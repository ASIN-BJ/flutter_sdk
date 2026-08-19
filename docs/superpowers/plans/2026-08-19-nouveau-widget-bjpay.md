# Migration vers le nouveau widget BjPay (token-based payWithJs) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remplacer l'ancienne intégration BjPay (URL + query string) par la nouvelle intégration basée sur le widget JS `Tresor.payWithJs` (token JWT), en gardant une WebView comme seul mécanisme de rendu.

**Architecture:** Une nouvelle fonction pure `buildCheckoutHtml` génère une page HTML locale embarquant le script `bjpay.min.js` et déclenchant automatiquement `Tresor.payWithJs({...})`. `PaymentWebView` charge cette page via `loadHtmlString` et reçoit le résultat du paiement via un `JavaScriptChannel` (`BjPayChannel`) qui transmet un JSON `{status, data}`. `Bjpay` expose la nouvelle API publique (`totalamount`, `token`, `onSuccess`, `onFailure`).

**Tech Stack:** Flutter/Dart, `webview_flutter` ^4.13.0 (déjà en dépendance, aucune nouvelle dépendance requise), `flutter_test`.

## Global Constraints

- Dart SDK `^3.9.2`, Flutter `>=1.17.0` (déjà fixés dans `pubspec.yaml`, ne pas changer).
- Le nom du paramètre est `totalamount` (tout en minuscule) partout — Dart ET JSON/JS généré. Ne jamais utiliser `totalAmount`.
- URL de production codée en dur : `https://widget-bjpay.service-public.bj` (script : `https://widget-bjpay.service-public.bj/widget/assets/bjpay.min.js`). Pas de bascule staging configurable.
- Suppression complète de `apiKey`, `callbackUrl`, `currency`, `description`, `customData`, `partnerId` de l'API publique — breaking change assumé, pas de coexistence avec l'ancien flux.
- `onSuccess`/`onFailure` ont la signature `void Function(Map<String, dynamic> data)?` — transmettre l'objet `data` reçu tel quel, sans supposer sa structure.
- Toute valeur dynamique injectée dans le HTML/JS généré doit passer par `jsonEncode` (jamais d'interpolation de chaîne brute) pour éviter la casse/injection JS.
- Pas de test d'intégration WebView (aucun setup de ce type n'existe dans le repo) — les tests se limitent à la logique pure (génération HTML) et au rendu du bouton `Bjpay` sans déclencher de navigation.

---

### Task 1: Générer le HTML/JS du nouveau widget (`checkout_html.dart`)

**Files:**
- Create: `lib/src/checkout_html.dart`
- Test: `test/checkout_html_test.dart`

**Interfaces:**
- Produces: `String buildCheckoutHtml({required double totalamount, required String token})` — utilisée par `PaymentWebView` (Task 2).

- [ ] **Step 1: Write the failing test**

Create `test/checkout_html_test.dart`:

```dart
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:bjpay_sdk/src/checkout_html.dart';

void main() {
  test('embeds totalamount and token as a JS/JSON object literal', () {
    final html = buildCheckoutHtml(totalamount: 100, token: 'abc123');
    // `totalamount` is a double parameter, so the literal `100` becomes
    // `100.0` — the expected payload must use the same double value or
    // jsonEncode will format it differently (`100` vs `100.0`).
    final expectedPayload = jsonEncode({'totalamount': 100.0, 'token': 'abc123'});

    expect(html, contains('var payload = $expectedPayload;'));
  });

  test('escapes a token containing quotes and backslashes', () {
    const trickyToken = 'weird"token\\with\\backslashes';
    final html = buildCheckoutHtml(totalamount: 50.5, token: trickyToken);
    final expectedPayload = jsonEncode({
      'totalamount': 50.5,
      'token': trickyToken,
    });

    expect(html, contains('var payload = $expectedPayload;'));
  });

  test('includes the BjPay script tag and resource hints', () {
    final html = buildCheckoutHtml(totalamount: 10, token: 't');

    expect(
      html,
      contains(
        '<link rel="preconnect" href="https://widget-bjpay.service-public.bj" crossorigin>',
      ),
    );
    expect(
      html,
      contains(
        '<link rel="dns-prefetch" href="https://widget-bjpay.service-public.bj">',
      ),
    );
    expect(
      html,
      contains(
        '<link rel="preload" as="script" href="https://widget-bjpay.service-public.bj/widget/assets/bjpay.min.js" crossorigin>',
      ),
    );
    expect(
      html,
      contains(
        '<script src="https://widget-bjpay.service-public.bj/widget/assets/bjpay.min.js"></script>',
      ),
    );
    expect(html, contains('Tresor.payWithJs(payload);'));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/checkout_html_test.dart`
Expected: FAIL — `Error: Not found: 'package:bjpay_sdk/src/checkout_html.dart'` (le fichier n'existe pas encore).

- [ ] **Step 3: Write minimal implementation**

Create `lib/src/checkout_html.dart`:

```dart
import 'dart:convert';

String buildCheckoutHtml({required double totalamount, required String token}) {
  final payload = jsonEncode({
    'totalamount': totalamount,
    'token': token,
  });

  return '''
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <link rel="preconnect" href="https://widget-bjpay.service-public.bj" crossorigin>
    <link rel="dns-prefetch" href="https://widget-bjpay.service-public.bj">
    <link rel="preload" as="script" href="https://widget-bjpay.service-public.bj/widget/assets/bjpay.min.js" crossorigin>
    <title>BjPay Checkout</title>
  </head>
  <body>
    <script src="https://widget-bjpay.service-public.bj/widget/assets/bjpay.min.js"></script>
    <script>
      var payload = $payload;
      payload.onSuccess = function (data) {
        BjPayChannel.postMessage(JSON.stringify({status: "SUCCESS", data: data}));
      };
      payload.onFailure = function (data) {
        BjPayChannel.postMessage(JSON.stringify({status: "FAILED", data: data}));
      };
      Tresor.payWithJs(payload);
    </script>
  </body>
</html>
''';
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/checkout_html_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/src/checkout_html.dart test/checkout_html_test.dart
git commit -m "Add buildCheckoutHtml for the new token-based BjPay widget"
```

---

### Task 2: Réécrire `PaymentWebView` pour le nouveau flux

**Files:**
- Modify: `lib/src/payment_webview.dart` (réécriture complète)

**Interfaces:**
- Consumes: `String buildCheckoutHtml({required double totalamount, required String token})` (Task 1).
- Produces: `class PaymentWebView extends StatefulWidget` avec constructeur `PaymentWebView({Key? key, required double totalamount, required String token, void Function(Map<String, dynamic> data)? onSuccess, void Function(Map<String, dynamic> data)? onFailure})` — utilisée par `Bjpay` (Task 3).

- [ ] **Step 1: Rewrite the file**

Replace the full content of `lib/src/payment_webview.dart`:

```dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'checkout_html.dart';

class PaymentWebView extends StatefulWidget {
  final double totalamount;
  final String token;
  final void Function(Map<String, dynamic> data)? onSuccess;
  final void Function(Map<String, dynamic> data)? onFailure;

  const PaymentWebView({
    super.key,
    required this.totalamount,
    required this.token,
    this.onSuccess,
    this.onFailure,
  });

  @override
  State<PaymentWebView> createState() => _PaymentWebViewState();
}

class _PaymentWebViewState extends State<PaymentWebView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'BjPayChannel',
        onMessageReceived: (JavaScriptMessage message) {
          _handleBridgeMessage(message.message);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (WebResourceError error) {
            debugPrint('BjPay widget failed to load: ${error.description}');
          },
        ),
      )
      ..loadHtmlString(
        buildCheckoutHtml(totalamount: widget.totalamount, token: widget.token),
        baseUrl: 'https://widget-bjpay.service-public.bj',
      );
  }

  void _handleBridgeMessage(String rawMessage) {
    final Object? decoded;
    try {
      decoded = jsonDecode(rawMessage);
    } catch (_) {
      return;
    }

    if (decoded is! Map<String, dynamic>) {
      return;
    }

    final status = decoded['status'];
    final rawData = decoded['data'];
    final data = rawData is Map<String, dynamic> ? rawData : <String, dynamic>{};

    if (status == 'SUCCESS') {
      widget.onSuccess?.call(data);
    } else if (status == 'FAILED') {
      widget.onFailure?.call(data);
    } else {
      return;
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Paiement BjPay")),
      body: WebViewWidget(controller: _controller),
    );
  }
}
```

- [ ] **Step 2: Run static analysis to verify it compiles cleanly**

Run: `flutter analyze lib/src/payment_webview.dart`
Expected: `No issues found!`

Pas de test automatisé dédié à ce fichier : la construction de `WebViewController` dans `initState` nécessite un environnement WebView réel, hors périmètre du plan (voir Global Constraints). La logique de parsing (`_handleBridgeMessage`) est volontairement simple (délégation directe au JSON déjà validé côté widget JS dans Task 1) et couverte indirectement par l'analyse statique.

- [ ] **Step 3: Commit**

```bash
git add lib/src/payment_webview.dart
git commit -m "Rewrite PaymentWebView for the token-based BjPay widget"
```

---

### Task 3: Réécrire le widget public `Bjpay`

**Files:**
- Modify: `lib/src/bjpay.dart` (réécriture complète)
- Test: `test/bjpay_test.dart`

**Interfaces:**
- Consumes: `PaymentWebView` constructor from Task 2 (`totalamount`, `token`, `onSuccess`, `onFailure`).
- Produces: `class Bjpay extends StatelessWidget` avec constructeur `Bjpay({Key? key, required double totalamount, required String token, void Function(Map<String, dynamic> data)? onSuccess, void Function(Map<String, dynamic> data)? onFailure})` — exportée via `lib/bjpay_sdk.dart` (déjà `export 'src/bjpay.dart';`, aucun changement nécessaire dans ce fichier).

- [ ] **Step 1: Write the failing test**

Create `test/bjpay_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bjpay_sdk/bjpay_sdk.dart';

void main() {
  testWidgets('renders the BjPay payment button', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Bjpay(
          totalamount: 100,
          token: 'test-token',
        ),
      ),
    );

    expect(find.text('Payer avec BjPay'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/bjpay_test.dart`
Expected: FAIL — erreur de compilation, `Bjpay` n'a pas de paramètres nommés `totalamount`/`token` (l'ancienne API exige encore `apiKey`/`callbackUrl`).

- [ ] **Step 3: Write minimal implementation**

Replace the full content of `lib/src/bjpay.dart`:

```dart
import 'package:flutter/material.dart';
import 'payment_webview.dart';

class Bjpay extends StatelessWidget {
  final double totalamount;
  final String token;
  final void Function(Map<String, dynamic> data)? onSuccess;
  final void Function(Map<String, dynamic> data)? onFailure;

  const Bjpay({
    super.key,
    required this.totalamount,
    required this.token,
    this.onSuccess,
    this.onFailure,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentWebView(
              totalamount: totalamount,
              token: token,
              onSuccess: onSuccess,
              onFailure: onFailure,
            ),
          ),
        );
      },
      child: const Text("Payer avec BjPay"),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/bjpay_test.dart`
Expected: PASS.

- [ ] **Step 5: Run the full test suite**

Run: `flutter test`
Expected: PASS (all tests across `test/checkout_html_test.dart` and `test/bjpay_test.dart`).

- [ ] **Step 6: Commit**

```bash
git add lib/src/bjpay.dart test/bjpay_test.dart
git commit -m "Rewrite Bjpay widget with the new totalamount/token API"
```

---

### Task 4: Mettre à jour l'app d'exemple

**Files:**
- Modify: `example/lib/main.dart`

**Interfaces:**
- Consumes: `Bjpay` constructor from Task 3 (`totalamount`, `token`, `onSuccess`, `onFailure`).

- [ ] **Step 1: Rewrite the file**

Replace the full content of `example/lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:bjpay_sdk/bjpay_sdk.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BjPay SDK Example',
      home: Scaffold(
        appBar: AppBar(title: const Text("BjPay Demo")),
        body: Center(
          child: Bjpay(
            totalamount: 100,
            token:
                "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOjE2NjM5NTAyLCJleHAiOjE3ODcyMTU1Mzh9.VY_MTh6aFozoDJ1zudiLffvb12ds2gdNY61mOMAaEdc",
            onSuccess: (data) {
              debugPrint("✅ Paiement réussi : $data");
            },
            onFailure: (data) {
              debugPrint("❌ Paiement échoué : $data");
            },
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Run static analysis to verify it compiles cleanly**

Run: `cd example && flutter analyze lib/main.dart && cd ..`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add example/lib/main.dart
git commit -m "Update example app to the new totalamount/token BjPay API"
```

---

### Task 5: Mettre à jour la documentation et la version du package

**Files:**
- Modify: `README.md`
- Modify: `CHANGELOG.md`
- Modify: `pubspec.yaml:3`

**Interfaces:**
- None (documentation-only task).

- [ ] **Step 1: Update the usage example in `README.md`**

In `README.md`, replace the `## 🎉 Exemple d'utilisation` code block (currently using `apiKey`/`callbackUrl`) with:

```dart
import 'package:flutter/material.dart';
import 'package:bjpay_sdk/bjpay_sdk.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BjPay SDK Example',
      home: Scaffold(
        appBar: AppBar(title: const Text("BjPay Demo")),
        body: Center(
          child: Bjpay(
            totalamount: 200,
            token: "VOTRE_TOKEN_JWT",
            onSuccess: (data) {
              debugPrint("✅ Paiement réussi : $data");
            },
            onFailure: (data) {
              debugPrint("❌ Paiement échoué : $data");
            },
          ),
        ),
      ),
    );
  }
}
```

Juste avant ce bloc de code, ajoute une phrase précisant l'origine du token :

```markdown
Le `token` est un JWT que votre backend doit générer via votre propre intégration BjPay ; le SDK ne le génère pas lui-même.
```

- [ ] **Step 2: Update `CHANGELOG.md`**

Replace the full content of `CHANGELOG.md`:

```markdown
## 0.1.0

* Breaking change: migration vers le nouveau widget BjPay (`Tresor.payWithJs`).
* `Bjpay` prend désormais `totalamount` et `token` (JWT généré par l'app hôte) au lieu de `apiKey`, `callbackUrl`, `currency`, `description`, `customData`, `partnerId`.
* `onSuccess`/`onFailure` reçoivent désormais `Map<String, dynamic> data` au lieu d'un `String transactionId`.

## 0.0.1

* TODO: Describe initial release.
```

- [ ] **Step 3: Bump the package version**

In `pubspec.yaml`, change line 3:

```yaml
version: 0.0.2
```

to:

```yaml
version: 0.1.0
```

- [ ] **Step 4: Verify the whole package still analyzes and tests cleanly**

Run: `flutter analyze && flutter test`
Expected: `No issues found!` and all tests PASS.

- [ ] **Step 5: Commit**

```bash
git add README.md CHANGELOG.md pubspec.yaml
git commit -m "Document the new token-based BjPay API and bump to 0.1.0"
```
