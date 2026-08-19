import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'checkout_html.dart';

class PaymentWebView extends StatefulWidget {
  final double totalamount;
  final String token;
  final void Function(Map<String, dynamic> data)? onSuccess;
  final void Function(Map<String, dynamic> data)? onFailure;

  const PaymentWebView({
    super.key,
    required this.totalamount,
    required this.token,
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
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'BjPayChannel',
        onMessageReceived: (JavaScriptMessage message) {
          _handleBridgeMessage(message.message);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (WebResourceError error) {
            debugPrint('BjPay widget failed to load: ${error.description}');
          },
        ),
      )
      ..loadHtmlString(
        buildCheckoutHtml(totalamount: widget.totalamount, token: widget.token),
        baseUrl: 'https://widget-bjpay.service-public.bj',
      );
  }

  void _handleBridgeMessage(String rawMessage) {
    final Object? decoded;
    try {
      decoded = jsonDecode(rawMessage);
    } catch (_) {
      return;
    }

    if (decoded is! Map<String, dynamic>) {
      return;
    }

    final status = decoded['status'];
    final rawData = decoded['data'];
    final data = rawData is Map<String, dynamic> ? rawData : <String, dynamic>{};

    if (status == 'SUCCESS') {
      widget.onSuccess?.call(data);
    } else if (status == 'FAILED') {
      widget.onFailure?.call(data);
    } else {
      return;
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Paiement BjPay")),
      body: WebViewWidget(controller: _controller),
    );
  }
}
