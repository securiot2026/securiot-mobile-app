import '../../models/alert.dart';
import 'api_client.dart';

class AlertsRepository {
  AlertsRepository({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<List<Alert>> fetchAlerts({String? zoneId, String? deviceId, String? status}) async {
    final query = <String, String>{};
    if (zoneId != null) query['zone_id'] = zoneId;
    if (deviceId != null) query['device_id'] = deviceId;
    if (status != null) query['status'] = status;
    final raw = await _api.getList('alerts', query);
    return raw.map((e) => Alert.fromJson(e as Map<String, dynamic>)).toList();
  }
}
