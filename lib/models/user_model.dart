class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final String? country;
  final String? profilePictureUrl;
  final Map<String, dynamic> preferences;
  final Map<String, dynamic> securitySettings;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.phoneNumber,
    this.country,
    this.profilePictureUrl,
    Map<String, dynamic>? preferences,
    Map<String, dynamic>? securitySettings,
  })  : preferences = preferences ?? {
          'currency': 'GH₵',
          'theme': 'dark',
          'language': 'en',
        },
        securitySettings = securitySettings ?? {
          'pinEnabled': false,
          'pin': '',
          'biometricEnabled': false,
          'appLockDuration': 'Never',
        };

  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      id: documentId,
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'],
      country: map['country'],
      profilePictureUrl: map['profilePictureUrl'],
      preferences: map['preferences'] != null ? Map<String, dynamic>.from(map['preferences']) : null,
      securitySettings: map['securitySettings'] != null ? Map<String, dynamic>.from(map['securitySettings']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'country': country,
      'profilePictureUrl': profilePictureUrl,
      'preferences': preferences,
      'securitySettings': securitySettings,
    };
  }

  UserModel copyWith({
    String? fullName,
    String? phoneNumber,
    String? country,
    String? profilePictureUrl,
    Map<String, dynamic>? preferences,
    Map<String, dynamic>? securitySettings,
  }) {
    return UserModel(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      country: country ?? this.country,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      preferences: preferences ?? this.preferences,
      securitySettings: securitySettings ?? this.securitySettings,
    );
  }
}
