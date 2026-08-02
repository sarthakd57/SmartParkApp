import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/booking.dart';
import '../providers/parking_provider.dart';
import '../services/booking_service.dart';
import 'lot_detail_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({
    super.key,
    required this.bookingService,
    this.initialTabIndex = 0,
    this.showAllTabs = false, // If true, shows both tabs; if false, only shows selected tab
  });

  final BookingService bookingService;
  final int initialTabIndex; // 0 = Active, 1 = History
  final bool showAllTabs; // Control whether to show tab switching

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<Booking>> _bookingsFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _bookingsFuture = widget.bookingService.getMyBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.initialTabIndex == 0 ? 'Active Bookings' : 'Booking History';
    
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        // Only show tabs if showAllTabs is true
        bottom: widget.showAllTabs
            ? TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Active'),
                  Tab(text: 'History'),
                ],
              )
            : null,
      ),
      body: widget.showAllTabs
          ? TabBarView(
              controller: _tabController,
              children: [
                _buildActiveBookingsTab(),
                _buildHistoryTab(),
              ],
            )
          : (widget.initialTabIndex == 0
              ? _buildActiveBookingsTab()
              : _buildHistoryTab()),
    );
  }

  Widget _buildActiveBookingsTab() {
    return FutureBuilder<List<Booking>>(
      future: _bookingsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final bookings = snapshot.data ?? [];
        final activeBookings = bookings
            .where((b) => b.isActive && b.paymentStatus == 'paid')
            .toList();

        // Separate subscriptions and hourly bookings
        final subscriptionBookings =
            activeBookings.where((b) => b.bookingType == 'subscription').toList();
        final hourlyBookings =
            activeBookings.where((b) => b.bookingType == 'hourly').toList();

        if (activeBookings.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today,
                      size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No Active Bookings',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Book a parking spot to get started',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            if (subscriptionBookings.isNotEmpty) ...[
              Text(
                'Subscriptions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              ...subscriptionBookings.map((booking) =>
                  _buildSubscriptionCard(context, booking)),
              const SizedBox(height: 24),
            ],
            if (hourlyBookings.isNotEmpty) ...[
              Text(
                'Hourly Bookings',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              ...hourlyBookings.map((booking) =>
                  _buildBookingCard(context, booking)),
            ],
          ],
        );
      },
    );
  }

  Widget _buildSubscriptionCard(BuildContext context, Booking subscription) {
    final endDate = subscription.endTime ?? DateTime.now();
    final daysRemaining =
        endDate.difference(DateTime.now()).inDays;
    final isExpiringSoon = daysRemaining <= 7;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.teal[100],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              subscription.vehicleSize.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal[700],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isExpiringSoon)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange[100],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Expires in $daysRemaining days',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.orange[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ID: ${subscription.id.substring(0, 8)}...',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Valid until: ${endDate.toString().split(' ')[0]}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[700],
                            ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '₹${subscription.totalPrice.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.teal[700],
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _showRenewDialog(context, subscription);
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Renew'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      _showCancelDialog(context, subscription);
                    },
                    icon: const Icon(Icons.close),
                    label: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(BuildContext context, Booking booking) {
    final isPaid = booking.paymentStatus == 'paid';
    final isPending = booking.paymentStatus == 'pending';
    final isOverdue = booking.isOverdue;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Booking ${booking.id.substring(0, 6)}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.directions_car,
                              size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            booking.vehicleSize.capitalize(),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.access_time,
                              size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '${booking.customDurationHours ?? 1}h',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${booking.totalPrice.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isPaid
                            ? Colors.green[100]
                            : isOverdue
                                ? Colors.red[100]
                                : Colors.orange[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isPaid
                            ? 'Paid'
                            : isOverdue
                                ? 'Overdue'
                                : 'Pending',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isPaid
                              ? Colors.green[700]
                              : isOverdue
                                  ? Colors.red[700]
                                  : Colors.orange[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${booking.startTime.toString().split(' ')[0]} - ${booking.endTime?.toString().split(' ')[0] ?? 'Ongoing'}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[700],
                  ),
            ),
            if (isPending || isOverdue) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _showPaymentDialog(context, booking);
                  },
                  child: Text(isOverdue ? 'Pay Overdue Amount' : 'Pay Now'),
                ),
              ),
            ] else ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    _showBookAgainDialog(context, booking);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Book Again'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    return FutureBuilder<List<Booking>>(
      future: _bookingsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final allBookings = snapshot.data ?? [];
        // History: everything that is NOT (paid AND active)
        // This includes: expired bookings, unpaid bookings, past due bookings, cancelled, etc.
        final historyBookings = allBookings
            .where((b) => !b.isActive || b.paymentStatus != 'paid')
            .toList();

        if (historyBookings.isEmpty) {
          return const Center(child: Text('No booking history.'));
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: historyBookings.length,
          separatorBuilder: (_, _) => const SizedBox(height: 4),
          itemBuilder: (context, index) {
            final b = historyBookings[index];
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey[200],
                  child: Icon(
                    Icons.history,
                    color: Colors.grey[700],
                  ),
                ),
                title: Text('Booking ${b.id.substring(0, 6)}'),
                subtitle: Text(
                  '${b.startTime.toString().split(' ')[0]} • ${b.vehicleSize.capitalize()} • ₹${b.totalPrice.toStringAsFixed(0)}',
                ),
                trailing: Chip(
                  label: Text(
                    b.paymentStatus.capitalize(),
                    style: TextStyle(
                      fontSize: 11,
                      color: b.paymentStatus == 'paid'
                          ? Colors.green[700]
                          : Colors.orange[700],
                    ),
                  ),
                  backgroundColor: b.paymentStatus == 'paid'
                      ? Colors.green[100]
                      : Colors.orange[100],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _navigateToLotDetail(Booking booking) async {
    final parkingProvider = context.read<ParkingProvider>();
    var lot = parkingProvider.lots.where((l) => l.id == booking.lotId).firstOrNull;
    
    if (lot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fetching lot details...')),
      );
      await parkingProvider.fetchLots();
      lot = parkingProvider.lots.where((l) => l.id == booking.lotId).firstOrNull;
    }
    
    if (!mounted) return;

    if (lot != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LotDetailScreen(
            lot: lot!,
            bookingService: widget.bookingService,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Parking lot is currently unavailable')),
      );
    }
  }

  void _showRenewDialog(BuildContext context, Booking subscription) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Renew Subscription'),
        content: const Text(
          'Would you like to go to the lot page to renew your subscription?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToLotDetail(subscription);
            },
            child: const Text('Renew'),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(BuildContext context, Booking subscription) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Subscription'),
        content: const Text(
          'Are you sure you want to cancel? You will lose access immediately.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // Show loading
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cancelling subscription...'),
                  duration: Duration(seconds: 1),
                ),
              );

              try {
                // Call API to cancel subscription
                final result = await widget.bookingService.cancelSubscription(subscription.id);
                
                if (!mounted) return;
                
                // Show success message with refund info
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Subscription cancelled',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          result['refundMessage'] ?? 'Your refund will be processed within 5 days',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    duration: const Duration(seconds: 5),
                    backgroundColor: Colors.orange[700],
                  ),
                );

                // Refresh bookings list
                if (mounted) {
                  setState(() {
                    _bookingsFuture = widget.bookingService.getMyBookings();
                  });
                }
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to cancel: $e'),
                    duration: const Duration(seconds: 3),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancel Subscription'),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog(BuildContext context, Booking booking) {
    String? selectedMethod;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Complete Payment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Amount Due: ₹${booking.totalPrice.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Text(
                'Payment Method',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              RadioListTile(
                title: const Text('Card'),
                value: 'card',
                groupValue: selectedMethod,
                onChanged: (value) => setState(() => selectedMethod = value),
              ),
              RadioListTile(
                title: const Text('UPI'),
                value: 'upi',
                groupValue: selectedMethod,
                onChanged: (value) => setState(() => selectedMethod = value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedMethod == null
                  ? null
                  : () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Payment via $selectedMethod initiated',
                          ),
                        ),
                      );
                    },
              child: const Text('Pay'),
            ),
          ],
        ),
      ),
    );
  }

  void _showBookAgainDialog(BuildContext context, Booking booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Book Again'),
        content: const Text(
          'Would you like to go to the lot page to book again?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToLotDetail(booking);
            },
            child: const Text('Book Again'),
          ),
        ],
      ),
    );
  }
}

extension StringCapitalization on String {
  String capitalize() {
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}

