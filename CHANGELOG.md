## 0.1.0

* Breaking change: migration vers le nouveau widget BjPay (`Tresor.payWithJs`).
* `Bjpay` prend désormais `totalamount` et `token` (JWT généré par l'app hôte) au lieu de `apiKey`, `callbackUrl`, `currency`, `description`, `customData`, `partnerId`.
* `onSuccess`/`onFailure` reçoivent désormais `Map<String, dynamic> data` au lieu d'un `String transactionId`.

## 0.0.1

* TODO: Describe initial release.
