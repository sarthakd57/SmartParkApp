import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../models/booking.dart';
import 'api_client.dart';

class BookingService {
  BookingService(this._apiClient);

  final ApiClient _apiClient;

  Future<Booking> createBooking({
    required String lotId,
    required int durationHours,
    String bookingType = 'hourly',
    String? subscriptionType,
    String vehicleSize = 'sedan',
    bool isPayLater = false,
    double? totalPrice,
    int? customDurationHours,
  }) async {
    final json = await _apiClient.post(
      '/api/bookings',
      body: {
        'lotId': lotId,
        'durationHours': durationHours,
        'bookingType': bookingType,
        'subscriptionType': subscriptionType,
        'vehicleSize': vehicleSize,
        'isPayLater': isPayLater,
        'totalPrice': totalPrice,
        'customDurationHours': customDurationHours,
      },
    );
    return Booking.fromJson(json);
  }

  Future<List<Booking>> getMyBookings() async {
    final list = await _apiClient.getList('/api/bookings/me');
    return list
        .map((e) => Booking.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> createOrder(String bookingId) async {
    final json = await _apiClient.post(
      '/api/payment/create-order',
      body: {
        'bookingId': bookingId,
      },
    );
    return json;
  }

  Future<void> verifyPayment({
    required String bookingId,
    required PaymentSuccessResponse response,
  }) async {
    await _apiClient.post(
      '/api/payment/verify',
      body: {
        'bookingId': bookingId,
        'razorpay_order_id': response.orderId,
        'razorpay_payment_id': response.paymentId,
        'razorpay_signature': response.signature,
      },
    );
  }

  Future<Map<String, dynamic>> cancelSubscription(String bookingId) async {
    final json = await _apiClient.post(
      '/api/bookings/$bookingId/cancel',
      body: {},
    );
    return json;
  }
}

