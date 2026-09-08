import 'package:flutter_test/flutter_test.dart';
import 'package:securiot_mobile/core/i18n/app_localizations.dart';

void main() {
  test('en and es_419 string tables cover the exact same keys', () {
    final tables = AppLocalizations.debugStringTables;
    final enKeys = tables['en']!.keys.toSet();
    final esKeys = tables['es']!.keys.toSet();

    expect(enKeys.difference(esKeys), isEmpty, reason: 'keys missing from es_419');
    expect(esKeys.difference(enKeys), isEmpty, reason: 'keys missing from en_US');
  });

  test('no string is left empty in either language', () {
    final tables = AppLocalizations.debugStringTables;
    for (final entry in tables.entries) {
      for (final value in entry.value.values) {
        expect(value.trim(), isNotEmpty, reason: '${entry.key} has an empty string');
      }
    }
  });
}
