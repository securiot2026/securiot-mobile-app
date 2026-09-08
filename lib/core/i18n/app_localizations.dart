import 'package:flutter/material.dart';

/// Lightweight, dependency-free localization: a string table swapped by
/// [Locale], covering every visible string in the app for en_US and es_419.
class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const supportedLocales = [Locale('en', 'US'), Locale('es', 'PE')];

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static const Map<String, Map<String, String>> _strings = {
    'en': {
      'appTitle': 'SecurIoT',
      'languageSelector': 'Language selector',
      'languageEnglish': 'English',
      'languageSpanish': 'Español',
      'loginTitle': 'Sign in',
      'loginSubtitle': 'Monitor your zones, devices, and alerts on the go.',
      'emailLabel': 'Email',
      'passwordLabel': 'Password',
      'signInButton': 'Sign in',
      'loginErrorInvalidCredentials': 'Incorrect email or password.',
      'loginErrorNetwork': "We couldn't load this. Check your connection and try again.",
      'loginErrorGeneric': 'Something went wrong. Please try again.',
      'validationEmailRequired': 'Enter your email.',
      'validationEmailInvalid': 'Enter a valid email.',
      'validationPasswordRequired': 'Enter your password.',
      'sessionExpired': 'Your session expired. Sign in again to continue.',
      'navZones': 'Zones',
      'navDevices': 'Devices',
      'navAlerts': 'Alerts',
      'logout': 'Sign out',
      'retry': 'Try again',
      'loading': 'Loading…',
      'zonesTitle': 'Zones',
      'zonesEmptyHeading': 'No zones yet',
      'zonesEmptyBody': 'Zones you register will show up here with their devices and status.',
      'zonesErrorFetch': "We couldn't load this. Check your connection and try again.",
      'devicesTitle': 'Devices',
      'devicesEmptyHeading': 'No devices yet',
      'devicesEmptyBody': 'Register a device and assign it to a zone to see its status here.',
      'devicesErrorFetch': "We couldn't load this. Check your connection and try again.",
      'statusOnline': 'Online',
      'statusOffline': 'Offline',
      'lastReading': 'Last reading',
      'noReadingYet': 'No reading yet',
      'alertsTitle': 'Alerts',
      'alertsEmptyHeading': 'No alerts to show',
      'alertsEmptyBody': 'Alerts triggered by your zones and devices will appear here.',
      'alertsFilteredEmpty': 'No alerts match these filters.',
      'alertsErrorFetch': "We couldn't load this. Check your connection and try again.",
      'filterZone': 'Zone',
      'filterDevice': 'Device',
      'filterStatus': 'Status',
      'filterAll': 'All',
      'statusActive': 'Active',
      'statusResolved': 'Resolved',
      'severityLow': 'Low',
      'severityMedium': 'Medium',
      'severityHigh': 'High',
      'clearFilters': 'Clear filters',
    },
    'es': {
      'appTitle': 'SecurIoT',
      'languageSelector': 'Selector de idioma',
      'languageEnglish': 'English',
      'languageSpanish': 'Español',
      'loginTitle': 'Iniciar sesión',
      'loginSubtitle': 'Supervisa tus zonas, dispositivos y alertas desde donde estés.',
      'emailLabel': 'Correo electrónico',
      'passwordLabel': 'Contraseña',
      'signInButton': 'Iniciar sesión',
      'loginErrorInvalidCredentials': 'Correo o contraseña incorrectos.',
      'loginErrorNetwork': 'No pudimos cargar esta información. Revisa tu conexión e inténtalo de nuevo.',
      'loginErrorGeneric': 'Algo salió mal. Inténtalo de nuevo.',
      'validationEmailRequired': 'Ingresa tu correo electrónico.',
      'validationEmailInvalid': 'Ingresa un correo electrónico válido.',
      'validationPasswordRequired': 'Ingresa tu contraseña.',
      'sessionExpired': 'Tu sesión expiró. Inicia sesión de nuevo para continuar.',
      'navZones': 'Zonas',
      'navDevices': 'Dispositivos',
      'navAlerts': 'Alertas',
      'logout': 'Cerrar sesión',
      'retry': 'Reintentar',
      'loading': 'Cargando…',
      'zonesTitle': 'Zonas',
      'zonesEmptyHeading': 'Aún no hay zonas',
      'zonesEmptyBody': 'Las zonas que registres aparecerán aquí con sus dispositivos y estado.',
      'zonesErrorFetch': 'No pudimos cargar esta información. Revisa tu conexión e inténtalo de nuevo.',
      'devicesTitle': 'Dispositivos',
      'devicesEmptyHeading': 'Aún no hay dispositivos',
      'devicesEmptyBody': 'Registra un dispositivo y asígnalo a una zona para ver su estado aquí.',
      'devicesErrorFetch': 'No pudimos cargar esta información. Revisa tu conexión e inténtalo de nuevo.',
      'statusOnline': 'En línea',
      'statusOffline': 'Sin conexión',
      'lastReading': 'Última lectura',
      'noReadingYet': 'Sin lecturas aún',
      'alertsTitle': 'Alertas',
      'alertsEmptyHeading': 'No hay alertas para mostrar',
      'alertsEmptyBody': 'Las alertas de tus zonas y dispositivos aparecerán aquí.',
      'alertsFilteredEmpty': 'Ningún resultado coincide con estos filtros.',
      'alertsErrorFetch': 'No pudimos cargar esta información. Revisa tu conexión e inténtalo de nuevo.',
      'filterZone': 'Zona',
      'filterDevice': 'Dispositivo',
      'filterStatus': 'Estado',
      'filterAll': 'Todas',
      'statusActive': 'Activa',
      'statusResolved': 'Resuelta',
      'severityLow': 'Baja',
      'severityMedium': 'Media',
      'severityHigh': 'Alta',
      'clearFilters': 'Limpiar filtros',
    },
  };

  /// Exposed only so tests can assert en/es key parity; not used by the app.
  static Map<String, Map<String, String>> get debugStringTables => _strings;

  String _raw(String key) => _strings[locale.languageCode]?[key] ?? key;

  String t(String key) => _raw(key);

  String zoneDeviceCount(int n) {
    if (locale.languageCode == 'es') {
      return n == 1 ? '1 dispositivo' : '$n dispositivos';
    }
    return n == 1 ? '1 device' : '$n devices';
  }

  String get appTitle => t('appTitle');
  String get languageSelector => t('languageSelector');
  String get loginTitle => t('loginTitle');
  String get loginSubtitle => t('loginSubtitle');
  String get emailLabel => t('emailLabel');
  String get passwordLabel => t('passwordLabel');
  String get signInButton => t('signInButton');
  String get sessionExpired => t('sessionExpired');
  String get navZones => t('navZones');
  String get navDevices => t('navDevices');
  String get navAlerts => t('navAlerts');
  String get logout => t('logout');
  String get retry => t('retry');
  String get loading => t('loading');
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.supportedLocales.any((l) => l.languageCode == locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
