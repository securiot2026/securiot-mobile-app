enum CommandDeliveryStatus { pending, delivered, none }

CommandDeliveryStatus commandDeliveryStatusFromJson(String raw) {
  switch (raw) {
    case 'pending':
      return CommandDeliveryStatus.pending;
    case 'delivered':
      return CommandDeliveryStatus.delivered;
    default:
      return CommandDeliveryStatus.none;
  }
}

class LatestFrame {
  const LatestFrame({required this.deviceId, required this.capturedAt, required this.frameBase64});

  final String deviceId;
  final DateTime capturedAt;
  final String frameBase64;

  factory LatestFrame.fromJson(Map<String, dynamic> json) {
    return LatestFrame(
      deviceId: json['device_id'] as String,
      capturedAt: DateTime.parse(json['captured_at'] as String),
      frameBase64: json['frame'] as String,
    );
  }
}

class Occupancy {
  const Occupancy({required this.deviceId, required this.count});

  final String deviceId;
  final int count;

  factory Occupancy.fromJson(Map<String, dynamic> json) {
    return Occupancy(
      deviceId: json['device_id'] as String,
      count: json['count'] as int,
    );
  }
}
