class AdminMetrics {
  final String lotId;
  final double occupancyRate; // 0.0 to 1.0
  final int totalOccupied;
  final int totalAvailable;
  final double predictedOccupancyPeak; // Next peak occupancy prediction
  final DateTime predictedPeakTime;
  final List<VehicleAlert> vehicleAlerts;
  final Map<String, int> vehicleTypeDistribution; // sedan: count, suv: count, bike: count
  final double totalRevenue;
  final double subscriptionRevenue;
  final double hourlyBookingRevenue;
  final double pendingPayLaterAmount;
  final double overduePayLaterAmount;
  final List<HourlyOccupancy> hourlyPredictions; // Next 24 hours

  AdminMetrics({
    required this.lotId,
    required this.occupancyRate,
    required this.totalOccupied,
    required this.totalAvailable,
    required this.predictedOccupancyPeak,
    required this.predictedPeakTime,
    required this.vehicleAlerts,
    required this.vehicleTypeDistribution,
    required this.totalRevenue,
    required this.subscriptionRevenue,
    required this.hourlyBookingRevenue,
    required this.pendingPayLaterAmount,
    required this.overduePayLaterAmount,
    required this.hourlyPredictions,
  });

  factory AdminMetrics.fromJson(Map<String, dynamic> json) {
    return AdminMetrics(
      lotId: json['lot_id'] as String,
      occupancyRate: (json['occupancy_rate'] as num?)?.toDouble() ?? 0.0,
      totalOccupied: json['total_occupied'] as int? ?? 0,
      totalAvailable: json['total_available'] as int? ?? 0,
      predictedOccupancyPeak: (json['predicted_peak'] as num?)?.toDouble() ?? 0.0,
      predictedPeakTime: DateTime.parse(json['predicted_peak_time'] as String? ?? DateTime.now().toIso8601String()),
      vehicleAlerts: (json['vehicle_alerts'] as List<dynamic>? ?? [])
          .map((alert) => VehicleAlert.fromJson(alert as Map<String, dynamic>))
          .toList(),
      vehicleTypeDistribution: Map<String, int>.from(json['vehicle_distribution'] as Map<String, dynamic>? ?? {}),
      totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0.0,
      subscriptionRevenue: (json['subscription_revenue'] as num?)?.toDouble() ?? 0.0,
      hourlyBookingRevenue: (json['hourly_revenue'] as num?)?.toDouble() ?? 0.0,
      pendingPayLaterAmount: (json['pending_paylater'] as num?)?.toDouble() ?? 0.0,
      overduePayLaterAmount: (json['overdue_paylater'] as num?)?.toDouble() ?? 0.0,
      hourlyPredictions: (json['hourly_predictions'] as List<dynamic>? ?? [])
          .map((pred) => HourlyOccupancy.fromJson(pred as Map<String, dynamic>))
          .toList(),
    );
  }
}

class VehicleAlert {
  final String alertId;
  final String slotId;
  final String alertType; // 'overstay', 'unknown_vehicle', 'detection_error'
  final String vehicleType;
  final DateTime timestamp;
  final String? vehicleNumber;
  final bool isResolved;

  VehicleAlert({
    required this.alertId,
    required this.slotId,
    required this.alertType,
    required this.vehicleType,
    required this.timestamp,
    this.vehicleNumber,
    required this.isResolved,
  });

  factory VehicleAlert.fromJson(Map<String, dynamic> json) {
    return VehicleAlert(
      alertId: json['_id'] as String,
      slotId: json['slot_id'] as String,
      alertType: json['alert_type'] as String,
      vehicleType: json['vehicle_type'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      vehicleNumber: json['vehicle_number'] as String?,
      isResolved: json['is_resolved'] as bool? ?? false,
    );
  }
}

class HourlyOccupancy {
  final DateTime hour;
  final double predictedOccupancy;
  final String? peakIndicator; // 'low', 'medium', 'high'

  HourlyOccupancy({
    required this.hour,
    required this.predictedOccupancy,
    this.peakIndicator,
  });

  factory HourlyOccupancy.fromJson(Map<String, dynamic> json) {
    final occupancy = (json['occupancy'] as num?)?.toDouble() ?? 0.0;
    String? peak;
    if (occupancy < 0.3) {
      peak = 'low';
    } else if (occupancy < 0.7) {
      peak = 'medium';
    } else {
      peak = 'high';
    }

    return HourlyOccupancy(
      hour: DateTime.parse(json['hour'] as String),
      predictedOccupancy: occupancy,
      peakIndicator: peak,
    );
  }
}
