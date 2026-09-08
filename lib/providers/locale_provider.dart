import 'package:flutter/material.dart';

import '../core/storage/secure_storage.dart';

/// Owns the current [Locale] and persists the choice so the language
/// survives app restarts (`securiot_lang`, matching the sibling web
/// surfaces' persistence key intent, stored per-app here).
class LocaleProvider extends ChangeNotifier {
  LocaleProvider({SecureStorage? storage}) : _storage = storage ?? SecureStorage();

  final SecureStorage _storage;
  Locale _locale = const Locale('en', 'US');

  Locale get locale => _locale;

  Future<void> loadPersisted() async {
    final saved = await _storage.readLanguage();
    if (saved == 'es_419') {
      _locale = const Locale('es', 'PE');
      notifyListeners();
    } else if (saved == 'en_US') {
      _locale = const Locale('en', 'US');
      notifyListeners();
    }
  }

  Future<void> setLanguage(Locale locale) async {
    _locale = locale;
    notifyListeners();
    await _storage.saveLanguage(locale.languageCode == 'es' ? 'es_419' : 'en_US');
  }
}
