import '../../models/device.dart';
import 'api_client.dart';

class DevicesRepository {
  DevicesRepository({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<List<Device>> fetchDevices({String? zoneId}) async {
    final raw = await _api.getList(
      'devices',
      zoneId != null ? {'zone_id': zoneId} : null,
    );
    final devices = raw
        .map((e) => Device.fromJson(e as Map<String, dynamic>))
        .toList();

    // The list endpoint doesn't include online/offline status (kept out to
    // avoid an N+1 status computation on every listing); fetch each
    // device's status detail concurrently so cards can show it up front.
    final withStatus = await Future.wait(devices.map((d) => fetchStatus(d.id)));
    return withStatus;
  }

  Future<Device> fetchStatus(String deviceId) async {
    final raw = await _api.getOne('devices/$deviceId');
    return Device.fromStatusJson(raw);
  }
}
