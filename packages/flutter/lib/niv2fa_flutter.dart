import 'package:flutter/services.dart';

class Niv2faFlutter {
  static const MethodChannel _ch = MethodChannel('niv2fa');

  static Future<void> requestPermissions() async {
    await _ch.invokeMethod('requestPermissions');
  }

  static Future<List<dynamic>> getSimPhones() async {
    final res = await _ch.invokeMethod<Map>('getSimPhones');
    return (res?['sims'] as List?) ?? const [];
  }

  /// Opens in-app verify WebView for a NIV2FA session URL.
  static Future<Map<String, dynamic>> openVerify(String url) async {
    final res = await _ch.invokeMethod<Map>('openVerify', {'url': url});
    return Map<String, dynamic>.from(res ?? {});
  }
}
