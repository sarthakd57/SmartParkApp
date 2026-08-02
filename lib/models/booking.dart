class Booking {
  final String id;
  final String lotId;
  final String slotId;
  final String paymentStatus; // 'paid', 'pending', 'overdue'
  final DateTime startTime;
  final DateTime? endTime;
  final double totalPrice;
  final String vehicleSize; // 'sedan', 'suv', 'bike'
  final String bookingType; // 'hourly', 'subscription', 'daily'
  final int? customDurationHours; // For custom hourly bookings
  final String? subscriptionId; // Reference to subscription if using subscription
  final bool isPayLater; // If payment is deferred
  final DateTime? paymentDueDate; // For pay later bookings
  final double? latePenalty; // Applied if overdue
  final bool isActive; // Is within active duration and paid

  Booking({
    required this.id,
    required this.lotId,
    required this.slotId,
    required this.paymentStatus,
    required this.startTime,
    this.endTime,
    required this.totalPrice,
    this.vehicleSize = 'sedan',
    this.bookingType = 'hourly',
    this.customDurationHours,
    this.subscriptionId,
    this.isPayLater = false,
    this.paymentDueDate,
    this.latePenalty = 0.0,
    this.isActive = false,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    final isPaid = (json['payment_status'] as String? ?? 'pending') == 'paid';
    
    // Safely parse start time, default to now if missing
    final startTimeStr = json['start_time']?.toString();
    final startTime = startTimeStr != null 
        ? DateTime.tryParse(startTimeStr) ?? DateTime.now() 
        : DateTime.now();

    // Safely parse end time
    final endTimeStr = json['end_time']?.toString();
    final endTime = endTimeStr != null ? DateTime.tryParse(endTimeStr) : null;
    
    final now = DateTime.now();
    
    // Booking is active if: paid AND (endTime is null OR endTime is in future)
    final isActive = isPaid && (endTime == null || endTime.isAfter(now));

    return Booking(
      id: json['_id'] as String? ?? '',
      lotId: json['lot_id'] is Map
          ? (json['lot_id']['_id'] as String? ?? '')
          : (json['lot_id'] as String? ?? ''),
      slotId: json['slot_id'] is Map
          ? (json['slot_id']['_id'] as String? ?? '')
          : (json['slot_id'] as String? ?? ''),
      paymentStatus: json['payment_status'] as String? ?? 'pending',
      startTime: startTime,
      endTime: endTime,
      totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0.0,
      vehicleSize: json['vehicle_size'] as String? ?? 'sedan',
      bookingType: json['booking_type'] as String? ?? 'hourly',
      customDurationHours: json['custom_duration_hours'] as int?,
      subscriptionId: json['subscription_id'] as String?,
      isPayLater: json['is_pay_later'] as bool? ?? false,
      paymentDueDate: json['payment_due_date'] != null
          ? DateTime.tryParse(json['payment_due_date'].toString())
          : null,
      latePenalty: (json['late_penalty'] as num?)?.toDouble() ?? 0.0,
      isActive: isActive,
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'lot_id': lotId,
    'slot_id': slotId,
    'payment_status': paymentStatus,
    'start_time': startTime.toIso8601String(),
    'end_time': endTime?.toIso8601String(),
    'total_price': totalPrice,
    'vehicle_size': vehicleSize,
    'booking_type': bookingType,
    'custom_duration_hours': customDurationHours,
    'subscription_id': subscriptionId,
    'is_pay_later': isPayLater,
    'payment_due_date': paymentDueDate?.toIso8601String(),
    'late_penalty': latePenalty,
    'is_active': isActive,
  };

  bool get isOverdue => 
      isPayLater && 
      paymentDueDate != null && 
      DateTime.now().isAfter(paymentDueDate!);

  bool get isPastDue => endTime != null && DateTime.now().isAfter(endTime!);
}
