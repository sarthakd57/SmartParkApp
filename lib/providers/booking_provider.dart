import 'package:flutter/material.dart';

import '../models/booking.dart';
import '../services/booking_service.dart';

class BookingProvider extends ChangeNotifier {
  BookingProvider(this._bookingService);

  final BookingService _bookingService;

  List<Booking> _bookings = [];
  bool _loading = false;
  String? _error;

  List<Booking> get bookings => _bookings;
  bool get isLoading => _loading;
  String? get error => _error;

  // Get only active bookings (not ended)
  List<Booking> get activeBookings =>
      _bookings.where((b) => b.endTime == null || b.endTime!.isAfter(DateTime.now())).toList();

  Future<void> fetchActiveBookings() async {
    _setLoading(true);
    _error = null;
    try {
      _bookings = await _bookingService.getMyBookings();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }
}
