import 'package:flutter_test/flutter_test.dart';
import 'package:securiot_mobile/models/alert.dart';
import 'package:securiot_mobile/models/device.dart';
import 'package:securiot_mobile/models/reading.dart';
import 'package:securiot_mobile/models/zone.dart';

void main() {
  group('Zone.fromJson', () {
    test('parses the Cloud API zone shape', () {
      final zone = Zone.fromJson({
        'id': 'z1',
        'name': 'Front Entrance',
        'location': 'Building A',
        'ownerId': 'u1',
        'createdAt': '2026-09-01T10:00:00.000Z',
      });

      expect(zone.id, 'z1');
      expect(zone.name, 'Front Entrance');
      expect(zone.location, 'Building A');
    });

    test('tolerates a missing optional location', () {
      final zone = Zone.fromJson({
        'id': 'z1',
        'name': 'Front Entrance',
        'ownerId': 'u1',
        'createdAt': '2026-09-01T10:00:00.000Z',
      });

      expect(zone.location, isNull);
    });
  });

  group('Device.fromStatusJson', () {
    test('parses online status with a last reading', () {
      final device = Device.fromStatusJson({
        'id': 'd1',
        'name': 'Front Door Sensor',
        'zoneId': 'z1',
        'createdAt': '2026-09-01T10:00:00.000Z',
        'isOnline': true,
        'lastReading': {
          'id': 'r1',
          'deviceId': 'd1',
          'zoneId': 'z1',
          'sensorType': 'door_contact',
          'value': {'state': 'open'},
          'recordedAt': '2026-09-08T09:00:00.000Z',
        },
      });

      expect(device.isOnline, true);
      expect(device.lastReading, isNotNull);
      expect(device.lastReading!.displayValue, 'open');
    });

    test('parses offline status with no reading', () {
      final device = Device.fromStatusJson({
        'id': 'd1',
        'name': 'Front Door Sensor',
        'zoneId': 'z1',
        'createdAt': '2026-09-01T10:00:00.000Z',
        'isOnline': false,
        'lastReading': null,
      });

      expect(device.isOnline, false);
      expect(device.lastReading, isNull);
    });
  });

  group('Reading.displayValue', () {
    test('unwraps an object value with a state field', () {
      final reading = Reading.fromJson({
        'id': 'r1',
        'deviceId': 'd1',
        'zoneId': 'z1',
        'sensorType': 'door_contact',
        'value': {'state': 'closed'},
        'recordedAt': '2026-09-08T09:00:00.000Z',
      });

      expect(reading.displayValue, 'closed');
    });

    test('renders a plain scalar value as-is', () {
      final reading = Reading.fromJson({
        'id': 'r1',
        'deviceId': 'd1',
        'zoneId': 'z1',
        'sensorType': 'temperature',
        'value': 21.5,
        'recordedAt': '2026-09-08T09:00:00.000Z',
      });

      expect(reading.displayValue, '21.5');
    });
  });

  group('Alert.severityLevel', () {
    test('maps high and critical to AlertSeverity.high', () {
      final high = Alert.fromJson(_alertJson(severity: 'high'));
      final critical = Alert.fromJson(_alertJson(severity: 'critical'));

      expect(high.severityLevel, AlertSeverity.high);
      expect(critical.severityLevel, AlertSeverity.high);
    });

    test('maps medium and unknown severities correctly', () {
      final medium = Alert.fromJson(_alertJson(severity: 'medium'));
      final low = Alert.fromJson(_alertJson(severity: 'low'));

      expect(medium.severityLevel, AlertSeverity.medium);
      expect(low.severityLevel, AlertSeverity.low);
    });
  });
}

Map<String, dynamic> _alertJson({required String severity}) => {
      'id': 'a1',
      'zoneId': 'z1',
      'deviceId': 'd1',
      'readingId': 'r1',
      'ruleType': 'door_contact_open',
      'severity': severity,
      'status': 'active',
      'message': 'Door opened unexpectedly',
      'createdAt': '2026-09-08T09:00:00.000Z',
    };
