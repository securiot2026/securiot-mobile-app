/// Error categories the UI localizes; the api layer never hardcodes
/// user-facing English strings so every message is translated at the
/// widget layer through AppLocalizations.
enum ApiErrorKind { network, invalidCredentials, sessionExpired, generic }

class ApiException implements Exception {
  const ApiException(this.kind, {this.statusCode});

  final ApiErrorKind kind;
  final int? statusCode;

  bool get isAuthError => kind == ApiErrorKind.sessionExpired;

  @override
  String toString() => 'ApiException($kind, status: $statusCode)';
}
