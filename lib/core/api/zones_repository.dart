import '../../models/zone.dart';
import 'api_client.dart';

class ZonesRepository {
  ZonesRepository({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<List<Zone>> fetchZones() async {
    final raw = await _api.getList('zones');
    return raw.map((e) => Zone.fromJson(e as Map<String, dynamic>)).toList();
  }
}
