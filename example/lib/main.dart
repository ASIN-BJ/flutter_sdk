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
            apiKey: "810b7168-ab08-4707-8e41-fbf1d8772388",
            callbackUrl: "https://webhook.site/ad4dfc5c-cc76-4192-8241-3599491e7242",
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
