import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:securiot_mobile/core/api/api_exception.dart';
import 'package:securiot_mobile/core/api/device_control_repository.dart';
import 'package:securiot_mobile/core/i18n/app_localizations.dart';
import 'package:securiot_mobile/core/storage/secure_storage.dart';
import 'package:securiot_mobile/models/command_status.dart';
import 'package:securiot_mobile/providers/auth_provider.dart';
import 'package:securiot_mobile/providers/locale_provider.dart';
import 'package:securiot_mobile/screens/devices/device_control_screen.dart';

class _FakeStorage implements SecureStorage {
  @override
  Future<String?> readToken() async => null;

  @override
  Future<void> saveToken(String token) async {}

  @override
  Future<void> clearToken() async {}

  @override
  Future<void> saveLanguage(String languageCode) async {}

  @override
  Future<String?> readLanguage() async => null;
}

/// Scriptable stand-in for the Cloud-backed repository. Each `*Errors` list
/// is consumed one entry per call (null means the call succeeds); when empty
/// the call succeeds.
class _FakeRepository extends DeviceControlRepository {
  _FakeRepository({
    this.frameError = const ApiException(ApiErrorKind.generic, statusCode: 404),
    this.occupancyError = const ApiException(ApiErrorKind.generic, statusCode: 500),
    List<ApiException?>? lightErrors,
    List<ApiException?>? buzzerErrors,
    List<ApiException?>? panTiltErrors,
    List<ApiException?>? doorErrors,
    List<CommandDeliveryStatus>? statuses,
  })  : lightErrors = lightErrors ?? [],
        doorErrors = doorErrors ?? [],
        buzzerErrors = buzzerErrors ?? [],
        panTiltErrors = panTiltErrors ?? [],
        statuses = statuses ?? [];

  final ApiException frameError;
  final ApiException occupancyError;
  final List<ApiException?> lightErrors;
  final List<ApiException?> buzzerErrors;
  final List<ApiException?> panTiltErrors;
  final List<ApiException?> doorErrors;

  /// The `open` flag of every sendDoor call, in order.
  final List<bool> doorCalls = [];

  /// Statuses returned by successive getCommandStatus calls; the last one
  /// repeats once the list is exhausted.
  final List<CommandDeliveryStatus> statuses;

  int statusCalls = 0;

  Future<void> _maybeThrow(List<ApiException?> errors) async {
    if (errors.isEmpty) return;
    final next = errors.removeAt(0);
    if (next != null) throw next;
  }

  @override
  Future<void> sendLight(String deviceId, {required bool on}) => _maybeThrow(lightErrors);

  @override
  Future<void> sendBuzzer(String deviceId, {required bool on}) => _maybeThrow(buzzerErrors);

  @override
  Future<void> sendDoor(String deviceId, {required bool open}) {
    doorCalls.add(open);
    return _maybeThrow(doorErrors);
  }

  @override
  Future<void> sendPanTilt(String deviceId, {required double panDelta, required double tiltDelta}) =>
      _maybeThrow(panTiltErrors);

  @override
  Future<CommandDeliveryStatus> getCommandStatus(String deviceId, String actuator) async {
    statusCalls++;
    if (statuses.isEmpty) return CommandDeliveryStatus.delivered;
    final index = statusCalls - 1 < statuses.length ? statusCalls - 1 : statuses.length - 1;
    return statuses[index];
  }

  @override
  Future<LatestFrame> getLatestFrame(String deviceId) async => throw frameError;

  @override
  Future<Occupancy> getOccupancy(String deviceId) async => throw occupancyError;
}

const _edgeNotConfigured = ApiException(ApiErrorKind.edgeNotConfigured, statusCode: 400);
const _edgeUnreachable = ApiException(ApiErrorKind.edgeUnreachable, statusCode: 502);
const _network = ApiException(ApiErrorKind.network);
const _generic = ApiException(ApiErrorKind.generic, statusCode: 500);
const _sessionExpired = ApiException(ApiErrorKind.sessionExpired, statusCode: 401);

const _enNotConfigured =
    "This device has no Edge URL yet. Open the Web App, go to Devices, open this device's Face recognition page, save the Edge URL, and try again.";
const _enCommandFailed = 'The command was not sent. Try again.';
const _enNotDelivered =
    'The device did not pick up the command in time. Check that it is online, then try again.';

Future<void> _pumpScreen(
  WidgetTester tester,
  _FakeRepository repository, {
  Locale locale = const Locale('en', 'US'),
}) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(storage: _FakeStorage())),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: MaterialApp(
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: DeviceControlScreen(deviceId: 'dev-1', deviceName: 'Gate cam', repository: repository),
      ),
    ),
  );
  // Let the first feed poll settle.
  await tester.pump();
  await tester.pump();
}

/// Disposes the screen and flushes the status poll's pending delay so no
/// timers stay pending at the end of the test.
Future<void> _disposeScreen(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 12));
}

Future<void> _tapSwitch(WidgetTester tester, int index) async {
  await tester.tap(find.byType(Switch).at(index));
  await tester.pump();
  await tester.pump();
}

bool _switchValue(WidgetTester tester, int index) =>
    tester.widget<Switch>(find.byType(Switch).at(index)).value;

Future<void> _elapse(WidgetTester tester, int seconds) async {
  for (var i = 0; i < seconds; i++) {
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
  }
}

void main() {
  group('feed card errors', () {
    testWidgets('edgeNotConfigured shows the Web App instruction instead of Retrying (en)', (tester) async {
      await _pumpScreen(
        tester,
        _FakeRepository(frameError: _edgeNotConfigured, occupancyError: _edgeNotConfigured),
      );

      expect(find.text(_enNotConfigured), findsOneWidget);
      expect(find.textContaining('Web App'), findsOneWidget);
      expect(find.textContaining('Retrying'), findsNothing);
      await _disposeScreen(tester);
    });

    testWidgets('edgeNotConfigured is shown in Spanish in es_419', (tester) async {
      await _pumpScreen(
        tester,
        _FakeRepository(frameError: _edgeNotConfigured, occupancyError: _edgeNotConfigured),
        locale: const Locale('es', 'PE'),
      );

      expect(find.textContaining('Abre la Web App'), findsOneWidget);
      expect(find.textContaining('Reconocimiento facial'), findsOneWidget);
      expect(find.textContaining('Reintentando'), findsNothing);
      await _disposeScreen(tester);
    });

    testWidgets('a 404 frame shows the no-frame-yet message', (tester) async {
      await _pumpScreen(tester, _FakeRepository());

      expect(find.text('No picture yet. This device has not sent a frame.'), findsOneWidget);
      expect(find.textContaining('Retrying'), findsNothing);
      await _disposeScreen(tester);
    });

    testWidgets('edgeUnreachable shows the unreachable message', (tester) async {
      await _pumpScreen(tester, _FakeRepository(frameError: _edgeUnreachable));

      expect(find.textContaining('could not reach this device'), findsOneWidget);
      await _disposeScreen(tester);
    });

    testWidgets('other errors keep the generic load error', (tester) async {
      await _pumpScreen(tester, _FakeRepository(frameError: _generic));

      expect(find.text('Could not load the latest frame. Retrying…'), findsOneWidget);
      await _disposeScreen(tester);
    });
  });

  group('manual command failures', () {
    testWidgets('light send failing with edgeNotConfigured shows the banner and reverts the switch', (tester) async {
      await _pumpScreen(tester, _FakeRepository(lightErrors: [_edgeNotConfigured]));

      await _tapSwitch(tester, 0);

      expect(find.text(_enNotConfigured), findsWidgets);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(_switchValue(tester, 0), isFalse);
      await _disposeScreen(tester);
    });

    testWidgets('buzzer send failing reverts the buzzer switch and leaves light alone', (tester) async {
      await _pumpScreen(tester, _FakeRepository(buzzerErrors: [_edgeUnreachable]));

      await _tapSwitch(tester, 1);

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.textContaining('could not reach this device'), findsWidgets);
      expect(_switchValue(tester, 1), isFalse);
      expect(_switchValue(tester, 0), isFalse);
      await _disposeScreen(tester);
    });

    testWidgets('a network failure shows the network text and reverts', (tester) async {
      await _pumpScreen(tester, _FakeRepository(lightErrors: [_network]));

      await _tapSwitch(tester, 0);

      expect(
        find.text("We couldn't load this. Check your connection and try again."),
        findsOneWidget,
      );
      expect(_switchValue(tester, 0), isFalse);
      await _disposeScreen(tester);
    });

    testWidgets('a generic failure shows the command-failed text and reverts', (tester) async {
      await _pumpScreen(tester, _FakeRepository(lightErrors: [_generic]));

      await _tapSwitch(tester, 0);

      expect(find.text(_enCommandFailed), findsOneWidget);
      expect(_switchValue(tester, 0), isFalse);
      await _disposeScreen(tester);
    });

    testWidgets('a failed pan/tilt press shows the banner', (tester) async {
      await _pumpScreen(tester, _FakeRepository(panTiltErrors: [_generic]));

      await tester.tap(find.byIcon(Icons.keyboard_arrow_left));
      await tester.pump();
      await tester.pump();

      expect(find.text(_enCommandFailed), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      await _disposeScreen(tester);
    });

    testWidgets('a session-expired error shows no banner', (tester) async {
      await _pumpScreen(tester, _FakeRepository(lightErrors: [_sessionExpired]));

      await _tapSwitch(tester, 0);

      expect(find.byIcon(Icons.error_outline), findsNothing);
      expect(find.text(_enCommandFailed), findsNothing);
      await _disposeScreen(tester);
    });
  });

  group('undelivered commands', () {
    testWidgets('status falling to none after pending shows not-delivered and reverts', (tester) async {
      final repository = _FakeRepository(
        statuses: [CommandDeliveryStatus.pending, CommandDeliveryStatus.none],
      );
      await _pumpScreen(tester, repository);

      await _tapSwitch(tester, 0);
      expect(_switchValue(tester, 0), isTrue);

      await _elapse(tester, 1);
      expect(find.text(_enNotDelivered), findsNothing);
      expect(_switchValue(tester, 0), isTrue);

      await _elapse(tester, 1);
      expect(find.text(_enNotDelivered), findsOneWidget);
      expect(_switchValue(tester, 0), isFalse);
      await _disposeScreen(tester);
    });

    testWidgets('no delivery within the poll window shows not-delivered and reverts the buzzer', (tester) async {
      final repository = _FakeRepository(statuses: [CommandDeliveryStatus.pending]);
      await _pumpScreen(tester, repository);

      await _tapSwitch(tester, 1);
      await _elapse(tester, 9);
      expect(find.text(_enNotDelivered), findsNothing);
      expect(_switchValue(tester, 1), isTrue);

      await _elapse(tester, 2);
      expect(find.text(_enNotDelivered), findsOneWidget);
      expect(_switchValue(tester, 1), isFalse);
      await _disposeScreen(tester);
    });

    testWidgets('a delivered command shows no error and clears a previous banner', (tester) async {
      final repository = _FakeRepository(
        lightErrors: [_generic, null],
        statuses: [CommandDeliveryStatus.pending, CommandDeliveryStatus.delivered],
      );
      await _pumpScreen(tester, repository);

      await _tapSwitch(tester, 0);
      expect(find.text(_enCommandFailed), findsOneWidget);

      await _tapSwitch(tester, 0);
      expect(_switchValue(tester, 0), isTrue);
      await _elapse(tester, 2);

      expect(find.text('Delivered'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsNothing);
      expect(find.text(_enCommandFailed), findsNothing);
      expect(_switchValue(tester, 0), isTrue);
      await _disposeScreen(tester);
    });
  });

  group('error banner accessibility', () {
    testWidgets('is a live region with icon plus text and a dismiss control that works', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpScreen(tester, _FakeRepository(lightErrors: [_generic]));

      await _tapSwitch(tester, 0);

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text(_enCommandFailed), findsOneWidget);
      expect(
        find.ancestor(
          of: find.text(_enCommandFailed),
          matching: find.byWidgetPredicate(
            (w) => w is Semantics && w.properties.liveRegion == true,
          ),
        ),
        findsWidgets,
      );

      final dismiss = find.bySemanticsLabel('Dismiss');
      expect(dismiss, findsOneWidget);
      final size = tester.getSize(find.widgetWithIcon(IconButton, Icons.close));
      expect(size.width, greaterThanOrEqualTo(44));
      expect(size.height, greaterThanOrEqualTo(44));

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      expect(find.text(_enCommandFailed), findsNothing);
      expect(find.byIcon(Icons.error_outline), findsNothing);

      semantics.dispose();
      await _disposeScreen(tester);
    });

    testWidgets('dismiss control is labelled in Spanish', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpScreen(
        tester,
        _FakeRepository(lightErrors: [_generic]),
        locale: const Locale('es', 'PE'),
      );

      await _tapSwitch(tester, 0);

      expect(find.text('No se envió el comando. Inténtalo de nuevo.'), findsOneWidget);
      expect(find.bySemanticsLabel('Cerrar'), findsOneWidget);

      semantics.dispose();
      await _disposeScreen(tester);
    });
  });

  group('door buttons', () {
    const openText = 'Open door';
    const closeText = 'Close door';

    Future<void> tapText(WidgetTester tester, String text) async {
      await tester.tap(find.text(text));
      await tester.pump();
      await tester.pump();
    }

    testWidgets('Open door sends open once, shows pending then delivered and no banner', (tester) async {
      final repository = _FakeRepository(
        statuses: [CommandDeliveryStatus.pending, CommandDeliveryStatus.delivered],
      );
      await _pumpScreen(tester, repository);

      expect(find.text('Door'), findsOneWidget);
      expect(find.text(openText), findsOneWidget);
      expect(find.text(closeText), findsOneWidget);

      await tapText(tester, openText);
      expect(repository.doorCalls, [true]);
      expect(find.text('Sending…'), findsOneWidget);

      await _elapse(tester, 1);
      expect(find.text('Sending…'), findsOneWidget);
      await _elapse(tester, 1);
      expect(find.text('Delivered'), findsOneWidget);
      expect(find.text('Sending…'), findsNothing);
      expect(find.byIcon(Icons.error_outline), findsNothing);
      expect(repository.doorCalls, [true]);
      await _disposeScreen(tester);
    });

    testWidgets('labels are localized in es_419', (tester) async {
      await _pumpScreen(tester, _FakeRepository(), locale: const Locale('es', 'PE'));

      expect(find.text('Puerta'), findsOneWidget);
      expect(find.text('Abrir puerta'), findsOneWidget);
      expect(find.text('Cerrar puerta'), findsOneWidget);
      await _disposeScreen(tester);
    });

    testWidgets('Close door sends close once with pending then delivered feedback', (tester) async {
      final repository = _FakeRepository(
        statuses: [CommandDeliveryStatus.pending, CommandDeliveryStatus.delivered],
      );
      await _pumpScreen(tester, repository);

      await tapText(tester, closeText);
      expect(repository.doorCalls, [false]);
      expect(find.text('Sending…'), findsOneWidget);

      await _elapse(tester, 2);
      expect(find.text('Delivered'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsNothing);
      await _disposeScreen(tester);
    });

    for (final failure in <String, (ApiException, Matcher)>{
      'edgeNotConfigured': (_edgeNotConfigured, equals(_enNotConfigured)),
      'edgeUnreachable': (_edgeUnreachable, contains('could not reach this device')),
      'network': (_network, equals("We couldn't load this. Check your connection and try again.")),
      'generic': (_generic, equals(_enCommandFailed)),
    }.entries) {
      testWidgets('a door send failing with ${failure.key} shows the banner and no status label',
          (tester) async {
        final repository = _FakeRepository(doorErrors: [failure.value.$1]);
        await _pumpScreen(tester, repository);

        await tapText(tester, openText);

        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        expect(
          find.byWidgetPredicate((w) => w is Text && w.data != null && failure.value.$2.matches(w.data, {})),
          findsWidgets,
        );
        expect(find.text('Sending…'), findsNothing);
        expect(find.text('Delivered'), findsNothing);
        expect(_switchValue(tester, 0), isFalse);
        expect(_switchValue(tester, 1), isFalse);
        await _disposeScreen(tester);
      });
    }

    testWidgets('a session-expired error on a door press shows no banner', (tester) async {
      await _pumpScreen(tester, _FakeRepository(doorErrors: [_sessionExpired]));

      await tapText(tester, openText);

      expect(find.byIcon(Icons.error_outline), findsNothing);
      expect(find.text(_enCommandFailed), findsNothing);
      await _disposeScreen(tester);
    });

    testWidgets('status falling to none after pending shows the not-delivered banner', (tester) async {
      final repository = _FakeRepository(
        statuses: [CommandDeliveryStatus.pending, CommandDeliveryStatus.none],
      );
      await _pumpScreen(tester, repository);

      await tapText(tester, openText);
      await _elapse(tester, 1);
      expect(find.text(_enNotDelivered), findsNothing);

      await _elapse(tester, 1);
      expect(find.text(_enNotDelivered), findsOneWidget);
      expect(find.text('Sending…'), findsNothing);
      await _disposeScreen(tester);
    });

    testWidgets('no delivery within the poll window shows the not-delivered banner', (tester) async {
      final repository = _FakeRepository(statuses: [CommandDeliveryStatus.pending]);
      await _pumpScreen(tester, repository);

      await tapText(tester, closeText);
      await _elapse(tester, 9);
      expect(find.text(_enNotDelivered), findsNothing);

      await _elapse(tester, 2);
      expect(find.text(_enNotDelivered), findsOneWidget);
      await _disposeScreen(tester);
    });

    testWidgets('a newer door press supersedes the older one', (tester) async {
      final repository = _FakeRepository();
      await _pumpScreen(tester, repository);

      await tapText(tester, openText);
      await tapText(tester, closeText);
      expect(repository.doorCalls, [true, false]);

      await _elapse(tester, 2);
      // Only the newer press polls the status; the older poll stops quietly.
      expect(repository.statusCalls, 1);
      expect(find.text('Delivered'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsNothing);
      await _disposeScreen(tester);
    });

    testWidgets('buttons are at least 48 dp high, labelled for screen readers and icon plus text',
        (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpScreen(tester, _FakeRepository());

      final openButton = find.ancestor(of: find.text(openText), matching: find.bySubtype<FilledButton>());
      final closeButton = find.ancestor(of: find.text(closeText), matching: find.bySubtype<OutlinedButton>());
      expect(tester.getSize(openButton).height, greaterThanOrEqualTo(48));
      expect(tester.getSize(closeButton).height, greaterThanOrEqualTo(48));
      expect(find.byIcon(Icons.lock_open), findsOneWidget);
      expect(find.byIcon(Icons.lock), findsOneWidget);
      expect(find.bySemanticsLabel(openText), findsOneWidget);
      expect(find.bySemanticsLabel(closeText), findsOneWidget);

      semantics.dispose();
      await _disposeScreen(tester);
    });

    for (final locale in [const Locale('en', 'US'), const Locale('es', 'PE')]) {
      testWidgets('builds without overflow at 2.0 text scale on a narrow screen (${locale.languageCode})',
          (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = 2.0;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await _pumpScreen(tester, _FakeRepository(), locale: locale);
        tester.view.physicalSize = const Size(360, 2400);
        await tester.pump();

        expect(tester.takeException(), isNull);
        final labels = locale.languageCode == 'es' ? ['Abrir puerta', 'Cerrar puerta'] : [openText, closeText];
        for (final label in labels) {
          expect(find.text(label), findsOneWidget);
        }
        await _disposeScreen(tester);
      });
    }
  });
}
