import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:securiot_mobile/core/api/api_client.dart';
import 'package:securiot_mobile/core/api/api_exception.dart';
import 'package:securiot_mobile/core/i18n/app_localizations.dart';
import 'package:securiot_mobile/core/i18n/error_localizer.dart';
import 'package:securiot_mobile/core/storage/secure_storage.dart';

class _FakeStorage implements SecureStorage {
  @override
  Future<String?> readToken() async => 'test-token';

  @override
  Future<void> saveToken(String token) async {}

  @override
  Future<void> clearToken() async {}

  @override
  Future<void> saveLanguage(String languageCode) async {}

  @override
  Future<String?> readLanguage() async => null;
}

ApiClient _clientAnswering(int status, String body) {
  return ApiClient(
    httpClient: MockClient((request) async => http.Response(body, status)),
    storage: _FakeStorage(),
  );
}

Future<ApiException> _thrownBy(ApiClient client) async {
  try {
    await client.getOne('devices/abc/frame');
  } on ApiException catch (e) {
    return e;
  }
  fail('Expected an ApiException');
}

void main() {
  group('ApiClient error mapping', () {
    test('400 with "edgeUrl not configured" maps to edgeNotConfigured', () async {
      final e = await _thrownBy(
        _clientAnswering(400, jsonEncode({'error': 'edgeUrl not configured for this device'})),
      );
      expect(e.kind, ApiErrorKind.edgeNotConfigured);
      expect(e.statusCode, 400);
    });

    test('400 detection is case-insensitive and accepts the Nest message shape', () async {
      final e = await _thrownBy(
        _clientAnswering(400, jsonEncode({'statusCode': 400, 'message': 'EDGEURL NOT CONFIGURED'})),
      );
      expect(e.kind, ApiErrorKind.edgeNotConfigured);
    });

    test('400 detection reads the first element of a message list', () async {
      final e = await _thrownBy(
        _clientAnswering(
          400,
          jsonEncode({
            'statusCode': 400,
            'message': ['edgeUrl not configured for this device', 'other'],
          }),
        ),
      );
      expect(e.kind, ApiErrorKind.edgeNotConfigured);
    });

    test('502 with the error body shape maps to edgeUnreachable', () async {
      final e = await _thrownBy(
        _clientAnswering(502, jsonEncode({'error': 'Edge API rejected the admin credential'})),
      );
      expect(e.kind, ApiErrorKind.edgeUnreachable);
      expect(e.statusCode, 502);
    });

    test('502 with the Nest message shape maps to edgeUnreachable', () async {
      final e = await _thrownBy(
        _clientAnswering(
          502,
          jsonEncode({'statusCode': 502, 'message': 'Could not reach the device Edge API'}),
        ),
      );
      expect(e.kind, ApiErrorKind.edgeUnreachable);
      expect(e.statusCode, 502);
    });

    test('502 with an unparseable body still maps to edgeUnreachable', () async {
      final e = await _thrownBy(_clientAnswering(502, '<html>Bad gateway</html>'));
      expect(e.kind, ApiErrorKind.edgeUnreachable);
      expect(e.statusCode, 502);
    });

    test('503 and 504 map to edgeUnreachable', () async {
      for (final status in [503, 504]) {
        final e = await _thrownBy(_clientAnswering(status, ''));
        expect(e.kind, ApiErrorKind.edgeUnreachable, reason: 'status $status');
        expect(e.statusCode, status);
      }
    });

    test('400 with any other text stays generic with its status code', () async {
      final e = await _thrownBy(
        _clientAnswering(400, jsonEncode({'error': 'actuator must be one of light, buzzer'})),
      );
      expect(e.kind, ApiErrorKind.generic);
      expect(e.statusCode, 400);
    });

    test('400 with an empty or non-JSON body never throws a parsing error', () async {
      for (final body in ['', 'not json at all', '[1, 2', 'null', '"edgeUrl not configured"']) {
        final e = await _thrownBy(_clientAnswering(400, body));
        expect(e.kind, ApiErrorKind.generic, reason: 'body "$body"');
        expect(e.statusCode, 400);
      }
    });

    test('404 keeps kind generic and statusCode 404', () async {
      final e = await _thrownBy(_clientAnswering(404, jsonEncode({'error': 'no frame'})));
      expect(e.kind, ApiErrorKind.generic);
      expect(e.statusCode, 404);
    });

    test('500 stays generic with its status code', () async {
      final e = await _thrownBy(_clientAnswering(500, jsonEncode({'error': 'boom'})));
      expect(e.kind, ApiErrorKind.generic);
      expect(e.statusCode, 500);
    });

    test('401 still maps to sessionExpired', () async {
      final e = await _thrownBy(_clientAnswering(401, jsonEncode({'error': 'Unauthorized'})));
      expect(e.kind, ApiErrorKind.sessionExpired);
      expect(e.isAuthError, isTrue);
    });

    test('successful JSON and 204 responses behave as before', () async {
      final ok = await _clientAnswering(200, jsonEncode({'a': 1})).getOne('x');
      expect(ok, {'a': 1});

      final client = ApiClient(
        httpClient: MockClient((request) async => http.Response('', 204)),
        storage: _FakeStorage(),
      );
      expect(await client.postOne('x', {}), isEmpty);
    });

    test('the thrown exception never carries response-body text', () async {
      const secret = 'EDGE_ADMIN_KEY=sk-super-secret-hint';
      final cases = <int, String>{
        400: jsonEncode({'error': 'edgeUrl not configured: $secret'}),
        502: jsonEncode({'error': 'Edge API rejected the admin credential $secret'}),
        500: jsonEncode({'error': secret}),
      };
      for (final entry in cases.entries) {
        final e = await _thrownBy(_clientAnswering(entry.key, entry.value));
        expect(e.toString(), isNot(contains(secret)));
        expect(e.toString(), isNot(contains('edgeUrl not configured')));
        expect(e.toString(), isNot(contains('admin credential')));
      }
    });
  });

  group('messageFor new kinds', () {
    test('edgeNotConfigured and edgeUnreachable are localized in en and es', () {
      final en = AppLocalizations(const Locale('en', 'US'));
      final es = AppLocalizations(const Locale('es', 'PE'));

      for (final kind in [ApiErrorKind.edgeNotConfigured, ApiErrorKind.edgeUnreachable]) {
        expect(en.messageFor(kind).trim(), isNotEmpty);
        expect(es.messageFor(kind).trim(), isNotEmpty);
        expect(en.messageFor(kind), isNot(es.messageFor(kind)));
      }
      expect(en.messageFor(ApiErrorKind.edgeNotConfigured), contains('Web App'));
    });

    test('new control error keys exist in both languages', () {
      final tables = AppLocalizations.debugStringTables;
      const keys = [
        'controlErrorEdgeNotConfigured',
        'controlErrorEdgeUnreachable',
        'controlErrorCommandFailed',
        'controlErrorCommandNotDelivered',
        'controlFeedNoFrameYet',
        'controlErrorDismiss',
      ];
      for (final lang in ['en', 'es']) {
        for (final key in keys) {
          expect(tables[lang]!.containsKey(key), isTrue, reason: '$lang missing $key');
        }
      }
    });
  });
}
