import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';

class PaymentWebView extends StatefulWidget {
  final double totalAmount;
  final String apiKey;
  final String callbackUrl;
  final String currency;
  final String description;
  final Map<String, String>? customData;
  final String partnerId;
  final Function(String transactionId)? onSuccess;
  final Function(String error)? onFailure;

  const PaymentWebView({
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
  State<PaymentWebView> createState() => _PaymentWebViewState();
}

class _PaymentWebViewState extends State<PaymentWebView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    String customData = widget.customData != null
        ? jsonEncode(widget.customData)
        : "";
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
          'FlutterChannel', onMessageReceived: (JavaScriptMessage message) {
            if (message.message == "close") {
              Navigator.of(context).pop();
            }
          },
      )
    ..setNavigationDelegate(
      NavigationDelegate(
        onPageFinished: (url) {
          if (url.contains("success")) {
            widget.onSuccess?.call("transaction_12345");
            Navigator.pop(context);
          } else if (url.contains("failure")) {
            widget.onFailure?.call("Paiement échoué");
            Navigator.pop(context);
          }
        },
      ),
    )
    ..loadRequest(
      Uri.parse(
        "https://bjpay-staging.service-public.bj/widget?totalamount=${widget.totalAmount}&currency=${widget.currency}&description=${widget.description}&apikey=${widget.apiKey}&callbackurl=${widget.callbackUrl}&customdata=$customData&partnerid=${widget.partnerId}",
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Paiement BjPay")),
      body: WebViewWidget(controller: _controller),
    );
  }
}
