import 'dart:convert';

class BridgeMessage {
  final String status;
  final Map<String, dynamic> data;

  const BridgeMessage({required this.status, required this.data});
}

BridgeMessage? parseBridgeMessage(String rawMessage) {
  final Object? decoded;
  try {
    decoded = jsonDecode(rawMessage);
  } catch (_) {
    return null;
  }

  if (decoded is! Map<String, dynamic>) {
    return null;
  }

  final status = decoded['status'];
  if (status != 'SUCCESS' && status != 'FAILED' && status != 'CLOSED') {
    return null;
  }

  final rawData = decoded['data'];
  final Map<String, dynamic> data;
  if (rawData == null) {
    data = <String, dynamic>{};
  } else if (rawData is Map<String, dynamic>) {
    data = rawData;
  } else {
    data = <String, dynamic>{'value': rawData};
  }

  return BridgeMessage(status: status as String, data: data);
}
