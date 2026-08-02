import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/parking_lot.dart';
import '../services/api_client.dart';

class ParkingProvider extends ChangeNotifier {
  ParkingProvider(this._apiClient);

  final ApiClient _apiClient;

  List<ParkingLot> _lots = [];
  List<ParkingLot> _searchResults = [];
  List<ParkingLot> _nearbyLots = [];
  bool _loading = false;
  String? _searchQuery;
  double? _userLatitude;
  double? _userLongitude;
  String? _userLocationName;

  List<ParkingLot> get lots => _lots;
  List<ParkingLot> get searchResults => _searchResults;
  List<ParkingLot> get nearbyLots => _nearbyLots;
  bool get isLoading => _loading;
  String? get searchQuery => _searchQuery;
  bool get hasSearchResults => _searchResults.isNotEmpty;
  double? get userLatitude => _userLatitude;
  double? get userLongitude => _userLongitude;
  String? get userLocationName => _userLocationName;

  Future<void> fetchLots() async {
    _setLoading(true);
    try {
      final list = await _apiClient.getList('/api/parking/lots');
      _lots = list
          .map((e) => ParkingLot.fromJson(e as Map<String, dynamic>))
          .toList();
    } finally {
      _setLoading(false);
    }
  }

  void updateAvailability(String lotId, int availableSlots) {
    final index = _lots.indexWhere((l) => l.id == lotId);
    if (index != -1) {
      final lot = _lots[index];
      _lots[index] = ParkingLot(
        id: lot.id,
        name: lot.name,
        address: lot.address,
        totalSlots: lot.totalSlots,
        availableSlots: availableSlots,
        pricePerHour: lot.pricePerHour,
        latitude: lot.latitude,
        longitude: lot.longitude,
      );
      notifyListeners();
    }
  }

  /// Search parking lots by location coordinates
  Future<void> searchByLocation({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  }) async {
    _setLoading(true);
    _searchQuery = 'Lat: $latitude, Lon: $longitude';
    try {
      final list = await _apiClient.getList('/api/parking/lots');
      final allLots = list
          .map((e) => ParkingLot.fromJson(e as Map<String, dynamic>))
          .toList();

      // Filter lots within radius and sort by distance
      _searchResults = allLots
          .where((lot) {
            final distance = _calculateDistance(
              latitude,
              longitude,
              lot.latitude,
              lot.longitude,
            );
            return distance <= radiusKm;
          })
          .toList();

      // Sort by distance
      _searchResults.sort((a, b) {
        final distA = _calculateDistance(
          latitude,
          longitude,
          a.latitude,
          a.longitude,
        );
        final distB = _calculateDistance(
          latitude,
          longitude,
          b.latitude,
          b.longitude,
        );
        return distA.compareTo(distB);
      });
    } finally {
      _setLoading(false);
    }
  }

  /// Search parking lots by location name (this would ideally hit a geocoding service)
  Future<void> searchByLocationName(String locationName) async {
    _setLoading(true);
    _searchQuery = locationName;
    try {
      final list = await _apiClient.getList('/api/parking/lots');
      _searchResults = list
          .map((e) => ParkingLot.fromJson(e as Map<String, dynamic>))
          .toList();

      // Filter by name or address if it contains the search query
      _searchResults = _searchResults
          .where((lot) =>
              lot.name.toLowerCase().contains(locationName.toLowerCase()) ||
              (lot.address?.toLowerCase().contains(locationName.toLowerCase()) ?? false))
          .toList();
    } finally {
      _setLoading(false);
    }
  }

  /// Clear search results
  void clearSearch() {
    _searchResults = [];
    _searchQuery = null;
    notifyListeners();
  }

  /// Calculate distance between two coordinates using Haversine formula (in km)
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const R = 6371; // Earth radius in kilometers
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) * math.cos(_toRad(lat2)) *
            math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  double _toRad(double degree) {
    return degree * math.pi / 180;
  }

  /// Set user location and name
  void setUserLocation({
    required double latitude,
    required double longitude,
    String? locationName,
  }) {
    _userLatitude = latitude;
    _userLongitude = longitude;
    _userLocationName = locationName;
    notifyListeners();
  }

  /// Set parking lots for a selected location area
  void setLocationAreaLots(List<dynamic> parkingLotsData) {
    try {
      _lots = parkingLotsData.map((lot) {
        if (lot is ParkingLot) {
          return lot;
        } else if (lot.runtimeType.toString().contains('DummyParkingLot')) {
          // Handle dummy data format by accessing properties dynamically
          return ParkingLot(
            id: lot.id as String,
            name: lot.name as String,
            address: lot.address as String,
            totalSlots: lot.totalSlots as int,
            availableSlots: lot.availableSlots as int,
            pricePerHour: lot.pricePerHour as double,
            latitude: lot.latitude as double,
            longitude: lot.longitude as double,
            images: lot.images as List<String>?,
          );
        }
        return null;
      }).whereType<ParkingLot>().toList();
      notifyListeners();
    } catch (e) {
      // Handle conversion error
    }
  }

  /// Fetch nearby lots based on user's current location
  Future<void> fetchNearbyLots({
    double radiusKm = 5.0,
  }) async {
    if (_userLatitude == null || _userLongitude == null) {
      return;
    }

    _setLoading(true);
    try {
      final list = await _apiClient.getList('/api/parking/lots');
      final allLots = list
          .map((e) => ParkingLot.fromJson(e as Map<String, dynamic>))
          .toList();

      // Filter lots within radius and sort by distance
      _nearbyLots = allLots
          .where((lot) {
            final distance = _calculateDistance(
              _userLatitude!,
              _userLongitude!,
              lot.latitude,
              lot.longitude,
            );
            return distance <= radiusKm;
          })
          .toList();

      // Sort by distance
      _nearbyLots.sort((a, b) {
        final distA = _calculateDistance(
          _userLatitude!,
          _userLongitude!,
          a.latitude,
          a.longitude,
        );
        final distB = _calculateDistance(
          _userLatitude!,
          _userLongitude!,
          b.latitude,
          b.longitude,
        );
        return distA.compareTo(distB);
      });
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }
}

