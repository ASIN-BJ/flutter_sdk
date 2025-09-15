# BjPay SDK

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
  bjpay_sdk:
    git:
      url: https://github.com/ASIN-BJ/flutter_sdk.git
```

## 🎉 Exemple d'utilisation

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
            totalAmount: 200,
            apiKey: "VOTRE_API_KEY",
            callbackUrl: "VOTRE_CALLBACK_URL",
            onSuccess: (transactionId) {
              debugPrint("✅ Paiement réussi : $transactionId");
            },
            onFailure: (transactionId) {
              debugPrint("❌ Paiement échoué : $transactionId");
            },
          ),
        ),
      ),
    );
  }
}
```