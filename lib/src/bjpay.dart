import 'package:flutter/material.dart';
import 'payment_webview.dart';

class Bjpay extends StatelessWidget {
  final double totalamount;
  final String token;
  final void Function(Map<String, dynamic> data)? onSuccess;
  final void Function(Map<String, dynamic> data)? onFailure;

  Bjpay({
    super.key,
    required this.totalamount,
    required this.token,
    this.onSuccess,
    this.onFailure,
  }) : assert(
         totalamount.isFinite && totalamount > 0,
         'totalamount must be a finite, positive number',
       );

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
