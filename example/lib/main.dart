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
