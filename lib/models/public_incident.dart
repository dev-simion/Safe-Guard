class PublicIncident {
  final String id;
  final String userId;
  final String title;
  final String description;
  final double latitude;
  final double longitude;
  final String? locationAddress;
  final List<String> mediaUrls;
  final int upvotes;
  final int downvotes;
  final List<String> upvotedBy;
  final List<String> downvotedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  PublicIncident({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.latitude,
    required this.longitude,
    this.locationAddress,
    this.mediaUrls = const [],
    this.upvotes = 0,
    this.downvotes = 0,
    this.upvotedBy = const [],
    this.downvotedBy = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory PublicIncident.fromJson(Map<String, dynamic> json) => PublicIncident(
    id: json['id'],
    userId: json['user_id'],
    title: json['title'],
    description: json['description'],
    latitude: json['latitude'].toDouble(),
    longitude: json['longitude'].toDouble(),
    locationAddress: json['location_address'],
    mediaUrls: List<String>.from(json['media_urls'] ?? []),
    upvotes: json['upvotes'] ?? 0,
    downvotes: json['downvotes'] ?? 0,
    upvotedBy: List<String>.from(json['upvoted_by'] ?? []),
    downvotedBy: List<String>.from(json['downvoted_by'] ?? []),
    createdAt: DateTime.parse(json['created_at']),
    updatedAt: DateTime.parse(json['updated_at']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'title': title,
    'description': description,
    'latitude': latitude,
    'longitude': longitude,
    'location_address': locationAddress,
    'media_urls': mediaUrls,
    'upvotes': upvotes,
    'downvotes': downvotes,
    'upvoted_by': upvotedBy,
    'downvoted_by': downvotedBy,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  PublicIncident copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    double? latitude,
    double? longitude,
    String? locationAddress,
    List<String>? mediaUrls,
    int? upvotes,
    int? downvotes,
    List<String>? upvotedBy,
    List<String>? downvotedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => PublicIncident(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    title: title ?? this.title,
    description: description ?? this.description,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    locationAddress: locationAddress ?? this.locationAddress,
    mediaUrls: mediaUrls ?? this.mediaUrls,
    upvotes: upvotes ?? this.upvotes,
    downvotes: downvotes ?? this.downvotes,
    upvotedBy: upvotedBy ?? this.upvotedBy,
    downvotedBy: downvotedBy ?? this.downvotedBy,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
