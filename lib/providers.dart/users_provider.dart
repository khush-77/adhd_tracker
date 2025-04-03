import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:adhd_tracker/models/user_model.dart';

class UserProvider extends ChangeNotifier {
  ProfileData? _profileData;
  bool _isLoading = false;
  String? _error;

  ProfileData? get profileData => _profileData;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  final FlutterSecureStorage _storage = FlutterSecureStorage();
  final _client = http.Client();
  
  static const String _baseUrl = 'https://freelance-backend-xx6e.onrender.com/api/v1';
  static const Duration _timeout = Duration(seconds: 30);

  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _storage.read(key: 'auth_token');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<void> fetchProfileData() async {
    if (_isLoading) return;
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final headers = await _getAuthHeaders();
      final response = await _client
          .get(
            Uri.parse('$_baseUrl/users/getuserdetails'),
            headers: headers,
          )
          .timeout(_timeout);

      final jsonResponse = json.decode(response.body);
      
      if (response.statusCode == 200 && jsonResponse['success'] == true) {
        _profileData = ProfileData.fromJson(jsonResponse['data']);
        _error = null;
      } else {
        _error = jsonResponse['message'] ?? 'Failed to fetch profile data';
        _profileData = null;
      }
    } catch (e) {
      _error = 'Failed to load profile data. Please try again.';
      _profileData = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateMedications(List<String> medications) async {
    return _updateData(
      endpoint: '/users/updatemedication',
      data: {'medication': medications},
      successMessage: 'Medications updated successfully',
    );
  }

  Future<bool> updateSymptoms(List<String> symptoms) async {
    return _updateData(
      endpoint: '/users/updatesymptoms',
      data: {'symptoms': symptoms},
      successMessage: 'Symptoms updated successfully',
    );
  }

  Future<bool> updateStrategies(List<String> strategies) async {
    return _updateData(
      endpoint: '/users/updatestrategies',
      data: {'strategies': strategies},
      successMessage: 'Strategies updated successfully',
    );
  }

  Future<bool> _updateData({
    required String endpoint,
    required Map<String, dynamic> data,
    required String successMessage,
  }) async {
    if (_isLoading) return false;
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final headers = await _getAuthHeaders();
      final response = await _client
          .post(
            Uri.parse('$_baseUrl$endpoint'),
            headers: headers,
            body: json.encode(data),
          )
          .timeout(_timeout);

      final jsonResponse = json.decode(response.body);
      
      if (response.statusCode == 200 && jsonResponse['success'] == true) {
        await fetchProfileData(); // Refresh profile data after successful update
        return true;
      }
      
      _error = jsonResponse['message'] ?? 'Update failed';
      return false;
    } catch (e) {
      _error = 'Failed to update. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }
}