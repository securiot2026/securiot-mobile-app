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
    throw ApiException(ApiErrorKind.generic, statusCode: response.statusCode);
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

  Future<Map<String, dynamic>> getOne(String path) async {
    final result = await _send(
      () async => _http.get(_uri(path), headers: await _headers()),
    );
    return result as Map<String, dynamic>;
  }
}
