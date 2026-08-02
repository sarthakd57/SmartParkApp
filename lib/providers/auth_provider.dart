import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/api_client.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._apiClient);

  final ApiClient _apiClient;

  UserModel? _user;
  String? _token;
  bool _loading = false;

  UserModel? get user => _user;
  String? get token => _token;
  bool get isLoading => _loading;
  bool get isLoggedIn => _token != null && _user != null;

  Future<void> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    String? vehicleNumber,
  }) async {
    _setLoading(true);
    try {
      final result = await _apiClient.post(
        '/api/auth/register',
        body: {
          'name': name,
          'email': email,
          'password': password,
          'phone': phone,
          'vehicle_number': vehicleNumber,
        },
      );

      _token = result['token'] as String?;
      if (_token != null) {
        _apiClient.token = _token;
      }
      final userJson = result['user'] as Map<String, dynamic>?;
      if (userJson != null) {
        _user = UserModel.fromJson(userJson);
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    try {
      final result = await _apiClient.post(
        '/api/auth/login',
        body: {
          'email': email,
          'password': password,
        },
      );

      _token = result['token'] as String?;
      if (_token != null) {
        _apiClient.token = _token;
      }
      final userJson = result['user'] as Map<String, dynamic>?;
      if (userJson != null) {
        _user = UserModel.fromJson(userJson);
      }
    } finally {
      _setLoading(false);
    }
  }

  void logout() {
    _user = null;
    _token = null;
    _apiClient.token = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }
}

