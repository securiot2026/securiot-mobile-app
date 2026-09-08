import 'package:flutter/material.dart';

import '../core/api/api_client.dart';
import '../core/api/api_exception.dart';
import '../core/navigation/app_navigator.dart';
import '../core/storage/secure_storage.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

/// Owns the JWT session lifecycle: restoring a persisted token on launch,
/// logging in, and logging out (including a forced logout on a 401 from
/// any downstream call, per AUTH-02's session-expired flow).
class AuthProvider extends ChangeNotifier {
  AuthProvider({ApiClient? apiClient, SecureStorage? storage})
      : _api = apiClient ?? ApiClient(),
        _storage = storage ?? SecureStorage();

  final ApiClient _api;
  final SecureStorage _storage;

  AuthStatus status = AuthStatus.unknown;
  bool isSubmitting = false;
  ApiErrorKind? loginError;
  bool sessionExpired = false;

  Future<void> restoreSession() async {
    final token = await _storage.readToken();
    status = token != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    isSubmitting = true;
    loginError = null;
    notifyListeners();
    try {
      final result = await _api.login(email, password);
      final token = result['access_token'] as String;
      await _storage.saveToken(token);
      status = AuthStatus.authenticated;
      sessionExpired = false;
      return true;
    } on ApiException catch (e) {
      loginError = e.kind;
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _storage.clearToken();
    status = AuthStatus.unauthenticated;
    notifyListeners();
    AppNavigator.popToRoot();
  }

  Future<void> forceLogoutOnSessionExpired() async {
    await _storage.clearToken();
    status = AuthStatus.unauthenticated;
    sessionExpired = true;
    notifyListeners();
    AppNavigator.popToRoot();
  }
}
