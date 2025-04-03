import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class ForgotPasswordProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool _isOtpSent = false;
  bool _isOtpVerified = false;
  String? _errorMessage;
  String? _emailId;
  String? _authToken;

  final _storage = FlutterSecureStorage();

  bool get isLoading => _isLoading;
  bool get isOtpSent => _isOtpSent;
  bool get isOtpVerified => _isOtpVerified;
  String? get errorMessage => _errorMessage;

  // Store OTP for reuse if needed
  String? _lastVerifiedOtp;

  Future<bool> sendPasswordResetOtp(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('https://freelance-backend-xx6e.onrender.com/api/v1/users/forgot-password/otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'emailId': email}),
      );

      _isLoading = false;

      if (response.statusCode == 200) {
        _isOtpSent = true;
        _emailId = email;
        notifyListeners();
        return true;
      } else {
        _errorMessage = _parseErrorMessage(response.body);
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Network error. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyPasswordResetOtp(String email, String otp) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('https://freelance-backend-xx6e.onrender.com/api/v1/users/forgot-password/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'emailId': email,
          'otp': otp
        }),
      );

      _isLoading = false;

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        _authToken = responseBody['data']['accessToken'];
        _lastVerifiedOtp = otp; // Store OTP for potential reuse
        
        // Save token securely
        await _storage.write(key: 'reset_password_token', value: _authToken);

        _isOtpVerified = true;
        notifyListeners();
        return true;
      } else {
        _errorMessage = _parseErrorMessage(response.body);
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Network error. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPassword(String newPassword) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Retrieve the token from secure storage
      String? token = await _storage.read(key: 'reset_password_token');

      // First attempt with existing token
      var success = await _attemptPasswordReset(newPassword, token);
      
      // If failed due to expired token, try to refresh it
      if (!success && _errorMessage?.toLowerCase().contains('expired') == true) {
        // Re-verify OTP to get fresh token
        if (_emailId != null && _lastVerifiedOtp != null) {
          final verifySuccess = await verifyPasswordResetOtp(_emailId!, _lastVerifiedOtp!);
          if (verifySuccess) {
            // Retry password reset with new token
            token = await _storage.read(key: 'reset_password_token');
            success = await _attemptPasswordReset(newPassword, token);
          }
        }
      }

      if (success) {
        // Clear all stored data
        await _storage.delete(key: 'reset_password_token');
        _isOtpSent = false;
        _isOtpVerified = false;
        _emailId = null;
        _authToken = null;
        _lastVerifiedOtp = null;
        notifyListeners();
      }

      return success;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Network error. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> _attemptPasswordReset(String newPassword, String? token) async {
    if (token == null) {
      _errorMessage = 'Session expired. Please try again.';
      return false;
    }

    final response = await http.post(
      Uri.parse('https://freelance-backend-xx6e.onrender.com/api/v1/users/forgot-password/update-password'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      },
      body: jsonEncode({'newPassword': newPassword}),
    );

    _isLoading = false;

    if (response.statusCode == 200) {
      return true;
    } else {
      _errorMessage = _parseErrorMessage(response.body);
      notifyListeners();
      return false;
    }
  }

  String _parseErrorMessage(String responseBody) {
    try {
      final Map<String, dynamic> body = json.decode(responseBody);
      return body['message'] ?? 'An unknown error occurred';
    } catch (e) {
      return 'An unknown error occurred';
    }
  }
}