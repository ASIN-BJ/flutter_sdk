import 'package:flutter_test/flutter_test.dart';
import 'package:bjpay_sdk/src/bridge_message.dart';

void main() {
  test('parses a valid SUCCESS message', () {
    final message = parseBridgeMessage(
      '{"status":"SUCCESS","data":{"transactionId":"abc"}}',
    );

    expect(message, isNotNull);
    expect(message!.status, 'SUCCESS');
    expect(message.data['transactionId'], 'abc');
  });

  test('parses a valid FAILED message', () {
    final message = parseBridgeMessage(
      '{"status":"FAILED","data":{"error":"declined"}}',
    );

    expect(message, isNotNull);
    expect(message!.status, 'FAILED');
    expect(message.data['error'], 'declined');
  });

  test('returns null for invalid JSON', () {
    final message = parseBridgeMessage('not json');

    expect(message, isNull);
  });

  test('returns null when JSON decodes to something other than an object', () {
    final message = parseBridgeMessage('[1,2,3]');

    expect(message, isNull);
  });

  test('returns null for an unknown status', () {
    final message = parseBridgeMessage('{"status":"PENDING","data":{}}');

    expect(message, isNull);
  });

  test('parses a valid CLOSED message', () {
    final message = parseBridgeMessage('{"status":"CLOSED","data":{}}');

    expect(message, isNotNull);
    expect(message!.status, 'CLOSED');
    expect(message.data, isEmpty);
  });

  test('preserves a non-map data value under a "value" key', () {
    final message = parseBridgeMessage(
      '{"status":"SUCCESS","data":"txn-123"}',
    );

    expect(message, isNotNull);
    expect(message!.data['value'], 'txn-123');
  });

  test('defaults to an empty map when data is missing', () {
    final message = parseBridgeMessage('{"status":"SUCCESS"}');

    expect(message, isNotNull);
    expect(message!.data.isEmpty, isTrue);
  });
}
