import 'package:flutter/material.dart';
import 'payment_webview.dart';



class Bjpay extends StatelessWidget {
  final double totalAmount;
  final String apiKey;
  final String callbackUrl;
  final String currency;
  final String description;
  final Map<String, String>? customData;
  final String partnerId;
  final Function(String transactionId)? onSuccess;
  final Function(String transactionId)? onFailure;

  const Bjpay({
    super.key,
    required this.totalAmount,
    required this.apiKey,
    required this.callbackUrl,
    this.currency = "XOF",
    this.description = "",
    this.customData,
    this.partnerId = "",
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
              totalAmount: totalAmount,
              apiKey: apiKey,
              callbackUrl: callbackUrl,
              currency: currency,
              description: description,
              customData: customData,
              partnerId: partnerId,
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
