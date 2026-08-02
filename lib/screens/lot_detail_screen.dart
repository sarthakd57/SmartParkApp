import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/parking_lot.dart';
import '../services/booking_service.dart';

class LotDetailScreen extends StatefulWidget {
  const LotDetailScreen({
    super.key,
    required this.lot,
    required this.bookingService,
  });

  final ParkingLot lot;
  final BookingService bookingService;

  @override
  State<LotDetailScreen> createState() => _LotDetailScreenState();
}

class _LotDetailScreenState extends State<LotDetailScreen> {
  late Razorpay _razorpay;
  int _durationHours = 1;
  bool _loading = false;
  String _selectedVehicleSize = 'sedan'; // sedan, suv, bike
  bool _useSubscription = false;
  String _subscriptionType = 'monthly'; // monthly, quarterly, annual
  bool _isPayLater = false;
  DateTime? _paymentDueDate;
  
  static const Map<String, String> vehicleSizeLabels = {
    'sedan': 'Sedan',
    'suv': 'SUV',
    'bike': 'Bike',
  };

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  String? _pendingBookingId;

  double _calculatePrice() {
    final basePrice = widget.lot.getPriceForVehicle(_selectedVehicleSize);
    if (_useSubscription) {
      return basePrice * 30; // Monthly subscription (simplified)
    }
    return basePrice * _durationHours;
  }

  void _setPayLaterDueDate() {
    if (_isPayLater) {
      _paymentDueDate = DateTime.now().add(const Duration(days: 7));
    } else {
      _paymentDueDate = null;
    }
  }

  Future<void> _startBooking() async {
    setState(() => _loading = true);
    _setPayLaterDueDate();
    
    try {
      final price = _calculatePrice();
      final booking = await widget.bookingService.createBooking(
        lotId: widget.lot.id,
        durationHours: _durationHours,
        bookingType: _useSubscription ? 'subscription' : 'hourly',
        subscriptionType: _useSubscription ? _subscriptionType : null,
        vehicleSize: _selectedVehicleSize,
        isPayLater: _isPayLater,
        totalPrice: price,
        customDurationHours: _useSubscription ? null : _durationHours,
      );
      _pendingBookingId = booking.id;

      // If pay later, skip payment and confirm booking
      if (_isPayLater) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Booking confirmed! Payment due by ${_paymentDueDate?.toString().split(' ')[0]}',
            ),
          ),
        );
        await _promptNavigation();
        if (!mounted) return;
        Navigator.of(context).pop(true);
        return;
      }

      final order = await widget.bookingService.createOrder(booking.id);

      final options = {
        'key': 'rzp_test_SMqalSL7nmLKYX',
        'amount': order['amount'],
        'currency': order['currency'],
        'name': 'Smart Park',
        'description': _useSubscription
            ? 'Parking subscription ($_subscriptionType)'
            : 'Parking booking',
        'order_id': order['id'],
        'prefill': {'contact': '9999999999', 'email': 'test@parksmart.com'},
        'theme': {'color': '#3399cc'},
      };

      _razorpay.open(options);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start booking: $e')),
      );
      setState(() => _loading = false);
    }
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    if (_pendingBookingId == null) return;
    try {
      await widget.bookingService.verifyPayment(
        bookingId: _pendingBookingId!,
        response: response,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment successful')),
      );
      await _promptNavigation();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Verification failed: $e')),
      );
    } finally {
      setState(() => _loading = false);
      _pendingBookingId = null;
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Wallet: ${response.walletName}")),
    );
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment failed: ${response.message}')),
    );
    setState(() => _loading = false);
    _pendingBookingId = null;
  }

  Future<void> _promptNavigation() async {
    final shouldNavigate = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start navigation?'),
        content: const Text('Get live directions to your parking spot.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Navigate'),
          ),
        ],
      ),
    );

    if (shouldNavigate == true) {
      await _openNavigation();
    }
  }

  Future<void> _openNavigation() async {
    final destination = '${widget.lot.latitude},${widget.lot.longitude}';
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$destination&travelmode=driving',
    );
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Google Maps')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPrice = _calculatePrice();

    return Scaffold(
      appBar: AppBar(title: Text(widget.lot.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Lot Info Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.lot.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.lot.address ?? 'Address unavailable',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      Chip(
                        label: Text(
                          '${widget.lot.availableSlots}/${widget.lot.totalSlots} slots',
                        ),
                      ),
                      Chip(
                        label: Text(
                          '${(widget.lot.occupancyRate * 100).toStringAsFixed(0)}% occupied',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Vehicle Size Selection
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vehicle Type',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<String>(
                    segments: vehicleSizeLabels.entries
                        .map((e) => ButtonSegment(
                              value: e.key,
                              label: Text(e.value),
                            ))
                        .toList(),
                    selected: {_selectedVehicleSize},
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() => _selectedVehicleSize = newSelection.first);
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₹${widget.lot.getPriceForVehicle(_selectedVehicleSize)}/hour',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Booking Type Selection (Hourly vs Subscription)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Booking Type',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  // Hourly Option
                  RadioListTile<bool>(
                    title: const Text('Hourly Booking'),
                    subtitle: const Text('Pay per hour'),
                    value: false,
                    groupValue: _useSubscription,
                    onChanged: (value) {
                      setState(() => _useSubscription = value ?? false);
                    },
                  ),
                  if (!_useSubscription)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: DropdownButtonFormField<int>(
                        initialValue: _durationHours,
                        decoration: const InputDecoration(
                          labelText: 'Duration (hours)',
                          contentPadding: EdgeInsets.all(12),
                        ),
                        items: List.generate(
                          12,
                          (index) => DropdownMenuItem(
                            value: index + 1,
                            child: Text('${index + 1}h'),
                          ),
                        ),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _durationHours = value);
                          }
                        },
                      ),
                    ),
                  // Subscription Option
                  RadioListTile<bool>(
                    title: const Text('Subscription'),
                    subtitle: const Text('Recurring subscription plan'),
                    value: true,
                    groupValue: _useSubscription,
                    onChanged: (value) {
                      setState(() => _useSubscription = value ?? false);
                    },
                  ),
                  if (_useSubscription) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: DropdownButtonFormField<String>(
                        initialValue: _subscriptionType,
                        decoration: const InputDecoration(
                          labelText: 'Subscription Duration',
                          contentPadding: EdgeInsets.all(12),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'monthly',
                            child: Text('Monthly'),
                          ),
                          DropdownMenuItem(
                            value: 'quarterly',
                            child: Text('Quarterly (3 months)'),
                          ),
                          DropdownMenuItem(
                            value: 'annual',
                            child: Text('Annual'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _subscriptionType = value);
                          }
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Payment Method Selection
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payment Method',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  // Pay Now Option
                  RadioListTile<bool>(
                    title: const Text('Pay Now'),
                    subtitle: const Text('Immediate payment via card/UPI'),
                    value: false,
                    groupValue: _isPayLater,
                    onChanged: (value) {
                      setState(() => _isPayLater = value ?? false);
                    },
                  ),
                  if (!_isPayLater)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green[700]),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Secure Payment',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[700],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Instant confirmation • No penalties',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Pay Later Option
                  RadioListTile<bool>(
                    title: const Text('Pay Later'),
                    subtitle: const Text('Pay within 7 days'),
                    value: true,
                    groupValue: _isPayLater,
                    onChanged: (value) {
                      setState(() => _isPayLater = value ?? false);
                    },
                  ),
                  if (_isPayLater)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.schedule,
                                    color: Colors.orange[700]),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Deferred Payment',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.orange[100],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Payment Terms:',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.orange[900],
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '• Due: 7 days from booking',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.orange[800],
                                    ),
                                  ),
                                  Text(
                                    '• Late penalty: 5% after due date',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.orange[800],
                                    ),
                                  ),
                                  Text(
                                    '• Automatic reminders sent',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.orange[800],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Price Summary
          Card(
            color: Colors.teal[50],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _useSubscription ? 'Subscription:' : 'Duration:',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        _useSubscription
                            ? _subscriptionType
                            : '${_durationHours}h',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Price per unit:',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        '₹${widget.lot.getPriceForVehicle(_selectedVehicleSize)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total:',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '₹${totalPrice.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.teal[700],
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  if (_isPayLater) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Payment due: ${_paymentDueDate?.toString().split(' ')[0] ?? DateTime.now().add(Duration(days: 7)).toString().split(' ')[0]}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.orange[700],
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loading ? null : _startBooking,
            child: _loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_isPayLater ? 'Book (Pay Later)' : 'Book & Pay'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
