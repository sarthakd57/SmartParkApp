class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? vehicleType; // 'sedan', 'suv', 'bike'
  final String? vehicleNumber; // License plate number
  final List<String> activeSubscriptionIds;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.vehicleType = 'sedan',
    this.vehicleNumber,
    List<String>? activeSubscriptionIds,
  }) : activeSubscriptionIds = activeSubscriptionIds ?? [];

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'user',
      vehicleType: json['vehicle_type'] as String? ?? 'sedan',
      vehicleNumber: json['vehicle_number'] as String?,
      activeSubscriptionIds: (json['active_subscriptions'] as List<dynamic>?)
          ?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'role': role,
    'vehicle_type': vehicleType,
    'vehicle_number': vehicleNumber,
    'active_subscriptions': activeSubscriptionIds,
  };
}

