import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:io';

class TruzztFlutter {
  static const MethodChannel _ch = MethodChannel('truzzt');
  static String? _apiKey;
  static String? _projectId;
  static String _baseUrl = 'https://truzzt.site';
  static Map<String, String>? _theme;

  static String applyThemeToUrl(String url, [Map<String, String>? theme]) {
    final t = theme ?? _theme;
    if (t == null || t.isEmpty) return url;
    final parts = <String>[];
    t.forEach((k, v) {
      final s = v.trim();
      if (s.isNotEmpty) {
        parts.add('${Uri.encodeQueryComponent(k)}=${Uri.encodeQueryComponent(s)}');
      }
    });
    if (parts.isEmpty) return url;
    return url + (url.contains('?') ? '&' : '?') + parts.join('&');
  }

  /// Required. Dashboard API key + project id (first-year free or subscribed).
  static Future<Map<String, dynamic>> configure({
    required String apiKey,
    required String projectId,
    String? baseUrl,
    Map<String, String>? theme,
  }) async {
    _apiKey = apiKey.trim();
    _projectId = projectId.trim();
    if (baseUrl != null && baseUrl.trim().isNotEmpty) {
      _baseUrl = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    }
    _theme = theme;
    try {
      await _ch.invokeMethod('configure', {
        'apiKey': _apiKey,
        'projectId': _projectId,
        'baseUrl': _baseUrl,
        if (theme != null) 'theme': theme,
      });
    } catch (_) {}
    return validateAccess();
  }

  static Future<Map<String, dynamic>> validateAccess() async {
    if (_apiKey == null ||
        _projectId == null ||
        !_apiKey!.startsWith('trz_live_') ||
        !_projectId!.startsWith('proj_')) {
      throw PlatformException(
        code: 'CONFIG_REQUIRED',
        message: 'Call TruzztFlutter.configure(apiKey:, projectId:) first',
      );
    }
    final uri = Uri.parse(
        '$_baseUrl/secure-api/v1/sdk/access?projectId=${Uri.encodeQueryComponent(_projectId!)}');
    final client = HttpClient();
    try {
      final req = await client.getUrl(uri);
      req.headers.set(HttpHeaders.authorizationHeader, 'Bearer $_apiKey');
      final res = await req.close();
      final text = await res.transform(utf8.decoder).join();
      final body = jsonDecode(text.isEmpty ? '{}' : text) as Map<String, dynamic>;
      if (res.statusCode >= 400 || body['success'] != true) {
        throw PlatformException(
          code: (body['code'] ?? 'ACCESS_DENIED').toString(),
          message: (body['message'] ?? 'SDK access denied').toString(),
        );
      }
      return Map<String, dynamic>.from(body['data'] as Map? ?? {'ok': true});
    } finally {
      client.close(force: true);
    }
  }

  static Future<void> requestPermissions() async {
    await validateAccess();
    await _ch.invokeMethod('requestPermissions');
  }

  static Future<List<dynamic>> getSimPhones() async {
    await validateAccess();
    final res = await _ch.invokeMethod<Map>('getSimPhones');
    return (res?['sims'] as List?) ?? const [];
  }

  static Future<Map<String, dynamic>> openVerify(
    String url, {
    Map<String, String>? theme,
  }) async {
    await validateAccess();
    final themed = applyThemeToUrl(url, theme);
    final res = await _ch.invokeMethod<Map>('openVerify', {'url': themed});
    return Map<String, dynamic>.from(res ?? {});
  }
}
