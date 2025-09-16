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
        'BjPayChannel',
        onMessageReceived: (JavaScriptMessage message) {
          final parts = message.message.split(":");
          final status = parts[0];
          final transactionId = parts.length > 1 ? parts[1] : "";

          if (status == "SUCCESS") {
            widget.onSuccess?.call(transactionId);
          }

          if (status == "FAILED") {
            widget.onFailure?.call(transactionId);
          }
          Navigator.of(context).pop();
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) {
            final uri = Uri.parse(url);
            final transactionId = uri.queryParameters["transactionId"];
            
            if (url.contains("success") && transactionId != null) {
              widget.onSuccess?.call(transactionId);
              Navigator.pop(context);
            }

            if (url.contains("failed") && transactionId != null) {
              widget.onFailure?.call(transactionId);
              Navigator.pop(context);
            }
          },
        ),
      )
      ..loadRequest(
        Uri.parse(
          "https://bjpay-staging.service-public.bj/widget"
          "?totalamount=${widget.totalAmount}"
          "&currency=${widget.currency}"
          "&description=${widget.description}"
          "&apikey=${widget.apiKey}"
          "&callbackurl=${widget.callbackUrl}"
          "&customdata=$customData"
          "&partnerid=${widget.partnerId}",
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
