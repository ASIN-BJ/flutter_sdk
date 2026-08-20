import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'bridge_message.dart';
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
  bool _completed = false;
  bool _isLoading = true;

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
          onPageFinished: (String url) {
            if (mounted) {
              setState(() => _isLoading = false);
            }
          },
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
    if (_completed) {
      return;
    }

    final message = parseBridgeMessage(rawMessage);
    if (message == null) {
      return;
    }

    _completed = true;

    if (message.status == 'SUCCESS') {
      widget.onSuccess?.call(message.data);
    } else if (message.status == 'FAILED') {
      widget.onFailure?.call(message.data);
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              const ColoredBox(
                color: Colors.white,
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}
