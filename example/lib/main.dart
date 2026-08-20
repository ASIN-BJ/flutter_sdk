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
      title: 'BjPay Test SDK',
      home: Scaffold(
        appBar: AppBar(title: const Text("BjPay Test SDK")),
        body: Center(
          child: Bjpay(
            totalamount: 100,
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
