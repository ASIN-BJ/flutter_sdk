import 'dart:convert';

String buildCheckoutHtml({required double totalamount, required String token}) {
  final payload = jsonEncode({
    'totalamount': totalamount,
    'token': token,
  });

  return '''
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <link rel="preconnect" href="https://widget-bjpay.service-public.bj" crossorigin>
    <link rel="dns-prefetch" href="https://widget-bjpay.service-public.bj">
    <link rel="preload" as="script" href="https://widget-bjpay.service-public.bj/widget/assets/bjpay.min.js" crossorigin>
    <title>BjPay Checkout</title>
  </head>
  <body>
    <script src="https://widget-bjpay.service-public.bj/widget/assets/bjpay.min.js"></script>
    <script>
      var payload = $payload;
      payload.onSuccess = function (data) {
        BjPayChannel.postMessage(JSON.stringify({status: "SUCCESS", data: data}));
      };
      payload.onFailure = function (data) {
        BjPayChannel.postMessage(JSON.stringify({status: "FAILED", data: data}));
      };
      Tresor.payWithJs(payload);
    </script>
  </body>
</html>
''';
}
