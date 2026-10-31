import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../storage/secure_storage.dart';
import 'api_config.dart';
import 'api_exception.dart';

/// Minimal JSON client for the Cloud API: attaches the bearer token to
/// every authenticated request and normalizes failures into [ApiException].
class ApiClient {
  ApiClient({http.Client? httpClient, SecureStorage? storage})
      : _http = httpClient ?? http.Client(),
        _storage = storage ?? SecureStorage();

  final http.Client _http;
  final SecureStorage _storage;

  Uri _uri(String path, [Map<String, String>? query]) {
    final normalized = path.startsWith('/') ? path.substring(1) : path;
    return Uri.parse('${ApiConfig.baseUrl}/$normalized').replace(
      queryParameters: query != null && query.isNotEmpty ? query : null,
    );
  }

  Future<Map<String, String>> _headers({bool authenticated = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (authenticated) {
      final token = await _storage.readToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<dynamic> _send(Future<http.Response> Function() request) async {
    late http.Response response;
    try {
      response = await request();
    } on SocketException {
      throw const ApiException(ApiErrorKind.network);
    } on http.ClientException {
      throw const ApiException(ApiErrorKind.network);
    }

    if (response.statusCode == 204) return null;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }

    if (response.statusCode == 401) {
      throw ApiException(ApiErrorKind.sessionExpired, statusCode: 401);
    }
    throw ApiException(_classifyFailure(response), statusCode: response.statusCode);
  }

  /// Maps a non-2xx, non-401 response to an [ApiErrorKind]. The body is read
  /// only to classify it; its text is discarded and never stored on the
  /// exception, so server wording cannot reach the UI.
  ApiErrorKind _classifyFailure(http.Response response) {
    final status = response.statusCode;
    if (status == 502 || status == 503 || status == 504) {
      return ApiErrorKind.edgeUnreachable;
    }
    if (status == 400 &&
        _errorText(response.body).toLowerCase().contains('edgeurl not configured')) {
      return ApiErrorKind.edgeNotConfigured;
    }
    return ApiErrorKind.generic;
  }

  /// Extracts the server's error text from `{"error": "..."}` or the Nest
  /// `{"message": "..."}` / `{"message": ["..."]}` shapes. Returns an empty
  /// string for empty, non-JSON or unexpectedly shaped bodies.
  String _errorText(String body) {
    if (body.isEmpty) return '';
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map) return '';
      final error = decoded['error'];
      if (error is String) return error;
      final message = decoded['message'];
      if (message is String) return message;
      if (message is List && message.isNotEmpty && message.first is String) {
        return message.first as String;
      }
    } on FormatException {
      return '';
    }
    return '';
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    late http.Response response;
    try {
      response = await _http.post(
        _uri('auth/login'),
        headers: await _headers(authenticated: false),
        body: jsonEncode({'email': email, 'password': password}),
      );
    } on SocketException {
      throw const ApiException(ApiErrorKind.network);
    } on http.ClientException {
      throw const ApiException(ApiErrorKind.network);
    }

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    if (response.statusCode == 401) {
      throw const ApiException(ApiErrorKind.invalidCredentials, statusCode: 401);
    }
    throw ApiException(ApiErrorKind.generic, statusCode: response.statusCode);
  }

  Future<List<dynamic>> getList(String path, [Map<String, String>? query]) async {
    final result = await _send(
      () async => _http.get(_uri(path, query), headers: await _headers()),
    );
    return (result as List<dynamic>?) ?? const [];
  }

  Future<Map<String, dynamic>> getOne(String path, [Map<String, String>? query]) async {
    final result = await _send(
      () async => _http.get(_uri(path, query), headers: await _headers()),
    );
    return result as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> postOne(String path, Map<String, dynamic> body) async {
    final result = await _send(
      () async => _http.post(_uri(path), headers: await _headers(), body: jsonEncode(body)),
    );
    return (result as Map<String, dynamic>?) ?? const {};
  }
}
