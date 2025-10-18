class EmergencyAlert {
  final String id;
  final String userId;
  final AlertType type;
  final double latitude;
  final double longitude;
  final String? locationAddress;
  final AlertStatus status;
  final bool isSilent;
  final List<String> mediaUrls;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  EmergencyAlert({
    required this.id,
    required this.userId,
    required this.type,
    required this.latitude,
    required this.longitude,
    this.locationAddress,
    this.status = AlertStatus.active,
    this.isSilent = false,
    this.mediaUrls = const [],
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EmergencyAlert.fromJson(Map<String, dynamic> json) => EmergencyAlert(
    id: json['id'],
    userId: json['user_id'],
    type: AlertType.values.firstWhere((e) => e.name == json['type']),
    latitude: json['latitude'].toDouble(),
    longitude: json['longitude'].toDouble(),
    locationAddress: json['location_address'],
    status: AlertStatus.values.firstWhere((e) => e.name == json['status']),
    isSilent: json['is_silent'] ?? false,
    mediaUrls: List<String>.from(json['media_urls'] ?? []),
    notes: json['notes'],
    createdAt: DateTime.parse(json['created_at']),
    updatedAt: DateTime.parse(json['updated_at']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'type': type.name,
    'latitude': latitude,
    'longitude': longitude,
    'location_address': locationAddress,
    'status': status.name,
    'is_silent': isSilent,
    'media_urls': mediaUrls,
    'notes': notes,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  EmergencyAlert copyWith({
    String? id,
    String? userId,
    AlertType? type,
    double? latitude,
    double? longitude,
    String? locationAddress,
    AlertStatus? status,
    bool? isSilent,
    List<String>? mediaUrls,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => EmergencyAlert(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    type: type ?? this.type,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    locationAddress: locationAddress ?? this.locationAddress,
    status: status ?? this.status,
    isSilent: isSilent ?? this.isSilent,
    mediaUrls: mediaUrls ?? this.mediaUrls,
    notes: notes ?? this.notes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

enum AlertType {
  police,
  ambulance,
  general,
  bullying,
  harassment,
  threat,
  medical
}

enum AlertStatus {
  active,
  responding,
  resolved,
  cancelled
}
