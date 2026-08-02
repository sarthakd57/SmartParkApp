import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/parking_lot.dart';
import '../services/booking_service.dart';

class ParkingLotsMapView extends StatefulWidget {
  final List<ParkingLot> lots;
  final BookingService bookingService;
  final String? selectedAreaName;
  final void Function(ParkingLot lot)? onLotTap;

  const ParkingLotsMapView({
    super.key,
    required this.lots,
    required this.bookingService,
    this.selectedAreaName,
    this.onLotTap,
  });

  @override
  State<ParkingLotsMapView> createState() => _ParkingLotsMapViewState();
}

class _ParkingLotsMapViewState extends State<ParkingLotsMapView>
    with TickerProviderStateMixin {
  late MapController mapController;
  late List<AnimationController> markerAnimations;
  late List<Animation<double>> markerScales;
  ParkingLot? selectedLot;

  @override
  void initState() {
    super.initState();
    mapController = MapController();
    _setupMarkerAnimations();
  }

  void _setupMarkerAnimations() {
    markerAnimations = [];
    markerScales = [];
    
    for (int i = 0; i < widget.lots.length; i++) {
      final controller = AnimationController(
        duration: Duration(milliseconds: 800 + (i * 100)),
        vsync: this,
      );
      final scale = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.elasticOut),
      );
      
      markerAnimations.add(controller);
      markerScales.add(scale);
      controller.forward();
    }
  }

  @override
  void didUpdateWidget(ParkingLotsMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lots != widget.lots) {
      for (var controller in markerAnimations) {
        controller.dispose();
      }
      _setupMarkerAnimations();
      _updateMapBounds();
    }
  }

  void _updateMapBounds() {
    if (widget.lots.isEmpty) return;
    
    double minLat = widget.lots.first.latitude;
    double maxLat = widget.lots.first.latitude;
    double minLng = widget.lots.first.longitude;
    double maxLng = widget.lots.first.longitude;

    for (final lot in widget.lots) {
      minLat = minLat > lot.latitude ? lot.latitude : minLat;
      maxLat = maxLat < lot.latitude ? lot.latitude : maxLat;
      minLng = minLng > lot.longitude ? lot.longitude : minLng;
      maxLng = maxLng < lot.longitude ? lot.longitude : maxLng;
    }

    const padding = 0.005;
    minLat -= padding;
    maxLat += padding;
    minLng -= padding;
    maxLng += padding;

    final centerLat = (minLat + maxLat) / 2;
    final centerLng = (minLng + maxLng) / 2;
    final latDiff = (maxLat - minLat).abs();
    final lngDiff = (maxLng - minLng).abs();
    final maxDiff = latDiff > lngDiff ? latDiff : lngDiff;
    final zoom = (16 - (maxDiff * 9)).clamp(10.0, 18.0);
    
    mapController.move(LatLng(centerLat, centerLng), zoom);
  }

  void _showLotDetails(ParkingLot lot) {
    setState(() => selectedLot = lot);
  }

  void _handleMarkerTap(ParkingLot lot) {
    _showLotDetails(lot);
    widget.onLotTap?.call(lot);
  }

  @override
  void dispose() {
    for (var controller in markerAnimations) {
      controller.dispose();
    }
    mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.lots.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              'No parking lots available',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      );
    }

    // Calculate bounds with padding
    double minLat = widget.lots.first.latitude;
    double maxLat = widget.lots.first.latitude;
    double minLng = widget.lots.first.longitude;
    double maxLng = widget.lots.first.longitude;

    for (final lot in widget.lots) {
      minLat = minLat > lot.latitude ? lot.latitude : minLat;
      maxLat = maxLat < lot.latitude ? lot.latitude : maxLat;
      minLng = minLng > lot.longitude ? lot.longitude : minLng;
      maxLng = maxLng < lot.longitude ? lot.longitude : maxLng;
    }

    // Add padding to bounds (0.005 degrees ≈ 0.5km)
    const padding = 0.005;
    minLat -= padding;
    maxLat += padding;
    minLng -= padding;
    maxLng += padding;

    final centerLat = (minLat + maxLat) / 2;
    final centerLng = (minLng + maxLng) / 2;
    
    // Calculate zoom to fit all markers
    final latDiff = (maxLat - minLat).abs();
    final lngDiff = (maxLng - minLng).abs();
    final maxDiff = latDiff > lngDiff ? latDiff : lngDiff;
    final initialZoom = (16 - (maxDiff * 9)).clamp(10.0, 18.0);

    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: LatLng(centerLat, centerLng),
        initialZoom: initialZoom,
        minZoom: 10,
        maxZoom: 18,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://cartodb-basemaps-{s}.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
        ),
        MarkerLayer(
          markers: List.generate(widget.lots.length, (index) {
            final lot = widget.lots[index];
            return Marker(
              point: LatLng(lot.latitude, lot.longitude),
              child: ScaleTransition(
                scale: markerScales[index],
                child: GestureDetector(
                  onTap: () => _handleMarkerTap(lot),
                  child: _ParkingMarker(
                    isSelected: selectedLot?.id == lot.id,
                    availableSlots: lot.availableSlots,
                    totalSlots: lot.totalSlots,
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _ParkingMarker extends StatelessWidget {
  final bool isSelected;
  final int availableSlots;
  final int totalSlots;

  const _ParkingMarker({
    required this.isSelected,
    required this.availableSlots,
    required this.totalSlots,
  });

  @override
  Widget build(BuildContext context) {
    final isAvailable = availableSlots > 0;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isSelected ? 90 : 75,
      height: isSelected ? 90 : 75,
      decoration: BoxDecoration(
        color: isAvailable ? Colors.green : Colors.red,
        borderRadius: BorderRadius.circular(12),
        border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
        boxShadow: [
          BoxShadow(
            color: (isAvailable ? Colors.green : Colors.red)
                .withAlpha(128),
            blurRadius: isSelected ? 16 : 8,
            spreadRadius: isSelected ? 3 : 1,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.local_parking,
                color: Colors.white,
                size: isSelected ? 28 : 24,
              ),
              Text(
                '$availableSlots',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: isSelected ? 10 : 8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
