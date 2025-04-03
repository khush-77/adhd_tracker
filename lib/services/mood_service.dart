import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:adhd_tracker/models/representation/mood_model.dart';

class MoodService {
    final FlutterSecureStorage _storage = FlutterSecureStorage();

  bool _disposed = false;

  void dispose() {
    _disposed = true;
  }
  final String baseUrl = 'https://freelance-backend-xx6e.onrender.com/api/v1';

  Future<List<MoodEntry>> fetchMoodData({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (_disposed) return [];

    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) throw ApiException('Authentication token not found');

      final response = await http.get(
        Uri.parse(
          '${ApiConstants.baseUrl}/mood/mood?startDate=${startDate.toIso8601String()}&endDate=${endDate.toIso8601String()}',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(
        Duration(seconds: ApiConstants.timeoutDuration),
        onTimeout: () => throw TimeoutException('Request timed out'),
      );

      if (_disposed) return [];

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          return (jsonResponse['data'] as List)
              .map((item) => MoodEntry.fromJson(item))
              .toList();
        }
        throw ApiException('Invalid data format', statusCode: response.statusCode);
      } else if (response.statusCode == 401) {
        throw ApiException('Unauthorized access', statusCode: response.statusCode);
      } else if (response.statusCode == 403) {
        throw ApiException('Access forbidden', statusCode: response.statusCode);
      } else {
        throw ApiException(
          'Failed to load mood data',
          statusCode: response.statusCode,
        );
      }
    } on TimeoutException {
      throw ApiException('Request timed out');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Unexpected error: $e');
    }
  }

}

class ApiConstants {
  static const String baseUrl = 'https://freelance-backend-xx6e.onrender.com/api/v1';
  static const int timeoutDuration = 15; // seconds
}

// api_exception.dart
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}