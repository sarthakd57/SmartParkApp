class Subscription {
  final String id;
  final String userId;
  final String lotId;
  final String vehicleSize; // 'sedan', 'suv', 'bike'
  final String subscriptionType; // 'monthly', 'quarterly', 'annual'
  final double monthlyPrice;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime renewalDate;
  final bool isActive;
  final int allowedBookingsPerMonth;
  final int usedBookingsThisMonth;

  Subscription({
    required this.id,
    required this.userId,
    required this.lotId,
    required this.vehicleSize,
    required this.subscriptionType,
    required this.monthlyPrice,
    required this.startDate,
    required this.endDate,
    required this.renewalDate,
    required this.isActive,
    this.allowedBookingsPerMonth = 30,
    this.usedBookingsThisMonth = 0,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['_id'] as String,
      userId: json['user_id'] as String,
      lotId: json['lot_id'] as String,
      vehicleSize: json['vehicle_size'] as String? ?? 'sedan',
      subscriptionType: json['subscription_type'] as String? ?? 'monthly',
      monthlyPrice: (json['monthly_price'] as num?)?.toDouble() ?? 0.0,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      renewalDate: DateTime.parse(json['renewal_date'] as String),
      isActive: json['is_active'] as bool? ?? true,
      allowedBookingsPerMonth: json['allowed_bookings'] as int? ?? 30,
      usedBookingsThisMonth: json['used_bookings'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'user_id': userId,
    'lot_id': lotId,
    'vehicle_size': vehicleSize,
    'subscription_type': subscriptionType,
    'monthly_price': monthlyPrice,
    'start_date': startDate.toIso8601String(),
    'end_date': endDate.toIso8601String(),
    'renewal_date': renewalDate.toIso8601String(),
    'is_active': isActive,
    'allowed_bookings': allowedBookingsPerMonth,
    'used_bookings': usedBookingsThisMonth,
  };

  bool get isRenewalDue => DateTime.now().isAfter(renewalDate.subtract(Duration(days: 7)));
  
  bool get isExpired => endDate.isBefore(DateTime.now());
}
