import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../models/admin_metrics.dart';
import '../providers/admin_provider.dart';
import '../providers/parking_provider.dart';
import '../services/api_client.dart';

class AdminLotsScreen extends StatefulWidget {
  const AdminLotsScreen({super.key});

  @override
  State<AdminLotsScreen> createState() => _AdminLotsScreenState();
}

class _AdminLotsScreenState extends State<AdminLotsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    Future.microtask(() => context.read<ParkingProvider>().fetchLots());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _uploadLotImage(String lotId, ApiClient apiClient) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Processing image with AI...')),
    );

    try {
      final res = await apiClient.uploadImage(
        '/api/detection/upload',
        filePath: image.path,
        fields: {'lotId': lotId},
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Found ${res['occupiedSlots']} cars! Available slots updated to ${res['availableSlots']}.',
          ),
        ),
      );
      context.read<ParkingProvider>().fetchLots();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final apiClient = context.read<ApiClient>();
    final parking = context.watch<ParkingProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Lots'),
            Tab(text: 'Analytics'),
            Tab(text: 'Alerts'),
            Tab(text: 'Predictions'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Lots Management
          _buildLotsTab(parking, apiClient),
          // Tab 2: Analytics
          _buildAnalyticsTab(parking),
          // Tab 3: Alerts
          _buildAlertsTab(),
          // Tab 4: Predictions
          _buildPredictionsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AddLotScreen(apiClient: apiClient),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Lot'),
      ),
    );
  }

  Widget _buildLotsTab(
      ParkingProvider parking, ApiClient apiClient) {
    return RefreshIndicator(
      onRefresh: () => parking.fetchLots(),
      child: parking.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: parking.lots.length,
              itemBuilder: (context, index) {
                final lot = parking.lots[index];
                final occupancyPercent =
                    ((lot.totalSlots - lot.availableSlots) /
                            lot.totalSlots *
                            100)
                        .toStringAsFixed(0);
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
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
                                    lot.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    lot.address ?? 'Address unavailable',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.teal[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    '$occupancyPercent%',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.teal[700],
                                      fontSize: 18,
                                    ),
                                  ),
                                  Text(
                                    'Occupied',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Occupancy Bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: (lot.totalSlots - lot.availableSlots) /
                                lot.totalSlots,
                            minHeight: 8,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              lot.availableSlots > lot.totalSlots * 0.3
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${lot.totalSlots - lot.availableSlots}/${lot.totalSlots} slots filled',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _uploadLotImage(
                                  lot.id,
                                  apiClient,
                                ),
                                icon: const Icon(Icons.auto_awesome),
                                label: const Text('AI Detect'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          LotMetricsScreen(lot: lot),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.bar_chart),
                                label: const Text('Details'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildAnalyticsTab(ParkingProvider parking) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Revenue Analytics',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          // Revenue Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildAnalyticsCard(
                  title: 'Total Revenue',
                  value: '₹45,230',
                  subtitle: 'This month',
                  color: Colors.green,
                  icon: Icons.trending_up,
                  onTap: () {
                    _showDetailsDialog(
                      context,
                      'Total Revenue Details',
                      '• Week 1: ₹10,200\n• Week 2: ₹12,500\n• Week 3: ₹11,300\n• Week 4: ₹11,230\n\nTotal: ₹45,230\nGrowth: +15% from last month.',
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAnalyticsCard(
                  title: 'Subscriptions',
                  value: '₹28,500',
                  subtitle: '12 active',
                  color: Colors.blue,
                  icon: Icons.check_circle,
                  onTap: () {
                    _showDetailsDialog(
                      context,
                      'Subscriptions Details',
                      '• Active Monthly: 8\n• Active Yearly: 4\n• Expiring Soon: 2\n• Renewals this week: 5',
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildAnalyticsCard(
                  title: 'Hourly Bookings',
                  value: '₹16,730',
                  subtitle: '234 bookings',
                  color: Colors.orange,
                  icon: Icons.access_time,
                  onTap: () {
                    _showDetailsDialog(
                      context,
                      'Hourly Bookings Details',
                      '• Total Hours Booked: 450 hrs\n• Avg Duration: 1.9 hrs/booking\n• Peak booking time: 10 AM - 12 PM',
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAnalyticsCard(
                  title: 'Pending Payment',
                  value: '₹3,200',
                  subtitle: '8 overdue',
                  color: Colors.red,
                  icon: Icons.warning,
                  onTap: () {
                    _showDetailsDialog(
                      context,
                      'Pending Payment Details',
                      '• User A (Slot P-2): ₹400\n• User B (Slot P-5): ₹800\n• User C (Slot P-8): ₹1,200\n• 5 others: ₹800\n\n*Action required.*',
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Vehicle Type Distribution',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildDistributionRow('Sedans', 145, 0.45),
                  const SizedBox(height: 12),
                  _buildDistributionRow('SUVs', 92, 0.28),
                  const SizedBox(height: 12),
                  _buildDistributionRow('Bikes', 123, 0.37),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDetailsDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildAnalyticsCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Icon(icon, color: color, size: 20),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildDistributionRow(
      String label, int count, double percentage) {
    return InkWell(
      onTap: () {
        _showDetailsDialog(
          context,
          '$label Details',
          '• Total Vehicles: $count\n• Percentage: ${(percentage * 100).toStringAsFixed(0)}%\n\nInsight: $label are maintaining a steady trend over the last 30 days.',
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodyMedium),
                Text('$count (${(percentage * 100).toStringAsFixed(0)}%)'),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage,
                minHeight: 6,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.teal),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertsTab() {
    final admin = context.watch<AdminProvider>();
    return RefreshIndicator(
      onRefresh: () async {
        // In a real app, fetch alerts from admin provider
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Colors.orange[50],
            child: ListTile(
              leading: Icon(Icons.warning, color: Colors.orange[700]),
              title: const Text('Overstay Alert'),
              subtitle: const Text('Slot P-12 • Vehicle ABC123 • 2 hours overdue'),
              trailing: Chip(
                label: const Text('Resolve'),
                backgroundColor: Colors.orange[200],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            color: Colors.red[50],
            child: ListTile(
              leading: Icon(Icons.error, color: Colors.red[700]),
              title: const Text('Unknown Vehicle Detected'),
              subtitle:
                  const Text('Slot P-08 • No reservation found'),
              trailing: Chip(
                label: const Text('Alert'),
                backgroundColor: Colors.red[200],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            color: Colors.blue[50],
            child: ListTile(
              leading: Icon(Icons.info, color: Colors.blue[700]),
              title: const Text('High Occupancy'),
              subtitle: const Text('Lot A reached 85% capacity'),
              trailing: Chip(
                label: const Text('Acknowledged'),
                backgroundColor: Colors.blue[200],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Occupancy Predictions - Next 24 Hours',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          // Simple hourly chart representation
          SizedBox(
            height: 180,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(
                    8,
                    (index) {
                      final height = 30.0 + (index * 8.0);
                      return Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Flexible(
                              child: Container(
                                width: 20,
                                height: height,
                                decoration: BoxDecoration(
                                  color: height > 80
                                      ? Colors.red[400]
                                      : Colors.orange[400],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${index * 3}h',
                              style: Theme.of(context).textTheme.bodySmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Peak Hours Analysis',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildPeakHourRow('9:00 AM - 10:00 AM', '92%', Colors.red),
                  const SizedBox(height: 12),
                  _buildPeakHourRow(
                      '12:00 PM - 1:00 PM', '78%', Colors.orange),
                  const SizedBox(height: 12),
                  _buildPeakHourRow('5:00 PM - 6:00 PM', '88%', Colors.red),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeakHourRow(String time, String percent, Color color) {
    return InkWell(
      onTap: () {
        _showDetailsDialog(
          context,
          'Peak Hour Details: $time',
          '• Estimated Occupancy: $percent\n• Recommended Action: Consider dynamic pricing or staff deployment during this window.\n\nHistorical confidence: 87%',
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(time, style: Theme.of(context).textTheme.bodyMedium),
            Text(percent, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: int.parse(percent.replaceAll('%', '')) / 100,
            minHeight: 6,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
          ],
        ),
      ),
    );
  }
}

// Lot Metrics Details Screen
class LotMetricsScreen extends StatelessWidget {
  const LotMetricsScreen({super.key, required this.lot});

  final dynamic lot;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${lot.name} - Detailed Metrics')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Real-time Status',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatusBox('Available', '${lot.availableSlots}', Colors.green),
                        _buildStatusBox('Occupied', '${lot.totalSlots - lot.availableSlots}', Colors.red),
                        _buildStatusBox('Total', '${lot.totalSlots}', Colors.blue),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Detection Settings',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      title: const Text('AI Detection Enabled'),
                      trailing: Switch(value: true, onChanged: (_) {}),
                    ),
                    ListTile(
                      title: const Text('Detection Accuracy'),
                      subtitle: const Text('87.5% confidence level'),
                      trailing: const Text('87.5%'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBox(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label),
      ],
    );
  }
}

class AddLotScreen extends StatefulWidget {
  const AddLotScreen({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  State<AddLotScreen> createState() => _AddLotScreenState();
}

class _AddLotScreenState extends State<AddLotScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _slotsController = TextEditingController(text: '10');
  final _priceController = TextEditingController(text: '50');
  bool _loading = false;
  List<XFile> _selectedImages = [];

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _slotsController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() => _selectedImages.add(pickedFile));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  void _removeImage(int index) {
    setState(() => _selectedImages.removeAt(index));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      // Create lot
      await widget.apiClient.post(
        '/api/parking/admin/lots',
        body: {
          'name': _nameController.text,
          'address': _addressController.text,
          'latitude': double.tryParse(_latController.text) ?? 0,
          'longitude': double.tryParse(_lngController.text) ?? 0,
          'total_slots': int.tryParse(_slotsController.text) ?? 0,
          'price_per_hour': double.tryParse(_priceController.text) ?? 0,
        },
      );

      // Upload images
      if (_selectedImages.isNotEmpty) {
        for (final image in _selectedImages) {
          try {
            await widget.apiClient.uploadImage(
              '/api/parking/admin/lots/upload-image',
              filePath: image.path,
              fields: {
                'name': _nameController.text,
              },
            );
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Image upload error: $e')),
            );
          }
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Lot created${_selectedImages.isNotEmpty ? ' with ${_selectedImages.length} image(s)' : ''}',
          ),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Parking Lot'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      prefixIcon: Icon(Icons.local_parking),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Enter name' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Address',
                      prefixIcon: Icon(Icons.place_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _latController,
                    decoration: const InputDecoration(
                      labelText: 'Latitude (e.g. 12.97)',
                      prefixIcon: Icon(Icons.my_location_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _lngController,
                    decoration: const InputDecoration(
                      labelText: 'Longitude (e.g. 77.59)',
                      prefixIcon: Icon(Icons.my_location_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _slotsController,
                    decoration: const InputDecoration(
                      labelText: 'Total slots (e.g. 10)',
                      prefixIcon: Icon(Icons.grid_view),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'Price per hour (e.g. 50)',
                      prefixIcon: Icon(Icons.currency_rupee),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 24),
                  // Photos Section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Photos',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Chip(
                            label: Text(
                              '${_selectedImages.length}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            backgroundColor: Colors.teal[100],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_selectedImages.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 24,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey[300]!,
                              style: BorderStyle.solid,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey[50],
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.image_outlined,
                                size: 40,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No photos yet',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: List.generate(
                              _selectedImages.length,
                              (index) => Padding(
                                padding: EdgeInsets.only(
                                  right: index <
                                          _selectedImages.length -
                                              1
                                      ? 8
                                      : 0,
                                ),
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(
                                        File(_selectedImages[index].path),
                                        width: 120,
                                        height: 120,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: () => _removeImage(index),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          padding: const EdgeInsets.all(4),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _loading ? null : _pickImage,
                          icon: const Icon(Icons.add_photo_alternate_outlined),
                          label: const Text('Add Photo'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Create Lot'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

