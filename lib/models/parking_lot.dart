class ParkingLot {
  final String id;
  final String name;
  final String? address;
  final int totalSlots;
  final int availableSlots;
  final double pricePerHour;
  final double latitude;
  final double longitude;
  final List<String>? images;
  final Map<String, double> vehiclePricing; // sedan_per_hour, suv_per_hour, bike_per_hour
  final double occupancyRate; // 0.0 to 1.0
  final bool aiDetectionEnabled;
  final double detectionAccuracy; // 0.0 to 1.0
  final List<String> amenities; // parking features
  final DateTime? lastUpdated;

  ParkingLot({
    required this.id,
    required this.name,
    this.address,
    required this.totalSlots,
    required this.availableSlots,
    required this.pricePerHour,
    required this.latitude,
    required this.longitude,
    this.images,
    Map<String, double>? vehiclePricing,
    this.occupancyRate = 0.0,
    this.aiDetectionEnabled = false,
    this.detectionAccuracy = 0.85,
    List<String>? amenities,
    this.lastUpdated,
  })  : vehiclePricing = vehiclePricing ?? {
          'sedan': pricePerHour,
          'suv': pricePerHour * 1.2,
          'bike': pricePerHour * 0.5,
        },
        amenities = amenities ?? ['Covered Parking', 'Security', 'Lighting'];

  factory ParkingLot.fromJson(Map<String, dynamic> json) {
    final location = json['location'] as Map<String, dynamic>? ?? {};
    final coordinates = location['coordinates'] as List<dynamic>? ?? [0.0, 0.0];
    final basePrice = (json['price_per_hour'] as num?)?.toDouble() ?? 0.0;

    return ParkingLot(
      id: json['_id'] as String,
      name: json['name'] as String? ?? '',
      address: json['address'] as String?,
      totalSlots: json['total_slots'] as int? ?? 0,
      availableSlots: json['available_slots'] as int? ?? 0,
      pricePerHour: basePrice,
      longitude: (coordinates[0] as num).toDouble(),
      latitude: (coordinates[1] as num).toDouble(),
      images: (json['images'] as List<dynamic>?)?.cast<String>(),
      vehiclePricing: {
        'sedan': (json['sedan_price'] as num?)?.toDouble() ?? basePrice,
        'suv': (json['suv_price'] as num?)?.toDouble() ?? (basePrice * 1.2),
        'bike': (json['bike_price'] as num?)?.toDouble() ?? (basePrice * 0.5),
      },
      occupancyRate: (json['occupancy_rate'] as num?)?.toDouble() ?? 0.0,
      aiDetectionEnabled: json['ai_detection'] as bool? ?? false,
      detectionAccuracy: (json['detection_accuracy'] as num?)?.toDouble() ?? 0.85,
      amenities: (json['amenities'] as List<dynamic>?)?.cast<String>(),
      lastUpdated: json['last_updated'] != null
          ? DateTime.parse(json['last_updated'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'name': name,
    'address': address,
    'total_slots': totalSlots,
    'available_slots': availableSlots,
    'price_per_hour': pricePerHour,
    'sedan_price': vehiclePricing['sedan'],
    'suv_price': vehiclePricing['suv'],
    'bike_price': vehiclePricing['bike'],
    'location': {
      'coordinates': [longitude, latitude],
    },
    'images': images,
    'occupancy_rate': occupancyRate,
    'ai_detection': aiDetectionEnabled,
    'detection_accuracy': detectionAccuracy,
    'amenities': amenities,
    'last_updated': lastUpdated?.toIso8601String(),
  };

  double getPriceForVehicle(String vehicleSize) {
    return vehiclePricing[vehicleSize.toLowerCase()] ?? pricePerHour;
  }
}

