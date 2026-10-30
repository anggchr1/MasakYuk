import 'dart:convert';

import 'package:http/http.dart' as http;

/// Base URL backend MasakYuk (branch `web`).
/// Default = PC host dilihat dari emulator Android.
/// Ganti saat build, contoh:
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8000',
);

class ApiException implements Exception {
  final int status;
  final String body;
  ApiException(this.status, this.body);

  @override
  String toString() => 'ApiException($status): $body';
}

class ApiClient {
  final String baseUrl;
  final http.Client _client;

  /// Token Sanctum hasil login; null = request publik.
  String? token;

  ApiClient({String? baseUrl, http.Client? client})
      : baseUrl = baseUrl ?? apiBaseUrl,
        _client = client ?? http.Client();

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<dynamic> get(String path, {Map<String, String>? query}) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    final res = await _client
        .get(uri, headers: _headers)
        .timeout(const Duration(seconds: 20));
    return _decode(res);
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    final res = await _client
        .post(
          Uri.parse('$baseUrl$path'),
          headers: {..._headers, 'Content-Type': 'application/json'},
          body: json.encode(body ?? const <String, dynamic>{}),
        )
        .timeout(const Duration(seconds: 20));
    return _decode(res);
  }

  Future<dynamic> put(String path, {Map<String, dynamic>? body}) async {
    final res = await _client
        .put(
          Uri.parse('$baseUrl$path'),
          headers: {..._headers, 'Content-Type': 'application/json'},
          body: json.encode(body ?? const <String, dynamic>{}),
        )
        .timeout(const Duration(seconds: 20));
    return _decode(res);
  }

  Future<dynamic> delete(String path) async {
    final res = await _client
        .delete(Uri.parse('$baseUrl$path'), headers: _headers)
        .timeout(const Duration(seconds: 20));
    return _decode(res);
  }

  dynamic _decode(http.Response res) {
    if (res.statusCode >= 400) {
      throw ApiException(res.statusCode, res.body);
    }
    return json.decode(utf8.decode(res.bodyBytes));
  }
}
