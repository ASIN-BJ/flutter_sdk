# Migration vers le nouveau widget BjPay (bjpay.min.js / Tresor.payWithJs)

## Contexte

Le widget BjPay a évolué. L'ancienne intégration chargeait directement une URL
(`https://bjpay-staging.service-public.bj/widget?totalamount=...&apikey=...`)
dans une WebView, avec des paramètres passés en query string (`apiKey`,
`callbackUrl`, `currency`, `description`, `customData`, `partnerId`), et
détectait le résultat du paiement via un `JavaScriptChannel` ou une
redirection d'URL contenant `success`/`failed`.

La nouvelle intégration fournie par BjPay est un widget JS embarqué dans une
page web :

```html
<script src="https://widget-bjpay.service-public.bj/widget/assets/bjpay.min.js"></script>
<script>
  Tresor.payWithJs({
    totalamount: 100,
    token: "eyJ...",
    onSuccess: function (data) { ... },
    onFailure: function (data) { ... },
  });
</script>
```

Ce widget ne prend plus d'`apiKey`/`callbackUrl` : il attend un `token` JWT,
que l'application hôte doit générer elle-même via son propre backend (le SDK
Flutter n'a pas connaissance de la façon dont ce token est produit).

Il n'existe pas de SDK natif ni d'API REST alternative documentée pour ce
widget : c'est un widget JS/DOM, donc une WebView reste le seul mécanisme
d'intégration possible dans une app Flutter.

## Objectifs

- Remplacer entièrement l'ancienne API du SDK par la nouvelle (breaking
  change assumé — pas de coexistence des deux flux).
- Reproduire le comportement du snippet HTML fourni : chargement du script
  BjPay puis appel automatique de `Tresor.payWithJs(...)` dès l'ouverture de
  la WebView (pas de bouton intermédiaire dans la page HTML).
- Transmettre fidèlement l'objet `data` reçu par `onSuccess`/`onFailure` au
  code Dart appelant, sans supposer sa structure interne.
- Corriger au passage le point d'attention déjà identifié sur l'ancienne
  implémentation (valeurs interpolées sans échappement dans le contenu
  généré) : le nouveau code doit échapper `token` proprement avant de
  l'injecter dans le JS généré.

## Non-objectifs

- Pas de bascule staging/production configurable : l'URL de production
  (`widget-bjpay.service-public.bj`) est codée en dur, comme demandé.
- Pas de génération de token côté SDK (pas d'appel HTTP interne, pas
  d'`apiKey`/`apiSecret`) : le token est entièrement fourni par l'app hôte.
- Pas de callback dédié pour les erreurs de chargement réseau du script
  (hors périmètre demandé) — seulement un log de diagnostic.
- Pas de tests d'intégration WebView (aucun setup de ce type n'existe déjà
  dans le repo).

## Architecture

1. L'app hôte génère un `token` JWT via son propre backend et appelle le
   widget Flutter avec `totalamount` (double) et `token` (String).
2. `Bjpay` (bouton) ouvre `PaymentWebView` en passant ces paramètres tels
   quels.
3. `PaymentWebView` génère une page HTML locale via
   `buildCheckoutHtml(totalamount: ..., token: ...)` et la charge avec
   `WebViewController.loadHtmlString`. Cette page embarque le script
   `bjpay.min.js` et déclenche automatiquement `Tresor.payWithJs(...)` à son
   chargement (comportement identique au snippet fourni, sans bouton
   intermédiaire).
4. Les callbacks JS `onSuccess`/`onFailure` sérialisent leur `data` et le
   transmettent à Flutter via un `JavaScriptChannel` nommé `BjPayChannel`,
   sous la forme d'un message JSON `{"status": "SUCCESS"|"FAILED", "data": {...}}`.
5. `PaymentWebView` parse ce message, appelle `onSuccess`/`onFailure` côté
   Dart avec `data` (`Map<String, dynamic>`), puis ferme la WebView
   (`Navigator.pop`).

Plus de query string, plus de détection par redirection d'URL — tout passe
par le pont JS.

## Composants

### `lib/src/checkout_html.dart` (nouveau)

```dart
String buildCheckoutHtml({required double totalamount, required String token})
```

- Génère la page HTML complète, en reprenant les hints de performance du
  snippet fourni dans le `<head>` :
  `<link rel="preconnect">`, `<link rel="dns-prefetch">` et
  `<link rel="preload" as="script">`, tous pointant vers
  `https://widget-bjpay.service-public.bj` (respectivement l'origine et le
  script `bjpay.min.js`) — puis le `<script>` externe vers
  `https://widget-bjpay.service-public.bj/widget/assets/bjpay.min.js`, suivi
  d'un `<script>` inline qui appelle `Tresor.payWithJs({...})`.
- `token` est injecté via `jsonEncode(token)` (jamais interpolé brut) : la
  syntaxe des chaînes JSON étant un sous-ensemble valide des chaînes JS,
  cela protège contre toute casse ou injection si le token contenait des
  guillemets ou des antislashs.
- `totalamount` (double) est injecté directement — pas de risque
  d'injection sur une valeur numérique.
- Les callbacks JS renvoient leur résultat via
  `BjPayChannel.postMessage(JSON.stringify({status: "...", data: data}))`.
- Fonction pure, sans dépendance à Flutter/WebView : testable isolément.

### `lib/src/payment_webview.dart` (réécrit)

- Nouvelle API : `totalamount` (double, requis), `token` (String, requis),
  `onSuccess`/`onFailure` (`Function(Map<String, dynamic> data)?`).
- Suppression de `apiKey`, `callbackUrl`, `currency`, `description`,
  `customData`, `partnerId` et de toute la logique associée.
- `initState` : construit le HTML via `buildCheckoutHtml`, charge avec
  `controller.loadHtmlString(html, baseUrl: "https://widget-bjpay.service-public.bj")`.
- `JavaScriptChannel('BjPayChannel')` : délègue à une fonction privée
  `_handleBridgeMessage(String rawMessage)` qui parse le JSON, appelle le
  callback Dart correspondant, puis ferme la WebView.
- Le `NavigationDelegate` n'est conservé que pour `onWebResourceError`
  (diagnostic best-effort, pas de callback public).

### `lib/src/bjpay.dart` (mis à jour)

- Widget public `Bjpay` : mêmes paramètres que `PaymentWebView`
  (`totalamount`, `token`, `onSuccess`, `onFailure`), transmis tels quels à
  `PaymentWebView` lors de la navigation.

## Gestion des erreurs

- `token` et `totalamount` restent `required` — erreur de compilation si
  omis.
- Aucune validation runtime du format du token : le SDK fait confiance à
  l'app hôte ; un token invalide côté serveur BjPay se traduit par un appel
  à `onFailure` par le widget JS lui-même.
- Message reçu sur `BjPayChannel` malformé (JSON invalide, `status`
  inconnu) : ignoré silencieusement (`try/catch` autour du `jsonDecode`),
  ne doit jamais faire planter l'app.
- Échec de chargement du script BjPay (réseau indisponible) : loggé via
  `debugPrint` dans `onWebResourceError`, pas de callback public dédié.
- Fermeture manuelle de la WebView (bouton retour) : comportement inchangé,
  aucun callback déclenché.

## Tests

- `test/checkout_html_test.dart` (nouveau, Dart pur, sans WebView) :
  - vérifie que le JSON généré contient bien la clé `totalamount` (minuscule)
    avec la bonne valeur ;
  - vérifie qu'un token contenant des guillemets/antislashs est
    correctement échappé (le HTML généré reste un JS valide).
- Pas de test d'intégration WebView, hors périmètre (pas de setup existant
  dans le repo).

## Migration (breaking change)

Toute app utilisant l'ancienne API (`apiKey`, `callbackUrl`, `currency`,
`description`, `customData`, `partnerId`) devra migrer vers
`totalamount`/`token`. Le `CHANGELOG.md` et le `README.md` seront mis à jour
avec le nouvel exemple d'utilisation ; la version du package sera
incrémentée (breaking change → bump de version majeure ou mineure selon la
politique de versioning déjà en place, actuellement en `0.0.x`).
