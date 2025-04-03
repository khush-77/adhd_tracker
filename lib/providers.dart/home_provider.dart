// health_data_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HealthDataProvider with ChangeNotifier {
  List<dynamic> _symptoms = [];
  List<dynamic> _medications = [];

  List<dynamic> get symptoms => _symptoms;
  List<dynamic> get medications => _medications;
  final FlutterSecureStorage _storage = FlutterSecureStorage();

    Future<void> fetchSymptoms(DateTime date) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) {
        throw Exception('No authentication token found');
      }

      // Format date to only include the date part (YYYY-MM-DD)
      final formattedDate = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      
      print('Fetching symptoms for date: $formattedDate'); // Debug print

      final url = Uri.parse(
          'https://freelance-backend-xx6e.onrender.com/api/v1/symptoms/getsymptoms?startDate=$formattedDate&endDate=$formattedDate');

      print('Request URL: $url'); // Debug print

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Response status code: ${response.statusCode}'); // Debug print
      print('Response body: ${response.body}'); // Debug print

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          _symptoms = responseData['data'];
          print('Updated symptoms: $_symptoms'); // Debug print
          notifyListeners();
        } else {
          _symptoms = [];
          notifyListeners();
        }
      } else {
        throw Exception('Failed to fetch symptoms: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching symptoms: $e'); // Debug print
      rethrow;
    }
  }
  Future<void> fetchMedications(DateTime date) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final formattedDate = date.toIso8601String().split('T')[0];
      final url = Uri.parse(
          'https://freelance-backend-xx6e.onrender.com/api/v1/medication/getmedication?date=$formattedDate');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          _medications = responseData['data'];
          notifyListeners();
        }
      } else {
        throw Exception('Failed to fetch medications');
      }
    } catch (e) {
      rethrow;
    }
  }
}
