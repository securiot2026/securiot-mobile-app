/// Error categories the UI localizes; the api layer never hardcodes
/// user-facing English strings so every message is translated at the
/// widget layer through AppLocalizations.
///
/// [edgeNotConfigured] and [edgeUnreachable] come from the Cloud's Edge
/// proxy endpoints: the device has no edgeUrl yet, or its Edge API could
/// not be reached.
enum ApiErrorKind {
  network,
  invalidCredentials,
  sessionExpired,
  edgeNotConfigured,
  edgeUnreachable,
  generic,
}

class ApiException implements Exception {
  const ApiException(this.kind, {this.statusCode});

  final ApiErrorKind kind;
  final int? statusCode;

  bool get isAuthError => kind == ApiErrorKind.sessionExpired;

  @override
  String toString() => 'ApiException($kind, status: $statusCode)';
}
