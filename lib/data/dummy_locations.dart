class LocationArea {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final List<DummyParkingLot> parkingLots;

  LocationArea({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.parkingLots,
  });
}

class DummyParkingLot {
  final String id;
  final String name;
  final String address;
  final int totalSlots;
  final int availableSlots;
  final double pricePerHour;
  final double latitude;
  final double longitude;
  final List<String> images;

  DummyParkingLot({
    required this.id,
    required this.name,
    required this.address,
    required this.totalSlots,
    required this.availableSlots,
    required this.pricePerHour,
    required this.latitude,
    required this.longitude,
    required this.images,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'address': address,
    'totalSlots': totalSlots,
    'availableSlots': availableSlots,
    'pricePerHour': pricePerHour,
    'latitude': latitude,
    'longitude': longitude,
    'images': images,
  };
}

// Dummy data for locations and their parking lots
final List<LocationArea> dummyLocationAreas = [
  LocationArea(
    id: 'area_1',
    name: 'Chittaranjan Park',
    latitude: 28.5355,
    longitude: 77.2073,
    parkingLots: [
      DummyParkingLot(
        id: 'lot_cp_1',
        name: 'CP Star Plaza',
        address: 'Main Road, Chittaranjan Park',
        totalSlots: 50,
        availableSlots: 15,
        pricePerHour: 40.0,
        latitude: 28.5355,
        longitude: 77.2073,
        images: [
          'assets/images/lot1_1.jpg',
          'assets/images/lot1_2.jpeg',
          'assets/images/lot1_3.jpg',
        ],
      ),
      DummyParkingLot(
        id: 'lot_cp_2',
        name: 'CP Market Hub',
        address: 'Market Lane, Chittaranjan Park',
        totalSlots: 45,
        availableSlots: 8,
        pricePerHour: 35.0,
        latitude: 28.5360,
        longitude: 77.2080,
        images: [
          'assets/images/lot2_1.jpg',
          'assets/images/lot2_2.png',
          'assets/images/lot2_3.jpeg',
        ],
      ),
      DummyParkingLot(
        id: 'lot_cp_3',
        name: 'CP Sunset Residency',
        address: 'Residency Road, Chittaranjan Park',
        totalSlots: 60,
        availableSlots: 22,
        pricePerHour: 45.0,
        latitude: 28.5348,
        longitude: 77.2060,
        images: [
          'assets/images/lot3_1.jpeg',
          'assets/images/lot3_2.jpg',
          'assets/images/lot3_3.jpg',
        ],
      ),
      DummyParkingLot(
        id: 'lot_cp_4',
        name: 'CP Grand Center',
        address: 'Community Center, Chittaranjan Park',
        totalSlots: 35,
        availableSlots: 5,
        pricePerHour: 30.0,
        latitude: 28.5370,
        longitude: 77.2090,
        images: [
          'assets/images/lot4_1.jpg',
          'assets/images/lot4_2.jpg',
          'assets/images/lot4_3.jpeg',
        ],
      ),
    ],
  ),
  LocationArea(
    id: 'area_2',
    name: 'Vasant Kunj',
    latitude: 28.5244,
    longitude: 77.1855,
    parkingLots: [
      DummyParkingLot(
        id: 'lot_vk_1',
        name: 'VK Central Square',
        address: 'Central Hub, Vasant Kunj',
        totalSlots: 80,
        availableSlots: 32,
        pricePerHour: 50.0,
        latitude: 28.5244,
        longitude: 77.1855,
        images: [
          'assets/images/lot1_1.jpg',
          'assets/images/lot1_2.jpeg',
          'assets/images/lot1_3.jpg',
        ],
      ),
      DummyParkingLot(
        id: 'lot_vk_2',
        name: 'VK Premium Mall',
        address: 'Shopping Mall, Vasant Kunj',
        totalSlots: 100,
        availableSlots: 12,
        pricePerHour: 60.0,
        latitude: 28.5250,
        longitude: 77.1870,
        images: [
          'assets/images/lot2_1.jpg',
          'assets/images/lot2_2.png',
          'assets/images/lot2_3.jpeg',
        ],
      ),
      DummyParkingLot(
        id: 'lot_vk_3',
        name: 'VK Metro Park',
        address: 'Near Metro Station, Vasant Kunj',
        totalSlots: 55,
        availableSlots: 18,
        pricePerHour: 35.0,
        latitude: 28.5235,
        longitude: 77.1840,
        images: [
          'assets/images/lot3_1.jpeg',
          'assets/images/lot3_2.jpg',
          'assets/images/lot3_3.jpg',
        ],
      ),
      DummyParkingLot(
        id: 'lot_vk_4',
        name: 'VK Alpha Business',
        address: 'Business Park Complex, Vasant Kunj',
        totalSlots: 90,
        availableSlots: 42,
        pricePerHour: 55.0,
        latitude: 28.5260,
        longitude: 77.1875,
        images: [
          'assets/images/lot4_1.jpg',
          'assets/images/lot4_2.jpg',
          'assets/images/lot4_3.jpeg',
        ],
      ),
    ],
  ),
];
