import 'reading.dart';

class Device {
  const Device({
    required this.id,
    required this.name,
    required this.zoneId,
    required this.createdAt,
    this.isOnline,
    this.lastReading,
    this.statusLoaded = false,
  });

  final String id;
  final String name;
  final String zoneId;
  final DateTime createdAt;
  final bool? isOnline;
  final Reading? lastReading;
  final bool statusLoaded;

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'] as String,
      name: json['name'] as String,
      zoneId: json['zoneId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Device withStatus({required bool isOnline, Reading? lastReading}) {
    return Device(
      id: id,
      name: name,
      zoneId: zoneId,
      createdAt: createdAt,
      isOnline: isOnline,
      lastReading: lastReading,
      statusLoaded: true,
    );
  }

  static Device fromStatusJson(Map<String, dynamic> json) {
    final rawReading = json['lastReading'];
    return Device(
      id: json['id'] as String,
      name: json['name'] as String,
      zoneId: json['zoneId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isOnline: json['isOnline'] as bool,
      lastReading: rawReading == null
          ? null
          : Reading.fromJson(rawReading as Map<String, dynamic>),
      statusLoaded: true,
    );
  }
}
