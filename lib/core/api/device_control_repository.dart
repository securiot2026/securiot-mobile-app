import '../../models/command_status.dart';
import 'api_client.dart';

/// CTRL-01/02/03/05, FEED-02/05 and EXTR-02: manual actuator commands,
/// their delivery status, the live frame, and the zone occupancy counter —
/// all proxied through the Cloud API's per-device endpoints (Phases
/// 06.1/7/9/11), the same `callDeviceEdgeApi()`-backed contract the Web
/// App already consumes.
class DeviceControlRepository {
  DeviceControlRepository({ApiClient? apiClient})
    : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<void> sendPanTilt(
    String deviceId, {
    required double panDelta,
    required double tiltDelta,
  }) {
    return _api.postOne('devices/$deviceId/commands', {
      'actuator': 'pan_tilt',
      'action': {'pan_delta': panDelta, 'tilt_delta': tiltDelta},
    });
  }

  Future<void> sendLight(String deviceId, {required bool on}) {
    return _api.postOne('devices/$deviceId/commands', {
      'actuator': 'light',
      'action': {'on': on},
    });
  }

  Future<void> sendBuzzer(String deviceId, {required bool on}) {
    return _api.postOne('devices/$deviceId/commands', {
      'actuator': 'buzzer',
      'action': {'on': on},
    });
  }

  Future<void> sendDoor(String deviceId, {required bool open}) {
    return _api.postOne('devices/$deviceId/commands', {
      'actuator': 'door',
      'action': {'state': open ? 'open' : 'close'},
    });
  }

  Future<CommandDeliveryStatus> getCommandStatus(
    String deviceId,
    String actuator,
  ) async {
    final json = await _api.getOne('devices/$deviceId/commands/status', {
      'actuator': actuator,
    });
    return commandDeliveryStatusFromJson(json['status'] as String);
  }

  Future<LatestFrame> getLatestFrame(String deviceId) async {
    final json = await _api.getOne('devices/$deviceId/frame');
    return LatestFrame.fromJson(json);
  }

  Future<Occupancy> getOccupancy(String deviceId) async {
    final json = await _api.getOne('devices/$deviceId/occupancy');
    return Occupancy.fromJson(json);
  }
}
