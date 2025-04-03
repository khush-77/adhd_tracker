import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';
import 'package:http/http.dart' as http;

class SignUpProvider with ChangeNotifier {
  bool _isLoading = false;
  bool _isOtpSent = false;
  bool _isOtpVerified = false;
  String? _errorMessage;
  bool _disposed = false;
  
  bool get isLoading => _isLoading;
  bool get isOtpSent => _isOtpSent;
  bool get isOtpVerified => _isOtpVerified;
  String? get errorMessage => _errorMessage;
  
  final FlutterSecureStorage _storage = FlutterSecureStorage();

  // Override dispose to mark the provider as disposed
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  // Safe way to call notifyListeners
  void _notifyListeners() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  Future<bool> sendSignUpRequest(String name, String email, String password) async {
    if (!Validators.validateName(name)) {
      _errorMessage = 'Name must be at least 2 characters';
      _notifyListeners();
      return false;
    }
    if (!Validators.validateEmail(email)) {
      _errorMessage = 'Invalid email format';
      _notifyListeners();
      return false;
    }
    if (!Validators.validatePassword(password)) {
      _errorMessage = 'Password must be 8+ chars, with uppercase, lowercase & number';
      _notifyListeners();
      return false;
    }
    
    _isLoading = true;
    _errorMessage = null;
    _notifyListeners();
    
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.registerEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'emailId': email,
          'password': password,
        }),
      ).timeout(
        Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Request timed out'),
      );

      if (_disposed) return false; // Check if disposed before updating state
      
      _isLoading = false;
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseBody = json.decode(response.body);
        final token = responseBody['data']['token'];
        await _storage.write(key: 'auth_token', value: token);
        debugPrint('sign up ka hai token: ' + token);
        
        return await sendOtp();
      } else {
        _errorMessage = 'Registration failed: ${response.body}';
        _notifyListeners();
        return false;
      }
    } catch (e) {
      if (_disposed) return false; // Check if disposed before updating state
      
      _errorMessage = 'Unexpected error: ${e.toString()}';
      _isLoading = false;
      _notifyListeners();
      return false;
    }
  }

  Future<bool> sendOtp() async {
    if (_disposed) return false;
    
    _isLoading = true;
    _errorMessage = null;
    _notifyListeners();
    
    try {
      final token = await _storage.read(key: 'auth_token');
      final response = await http.post(
        Uri.parse(ApiConstants.sendOtpEndpoint),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(
        Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('OTP send timed out'),
      );

      if (_disposed) return false; // Check if disposed before updating state
      
      _isLoading = false;
      
      if (response.statusCode == 200) {
        _isOtpSent = true;
        _notifyListeners();
        return true;
      } else {
        _errorMessage = 'Failed to send OTP';
        _notifyListeners();
        return false;
      }
    } catch (e) {
      if (_disposed) return false; // Check if disposed before updating state
      
      _errorMessage = 'Unexpected error: ${e.toString()}';
      _isLoading = false;
      _notifyListeners();
      return false;
    }
  }

  Future<bool> verifyOtp(String otp) async {
    if (!Validators.validateOtp(otp)) {
      _errorMessage = 'Invalid OTP format';
      _notifyListeners();
      return false;
    }
    
    _isLoading = true;
    _errorMessage = null;
    _notifyListeners();
    
    try {
      final token = await _storage.read(key: 'auth_token');
      final response = await http.post(
        Uri.parse(ApiConstants.verifyOtpEndpoint),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'otp': otp}),
      ).timeout(
        Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('OTP verification timed out'),
      );

      if (_disposed) return false; // Check if disposed before updating state
      
      _isLoading = false;
      
      if (response.statusCode == 200) {
        _isOtpVerified = true;
        _notifyListeners();
        return true;
      } else {
        _errorMessage = 'Invalid OTP';
        _notifyListeners();
        return false;
      }
    } catch (e) {
      if (_disposed) return false; // Check if disposed before updating state
      
      _errorMessage = 'Unexpected error: ${e.toString()}';
      _isLoading = false;
      _notifyListeners();
      return false;
    }
  }
}