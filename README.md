# BjPay

Un package Flutter pour intégrer facilement le paiement BjPay dans vos applications mobiles.

## 🚀 Fonctionnalités

- Intégration rapide du paiement BjPay via un widget Flutter.
- Gestion des callbacks de succès et d’échec de paiement.
- Utilisation de WebView pour une expérience utilisateur fluide.

## 🛠️ Prérequis

- Flutter SDK `>=1.17.0`
- Dart SDK `^3.9.2`

## ⚡ Installation

Ajoutez ceci à votre fichier `pubspec.yaml` :

```yaml
dependencies:
  bjpay:
    git:
      url: https://github.com/ASIN-BJ/flutter_sdk.git
      ref: v0.2.0
```

## 🎉 Exemple d'utilisation

Le `token` est un JWT que votre backend doit générer via votre propre intégration BjPay ; le SDK ne le génère pas lui-même.

Si l'utilisateur ferme le widget (bouton fermer, clic hors modale) avant d'avoir terminé le paiement, ni `onSuccess` ni `onFailure` ne sont appelés, mais l'application reprend la main automatiquement.

```dart
import 'package:flutter/material.dart';
import 'package:bjpay/bjpay.dart';

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