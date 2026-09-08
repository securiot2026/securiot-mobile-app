class Zone {
  const Zone({
    required this.id,
    required this.name,
    this.location,
    required this.ownerId,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String? location;
  final String ownerId;
  final DateTime createdAt;

  factory Zone.fromJson(Map<String, dynamic> json) {
    return Zone(
      id: json['id'] as String,
      name: json['name'] as String,
      location: json['location'] as String?,
      ownerId: json['ownerId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
