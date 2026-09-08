enum AlertSeverity { low, medium, high }

enum AlertStatus { active, resolved }

class Alert {
  const Alert({
    required this.id,
    required this.zoneId,
    required this.deviceId,
    this.readingId,
    required this.ruleType,
    required this.severity,
    required this.status,
    required this.message,
    required this.createdAt,
  });

  final String id;
  final String zoneId;
  final String deviceId;
  final String? readingId;
  final String ruleType;
  final String severity;
  final String status;
  final String message;
  final DateTime createdAt;

  AlertSeverity get severityLevel {
    switch (severity) {
      case 'high':
      case 'critical':
        return AlertSeverity.high;
      case 'medium':
        return AlertSeverity.medium;
      default:
        return AlertSeverity.low;
    }
  }

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: json['id'] as String,
      zoneId: json['zoneId'] as String,
      deviceId: json['deviceId'] as String,
      readingId: json['readingId'] as String?,
      ruleType: json['ruleType'] as String,
      severity: json['severity'] as String,
      status: json['status'] as String,
      message: json['message'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
