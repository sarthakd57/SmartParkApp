import 'package:flutter/material.dart';

import '../models/subscription.dart';
import '../services/api_client.dart';

class SubscriptionProvider extends ChangeNotifier {
  final ApiClient _apiClient;

  List<Subscription> _subscriptions = [];
  bool _loading = false;
  String? _error;

  List<Subscription> get subscriptions => _subscriptions;
  bool get isLoading => _loading;
  String? get error => _error;

  SubscriptionProvider(this._apiClient);

  // Get only active subscriptions
  List<Subscription> get activeSubscriptions =>
      _subscriptions.where((s) => s.isActive && !s.isExpired).toList();

  // Get subscriptions that need renewal soon
  List<Subscription> get renewalDueSubscriptions =>
      _subscriptions.where((s) => s.isRenewalDue && !s.isExpired).toList();

  Future<void> fetchUserSubscriptions(String userId) async {
    _setLoading(true);
    _error = null;
    try {
      // TODO: Implement API endpoint
      // final response = await _apiClient.get('/subscriptions/user/$userId');
      // _subscriptions = (response as List<dynamic>)
      //     .map((json) => Subscription.fromJson(json as Map<String, dynamic>))
      //     .toList();
      _subscriptions = [];
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> renewSubscription(String subscriptionId) async {
    _setLoading(true);
    _error = null;
    try {
      // TODO: Implement API endpoint
      // await _apiClient.post('/subscriptions/$subscriptionId/renew', {});
      // Refresh subscriptions
      await fetchUserSubscriptions(''); // Pass actual userId
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> cancelSubscription(String subscriptionId) async {
    _setLoading(true);
    _error = null;
    try {
      // TODO: Implement API endpoint
      // await _apiClient.delete('/subscriptions/$subscriptionId');
      _subscriptions.removeWhere((s) => s.id == subscriptionId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> purchaseSubscription({
    required String lotId,
    required String vehicleSize,
    required String subscriptionType,
  }) async {
    _setLoading(true);
    _error = null;
    try {
      // TODO: Implement API endpoint
      // final response = await _apiClient.post('/subscriptions/purchase', {
      //   'lot_id': lotId,
      //   'vehicle_size': vehicleSize,
      //   'subscription_type': subscriptionType,
      // });
      // final subscription = Subscription.fromJson(response as Map<String, dynamic>);
      // _subscriptions.add(subscription);
      // notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }
}
