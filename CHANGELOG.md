## 0.1.1

* TODO: Describe changes since 0.1.0.

## 0.1.0

* Breaking change: migration vers le nouveau widget BjPay (`Tresor.payWithJs`).
* `Bjpay` prend désormais `totalamount` et `token` (JWT généré par l'app hôte) au lieu de `apiKey`, `callbackUrl`, `currency`, `description`, `customData`, `partnerId`.
* `onSuccess`/`onFailure` reçoivent désormais `Map<String, dynamic> data` au lieu d'un `String transactionId`.
* Fix : fermer le widget (bouton fermer, clic hors modale) revient désormais à l'application au lieu de rester bloqué sur la page de paiement.

## 0.0.1

* TODO: Describe initial release.
