class UserModel {
  final int id;
  final String fullName;
  final String email;
  final String phone;
  final String role; // ROLE_RENTER, ROLE_OWNER, ROLE_BOTH
  final String? cccdNumber;
  final String? driverLicense;
  final String? avatarUrl;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    this.cccdNumber,
    this.driverLicense,
    this.avatarUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'ROLE_RENTER',
      cccdNumber: json['cccd_number'],
      driverLicense: json['driver_license'],
      avatarUrl: json['avatar_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'role': role,
      'cccd_number': cccdNumber,
      'driver_license': driverLicense,
      'avatar_url': avatarUrl,
    };
  }
}

