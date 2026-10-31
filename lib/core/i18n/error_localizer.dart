import '../api/api_exception.dart';
import 'app_localizations.dart';

extension ApiErrorLocalization on AppLocalizations {
  String messageFor(ApiErrorKind kind) {
    switch (kind) {
      case ApiErrorKind.invalidCredentials:
        return t('loginErrorInvalidCredentials');
      case ApiErrorKind.sessionExpired:
        return sessionExpired;
      case ApiErrorKind.network:
        return t('loginErrorNetwork');
      case ApiErrorKind.edgeNotConfigured:
        return t('controlErrorEdgeNotConfigured');
      case ApiErrorKind.edgeUnreachable:
        return t('controlErrorEdgeUnreachable');
      case ApiErrorKind.generic:
        return t('loginErrorGeneric');
    }
  }
}
