import 'package:flutter/material.dart';

import '../models/admin_metrics.dart';
import '../services/api_client.dart';

class AdminProvider extends ChangeNotifier {
  final ApiClient _apiClient;

  final Map<String, AdminMetrics> _metricsPerLot = {}; // lotId -> metrics
  final List<VehicleAlert> _activeAlerts = [];
  bool _loading = false;
  String? _error;

  Map<String, AdminMetrics> get metricsPerLot => _metricsPerLot;
  List<VehicleAlert> get activeAlerts => _activeAlerts;
  bool get isLoading => _loading;
  String? get error => _error;

  AdminProvider(this._apiClient);

  AdminMetrics? getMetricsForLot(String lotId) => _metricsPerLot[lotId];

  List<VehicleAlert> getUnresolvedAlerts(String lotId) =>
      _activeAlerts.where((alert) => !alert.isResolved).toList();

  Future<void> fetchMetricsForLot(String lotId) async {
    _setLoading(true);
    _error = null;
    try {
      // TODO: Implement API endpoint
      // final response = await _apiClient.get('/admin/metrics/$lotId');
      // final metrics = AdminMetrics.fromJson(response as Map<String, dynamic>);
      // _metricsPerLot[lotId] = metrics;
      // _activeAlerts = metrics.vehicleAlerts;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchAllMetrics(List<String> lotIds) async {
    _setLoading(true);
    _error = null;
    try {
      for (final lotId in lotIds) {
        await fetchMetricsForLot(lotId);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> resolveAlert(String alertId) async {
    _setLoading(true);
    _error = null;
    try {
      // TODO: Implement API endpoint
      // await _apiClient.post('/admin/alerts/$alertId/resolve', {});
      _activeAlerts.removeWhere((alert) => alert.alertId == alertId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>> getOccupancyHeatmap(String lotId) async {
    _setLoading(true);
    _error = null;
    try {
      // TODO: Implement API endpoint
      // final response = await _apiClient.get('/admin/heatmap/$lotId');
      return {};
    } catch (e) {
      _error = e.toString();
      return {};
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>> getRevenueAnalytics(String lotId,
      {required DateTime startDate, required DateTime endDate}) async {
    _setLoading(true);
    _error = null;
    try {
      // TODO: Implement API endpoint
      // final response = await _apiClient.get('/admin/analytics/revenue/$lotId', {
      //   'start_date': startDate.toIso8601String(),
      //   'end_date': endDate.toIso8601String(),
      // });
      return {
        'total_revenue': 0.0,
        'subscription_revenue': 0.0,
        'hourly_revenue': 0.0,
      };
    } catch (e) {
      _error = e.toString();
      return {};
    } finally {
      _setLoading(false);
    }
  }

  Future<List<HourlyOccupancy>> getPredictionFor24Hours(String lotId) async {
    _setLoading(true);
    _error = null;
    try {
      // TODO: Implement API endpoint
      // final response = await _apiClient.get('/admin/predictions/$lotId');
      // return (response as List<dynamic>)
      //     .map((json) => HourlyOccupancy.fromJson(json as Map<String, dynamic>))
      //     .toList();
      return [];
    } catch (e) {
      _error = e.toString();
      return [];
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }
}
