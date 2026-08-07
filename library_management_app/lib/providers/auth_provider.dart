import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _user;
  String? _token;

  // Getters required by main.dart and home_screen.dart
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get user => _user;
  bool get isAuthenticated => _token != null || _user != null;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.post('/auth/login', {
        'email': email,
        'password': password,
      });

      if (response.headers['content-type']?.contains('text/html') ?? false) {
        _errorMessage =
            'Server returned HTML (404/Route Not Found). Check backend route.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 &&
          (data['success'] == true || data['token'] != null)) {
        _token = data['token'];
        _user = data['user'] ?? {'email': email};

        if (_token != null) {
          await ApiService.saveToken(_token!);
        }

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage =
            data['message'] ?? 'Login failed. Please check credentials.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('Login Error: $e');
      _errorMessage =
          'Connection failed. Make sure server is running on port 10000.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Logout method required by home_screen.dart
  Future<void> logout() async {
    _token = null;
    _user = null;
    await ApiService.clearToken();
    notifyListeners();
  }
}
