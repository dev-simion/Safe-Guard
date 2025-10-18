class UserProfile {
  final String id;
  final String email;
  final String fullName;
  final String? phoneNumber;
  final List<EmergencyContact> emergencyContacts;
  final String? medicalInfo;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    this.phoneNumber,
    this.emergencyContacts = const [],
    this.medicalInfo,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'],
    email: json['email'],
    fullName: json['full_name'],
    phoneNumber: json['phone_number'],
    emergencyContacts: (json['emergency_contacts'] as List?)
        ?.map((e) => EmergencyContact.fromJson(e))
        .toList() ?? [],
    medicalInfo: json['medical_info'],
    createdAt: DateTime.parse(json['created_at']),
    updatedAt: DateTime.parse(json['updated_at']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'full_name': fullName,
    'phone_number': phoneNumber,
    'emergency_contacts': emergencyContacts.map((e) => e.toJson()).toList(),
    'medical_info': medicalInfo,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  UserProfile copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phoneNumber,
    List<EmergencyContact>? emergencyContacts,
    String? medicalInfo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => UserProfile(
    id: id ?? this.id,
    email: email ?? this.email,
    fullName: fullName ?? this.fullName,
    phoneNumber: phoneNumber ?? this.phoneNumber,
    emergencyContacts: emergencyContacts ?? this.emergencyContacts,
    medicalInfo: medicalInfo ?? this.medicalInfo,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

class EmergencyContact {
  final String name;
  final String phoneNumber;
  final String relationship;

  EmergencyContact({
    required this.name,
    required this.phoneNumber,
    required this.relationship,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) => EmergencyContact(
    name: json['name'],
    phoneNumber: json['phone_number'],
    relationship: json['relationship'],
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'phone_number': phoneNumber,
    'relationship': relationship,
  };
}
