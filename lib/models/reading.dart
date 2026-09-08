class Reading {
  const Reading({
    required this.id,
    required this.deviceId,
    required this.zoneId,
    required this.sensorType,
    required this.value,
    required this.recordedAt,
  });

  final String id;
  final String deviceId;
  final String zoneId;
  final String sensorType;
  final dynamic value;
  final DateTime recordedAt;

  factory Reading.fromJson(Map<String, dynamic> json) {
    return Reading(
      id: json['id'] as String,
      deviceId: json['deviceId'] as String,
      zoneId: json['zoneId'] as String,
      sensorType: json['sensorType'] as String,
      value: json['value'],
      recordedAt: DateTime.parse(json['recordedAt'] as String),
    );
  }

  String get displayValue {
    if (value is Map && (value as Map).containsKey('state')) {
      return (value as Map)['state'].toString();
    }
    return value.toString();
  }
}
