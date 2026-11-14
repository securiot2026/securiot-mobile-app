import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Thin wrapper over [FlutterSecureStorage] for the two values this app
/// persists across restarts: the JWT and the chosen language.
class SecureStorage {
  SecureStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _tokenKey = 'securiot_access_token';
  static const _languageKey = 'securiot_lang';

  final FlutterSecureStorage _storage;

  Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<void> clearToken() => _storage.delete(key: _tokenKey);

  Future<void> saveLanguage(String languageCode) =>
      _storage.write(key: _languageKey, value: languageCode);

  Future<String?> readLanguage() => _storage.read(key: _languageKey);
}
