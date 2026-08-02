import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../providers/parking_provider.dart';
import '../services/config_service.dart';
import '../services/osm_parking_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _controller;
  io.Socket? _socket;
  final OsmParkingService _osmService = OsmParkingService();
  List<OsmParking> _nearbyParkings = [];
  bool _loadingNearby = false;
  bool _locationPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    _connectSocket();
    _loadNearbyParkings();
  }

  String _availabilitySocketUrl() {
    final baseUri = Uri.parse(ConfigService.getSavedUrl());
    return baseUri.replace(path: '/availability').toString();
  }

  void _connectSocket() {
    final socket = io.io(
      _availabilitySocketUrl(),
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );
    socket.connect();
    socket.onConnect((_) {
      final lots = context.read<ParkingProvider>().lots;
      for (final lot in lots) {
        socket.emit('joinLot', lot.id);
      }
    });
    socket.on(
      'availabilityUpdated',
      (data) {
        final lotId = data['lotId'] as String;
        final available = data['availableSlots'] as int;
        context.read<ParkingProvider>().updateAvailability(lotId, available);
        setState(() {});
      },
    );
    _socket = socket;
  }

  Future<void> _loadNearbyParkings() async {
    setState(() => _loadingNearby = true);
    try {
      final position = await _getCurrentPosition();
      if (position == null) {
        return;
      }
      final results = await _osmService.fetchNearby(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      if (!mounted) return;
      setState(() => _nearbyParkings = results);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load nearby parking: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _loadingNearby = false);
      }
    }
  }

  Future<Position?> _getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enable location services to find nearby parking.')),
      );
      return null;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission is required.')),
      );
      return null;
    }

    if (!_locationPermissionGranted && mounted) {
      setState(() => _locationPermissionGranted = true);
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
    );
  }

  @override
  void dispose() {
    _socket?.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lots = context.watch<ParkingProvider>().lots;

    final lotMarkers = lots
        .map(
          (lot) => Marker(
            markerId: MarkerId(lot.id),
            position: LatLng(lot.latitude, lot.longitude),
            infoWindow: InfoWindow(
              title: lot.name,
              snippet:
                  'Available: ${lot.availableSlots}/${lot.totalSlots} (₹${lot.pricePerHour}/hr)',
            ),
          ),
        )
        .toSet();

    final nearbyMarkers = _nearbyParkings
        .map(
          (spot) => Marker(
            markerId: MarkerId('osm_${spot.id}'),
            position: LatLng(spot.latitude, spot.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure,
            ),
            infoWindow: InfoWindow(
              title: spot.name,
              snippet: 'Nearby parking (OSM)',
            ),
          ),
        )
        .toSet();

    final markers = {...lotMarkers, ...nearbyMarkers};

    final initialLat = lots.isNotEmpty ? lots.first.latitude : 12.9716;
    final initialLng = lots.isNotEmpty ? lots.first.longitude : 77.5946;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Parking Map'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loadingNearby ? null : _loadNearbyParkings,
        icon: const Icon(Icons.refresh),
        label: const Text('Nearby'),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(initialLat, initialLng),
              zoom: 13,
            ),
            markers: markers,
            myLocationEnabled: _locationPermissionGranted,
            myLocationButtonEnabled: _locationPermissionGranted,
            onMapCreated: (controller) => _controller = controller,
          ),
          if (_loadingNearby)
            const Positioned(
              top: 12,
              left: 12,
              child: Chip(
                label: Text('Loading nearby parking...'),
              ),
            ),
        ],
      ),
    );
  }
}

