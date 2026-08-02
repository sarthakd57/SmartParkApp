import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;

import '../data/dummy_locations.dart';
import '../models/parking_lot.dart';
import '../providers/auth_provider.dart';
import '../providers/parking_provider.dart';
import '../services/api_client.dart';
import '../services/booking_service.dart';
import 'admin_lots_screen.dart';
import 'lot_detail_screen.dart';
import 'my_bookings_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late TextEditingController _searchController;
  List<LocationArea> _suggestions = [];
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(_onSearchChanged);
    Future.microtask(() {
      context.read<ParkingProvider>().fetchLots();
    });
  }



  void _onSearchChanged() {
    setState(() {
      if (_searchController.text.isEmpty) {
        _suggestions = [];
        _showSuggestions = false;
      } else {
        _suggestions = dummyLocationAreas
            .where((area) => area.name
                .toLowerCase()
                .contains(_searchController.text.toLowerCase()))
            .toList();
        _showSuggestions = _suggestions.isNotEmpty;
      }
    });
  }

  void _selectLocation(LocationArea area) {
    final parkingProvider = context.read<ParkingProvider>();
    final allDbLots = parkingProvider.lots;

    final parkingLots = area.parkingLots.map((dummy) {
      ParkingLot? dbLot;
      for (final lot in allDbLots) {
        if (lot.name.toLowerCase() == dummy.name.toLowerCase()) {
          dbLot = lot;
          break;
        }
      }

      return ParkingLot(
        id: dbLot != null ? dbLot.id : dummy.id,
        name: dummy.name,
        address: dummy.address,
        totalSlots: dummy.totalSlots,
        availableSlots: dummy.availableSlots,
        pricePerHour: dummy.pricePerHour,
        latitude: dummy.latitude,
        longitude: dummy.longitude,
        images: dummy.images,
      );
    }).toList();

    // Update provider with the selected area's lots
    parkingProvider.setLocationAreaLots(parkingLots);

    _searchController.clear();
    setState(() {
      _suggestions = [];
      _showSuggestions = false;
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  double _calculateZoomLevel(List<ParkingLot> lots) {
    if (lots.isEmpty) return 13;
    
    double minLat = lots.first.latitude;
    double maxLat = lots.first.latitude;
    double minLng = lots.first.longitude;
    double maxLng = lots.first.longitude;

    for (final lot in lots) {
      minLat = minLat > lot.latitude ? lot.latitude : minLat;
      maxLat = maxLat < lot.latitude ? lot.latitude : maxLat;
      minLng = minLng > lot.longitude ? lot.longitude : minLng;
      maxLng = maxLng < lot.longitude ? lot.longitude : maxLng;
    }

    final latDiff = (maxLat - minLat).abs();
    final lngDiff = (maxLng - minLng).abs();
    final maxDiff = latDiff > lngDiff ? latDiff : lngDiff;
    
    // Calculate zoom level to fit all markers with padding - zoomed in more for detail
    return (16 - (maxDiff * 15)).clamp(11.0, 15.0);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final parking = context.watch<ParkingProvider>();

    final apiClient = context.read<ApiClient>();
    final bookingService = BookingService(apiClient);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF2E7D6B),
                const Color(0xFF1F5C52),
              ],
            ),
          ),
          child: AppBar(
            leading: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: UnconstrainedBox(
                child: SizedBox(
                  width: 38,
                  height: 38,
                  child: ClipOval(
                    child: Transform.scale(
                      scale: 1.6, // Zoomed in so car is more visible
                      child: Image.asset(
                        'assets/smartpark_logocar.jpeg',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            elevation: 0,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            actions: [
              if (auth.user?.role == 'admin')
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AdminLotsScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.admin_panel_settings),
                    label: const Text('Admin Dashboard'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      foregroundColor: Colors.white,
                      elevation: 0,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: IconButton(
                  icon: const Icon(Icons.settings, color: Colors.white),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SettingsScreen(),
                      ),
                    );
                  },
                  tooltip: 'Settings',
                ),
              ),
            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => parking.fetchLots(),
        child: parking.isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  // Search Bar with Suggestions
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Where to?',
                          prefixIcon: const Icon(Icons.location_on_outlined),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _suggestions = [];
                                      _showSuggestions = false;
                                    });
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                      ),
                      if (_showSuggestions)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(26),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: _suggestions.map((area) {
                              return ListTile(
                                title: Text(area.name),
                                subtitle: Text(
                                    '${area.parkingLots.length} parking lots nearby'),
                                leading: Icon(Icons.location_city,
                                    color: Colors.blue[700]),
                                onTap: () => _selectLocation(area),
                                dense: true,
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Parking Lots Header
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Nearby parking lots',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (parking.lots.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(child: Text('No parking lots available.')),
                    )
                  else
                    ...parking.lots.map(
                      (lot) => _ParkingLotCard(
                        lot: lot,
                        bookingService: bookingService,
                      ),
                    ),
                  // Map with markers
                  if (parking.lots.isNotEmpty) ...[
                    const SizedBox(height: 32),
                    Text(
                      'Parking Lots Map',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        height: 350,
                        width: double.infinity,
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter: LatLng(
                              parking.lots
                                  .map((l) => l.latitude)
                                  .reduce((a, b) => (a + b) / 2),
                              parking.lots
                                  .map((l) => l.longitude)
                                  .reduce((a, b) => (a + b) / 2),
                            ),
                            initialZoom: _calculateZoomLevel(parking.lots),
                            minZoom: 10,
                            maxZoom: 18,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://cartodb-basemaps-{s}.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png',
                              subdomains: const ['a', 'b', 'c'],
                            ),
                            MarkerLayer(
                              markers: parking.lots
                                  .map(
                                    (lot) => Marker(
                                      point: LatLng(lot.latitude, lot.longitude),
                                      width: 140,
                                      height: 100,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: lot.availableSlots > 0
                                                  ? Colors.green
                                                  : Colors.red,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withAlpha(51),
                                                  blurRadius: 4,
                                                ),
                                              ],
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.local_parking,
                                                      color: Colors.white,
                                                      size: 14,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      '${lot.availableSlots}/${lot.totalSlots}',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 2),
                                                SizedBox(
                                                  width: 120,
                                                  child: Text(
                                                    lot.name,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 9,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          CustomPaint(
                                            painter: TrianglePainter(
                                              color: lot.availableSlots > 0
                                                  ? Colors.green
                                                  : Colors.red,
                                            ),
                                            size: const Size(20, 10),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(26),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BottomNavigationBar(
            backgroundColor: Colors.white,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.local_activity_outlined),
                activeIcon: Icon(Icons.local_activity),
                label: 'Active Bookings',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history_outlined),
                activeIcon: Icon(Icons.history),
                label: 'Booking History',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.logout),
                label: 'Logout',
              ),
            ],
            onTap: (index) {
              if (index == 0) {
                // Active Bookings
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MyBookingsScreen(
                      bookingService: bookingService,
                      initialTabIndex: 0,
                    ),
                  ),
                );
              } else if (index == 1) {
                // Booking History
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MyBookingsScreen(
                      bookingService: bookingService,
                      initialTabIndex: 1,
                    ),
                  ),
                );
              } else if (index == 2) {
                // Logout
                auth.logout();
              }
            },
          ),
        ),
      ),
    );
  }
}

class _ParkingLotCard extends StatefulWidget {
  const _ParkingLotCard({
    required this.lot,
    required this.bookingService,
  });

  final ParkingLot lot;
  final BookingService bookingService;

  @override
  State<_ParkingLotCard> createState() => _ParkingLotCardState();
}

class _ParkingLotCardState extends State<_ParkingLotCard>
    with SingleTickerProviderStateMixin {
  int _currentImageIndex = 0;
  late AnimationController _hoverController;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAvailable = widget.lot.availableSlots > 0;
    final availabilityPercent = widget.lot.totalSlots > 0
        ? (widget.lot.availableSlots / widget.lot.totalSlots * 100).toInt()
        : 0;
    
    final hasImages = widget.lot.images != null && widget.lot.images!.isNotEmpty;
    final imageCount = hasImages ? widget.lot.images!.length : 0;

    final statusColor = isAvailable
        ? const Color(0xFF10B981)
        : const Color(0xFFEF4444);

    return GestureDetector(
      onTapDown: (_) => _hoverController.forward(),
      onTapUp: (_) => _hoverController.reverse(),
      onTapCancel: () => _hoverController.reverse(),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ScaleTransition(
          scale: Tween<double>(begin: 1.0, end: 0.98).animate(
            CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => LotDetailScreen(
                    lot: widget.lot,
                    bookingService: widget.bookingService,
                  ),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Enhanced Image Carousel
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      child: SizedBox(
                        height: 160,
                        width: double.infinity,
                        child: hasImages
                            ? Stack(
                                children: [
                                  widget.lot.images![_currentImageIndex].startsWith('http')
                                      ? Image.network(
                                          widget.lot.images![_currentImageIndex],
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              color: Colors.grey[300],
                                              child: Icon(
                                                Icons.image_not_supported,
                                                color: Colors.grey[600],
                                              ),
                                            );
                                          },
                                        )
                                      : Image.asset(
                                          widget.lot.images![_currentImageIndex],
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              color: Colors.grey[300],
                                              child: Icon(
                                                Icons.image_not_supported,
                                                color: Colors.grey[600],
                                              ),
                                            );
                                          },
                                        ),
                                  // Gradient overlay
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withAlpha(102),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Container(
                                color: Colors.grey[300],
                                child: Icon(
                                  Icons.local_parking,
                                  size: 56,
                                  color: Colors.grey[600],
                                ),
                              ),
                      ),
                    ),
                    // Availability Badge - Top Right
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: statusColor.withAlpha(128),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isAvailable
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isAvailable ? 'Available' : 'Full',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Image Carousel Controls
                    if (imageCount > 1) ...[
                      // Indicators Bottom Center
                      Positioned(
                        bottom: 12,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            imageCount,
                            (index) => Container(
                              width: _currentImageIndex == index ? 8 : 6,
                              height: 6,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _currentImageIndex == index
                                    ? Colors.white
                                    : Colors.white70,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Left Arrow
                      Positioned(
                        left: 12,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _currentImageIndex =
                                    (_currentImageIndex - 1 + imageCount) %
                                        imageCount;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.black.withAlpha(179),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.chevron_left,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Right Arrow
                      Positioned(
                        right: 12,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _currentImageIndex =
                                    (_currentImageIndex + 1) % imageCount;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.black.withAlpha(179),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.chevron_right,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                // Details Section
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name and Address
                      Text(
                        widget.lot.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.lot.address ?? 'Address unavailable',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.grey[600]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Availability Bar with Stats
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Availability',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(
                                        color: Colors.grey[700],
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                Text(
                                  '$availabilityPercent%',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(
                                        color: statusColor,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: availabilityPercent / 100,
                                minHeight: 8,
                                backgroundColor: Colors.grey[300],
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(
                                  statusColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${widget.lot.availableSlots}/${widget.lot.totalSlots} slots',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Price and Book Button
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Price',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                              ),
                              const SizedBox(height: 4),
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text:
                                          '₹${widget.lot.pricePerHour.toStringAsFixed(0)}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight:
                                                FontWeight.w800,
                                            color: statusColor,
                                          ),
                                    ),
                                    TextSpan(
                                      text: '/hr',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color:
                                                Colors.grey[600],
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          FilledButton.icon(
                            onPressed: isAvailable
                                ? () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            LotDetailScreen(
                                          lot: widget.lot,
                                          bookingService:
                                              widget
                                                  .bookingService,
                                        ),
                                      ),
                                    );
                                  }
                                : null,
                            icon: const Icon(Icons.directions_car),
                            label: const Text('Book'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Custom painter for map marker pointer
class TrianglePainter extends CustomPainter {
  final Color color;

  TrianglePainter({required this.color});

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    final paint = ui.Paint()
      ..color = color
      ..style = ui.PaintingStyle.fill;

    final path = ui.Path();
    path.moveTo(size.width / 2, size.height);
    path.lineTo(0, 0);
    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(TrianglePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

