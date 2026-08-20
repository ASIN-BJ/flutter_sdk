import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bjpay/bjpay.dart';

void main() {
  testWidgets('renders the BjPay payment button', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Bjpay(
          totalamount: 100,
          token: 'test-token',
        ),
      ),
    );

    expect(find.text('Payer avec BjPay'), findsOneWidget);
  });
}
