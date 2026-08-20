import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:bjpay/src/checkout_html.dart';

void main() {
  test('embeds totalamount and token as a JS/JSON object literal', () {
    final html = buildCheckoutHtml(totalamount: 100, token: 'abc123');
    // `totalamount` is a double parameter, so the literal `100` becomes
    // `100.0` — the expected payload must use the same double value or
    // jsonEncode will format it differently (`100` vs `100.0`).
    final expectedPayload = jsonEncode({'totalamount': 100.0, 'token': 'abc123'});

    expect(html, contains('var payload = $expectedPayload;'));
  });

  test('escapes a token containing quotes and backslashes', () {
    const trickyToken = 'weird"token\\with\\backslashes';
    final html = buildCheckoutHtml(totalamount: 50.5, token: trickyToken);
    final expectedPayload = jsonEncode({
      'totalamount': 50.5,
      'token': trickyToken,
    });

    expect(html, contains('var payload = $expectedPayload;'));
  });

  test('includes the BjPay script tag and resource hints', () {
    final html = buildCheckoutHtml(totalamount: 10, token: 't');

    expect(
      html,
      contains(
        '<link rel="preconnect" href="https://widget-bjpay.service-public.bj" crossorigin>',
      ),
    );
    expect(
      html,
      contains(
        '<link rel="dns-prefetch" href="https://widget-bjpay.service-public.bj">',
      ),
    );
    expect(
      html,
      contains(
        '<link rel="preload" as="script" href="https://widget-bjpay.service-public.bj/widget/assets/bjpay.min.js" crossorigin>',
      ),
    );
    expect(
      html,
      contains(
        '<script src="https://widget-bjpay.service-public.bj/widget/assets/bjpay.min.js" crossorigin></script>',
      ),
    );
    expect(html, contains('Tresor.payWithJs(payload);'));
  });

  test('forwards the widget close event to the Flutter bridge', () {
    final html = buildCheckoutHtml(totalamount: 10, token: 't');

    expect(
      html,
      contains("event.origin === 'https://widget-bjpay.service-public.bj'"),
    );
    expect(html, contains("event.data.bjpay === 'close'"));
    expect(
      html,
      contains('BjPayChannel.postMessage(JSON.stringify({status: "CLOSED", data: {}}));'),
    );
  });

  test('escapes tokens containing </script> to prevent script injection', () {
    const injectToken = 'token</script><script>alert("xss")</script>';
    final html = buildCheckoutHtml(totalamount: 25.0, token: injectToken);

    // The literal </script> must NOT appear in the HTML output
    // (which would break out of the script tag)
    expect(html, isNot(contains('</script><script>')));

    // The escaped form must appear in the payload
    final expectedPayload = jsonEncode({
      'totalamount': 25.0,
      'token': injectToken,
    }).replaceAll('<', r'\u003C');
    expect(html, contains('var payload = $expectedPayload;'));
    expect(html, contains(r'\u003C/script>'));
  });
}
