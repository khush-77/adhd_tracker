import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class SeverityStatsProvider extends ChangeNotifier {
  String _selectedRange = 'week';
  late String _selectedMonth;

  SeverityStatsProvider() {
    _selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());
  }

  String get selectedRange => _selectedRange;
  String get selectedMonth => _selectedMonth;

  final FlutterSecureStorage _storage = FlutterSecureStorage();

  // Map severity strings to numeric values for charting
  final Map<String, int> severityValues = {
    'Not at all': 1,
    'Mild': 2,
    'Moderate': 3,
    'Severe': 4,
  };

  Map<String, List<double>> _severityByDay = {};
  Map<String, int> _severityTotals = {};
  bool isLoading = true;
  String? error;

  Map<String, List<double>> get severityByDay => _severityByDay;
  Map<String, int> get severityTotals => _severityTotals;

  void setRange(String range) {
    _selectedRange = range;
    if (range == 'custom') {
      fetchSeverityData(range: 'custom', customDate: _selectedMonth);
    } else {
      fetchSeverityData(range: range);
    }
  }

  void setMonth(String month) {
    _selectedMonth = month;
    fetchSeverityData(range: 'custom', customDate: month);
  }

  Future<void> fetchSeverityData({String? range, String? customDate}) async {
    if (range != null) {
      _selectedRange = range;
    }
    if (customDate != null) {
      _selectedMonth = customDate;
    }

    final token = await _storage.read(key: 'auth_token');
    if (token == null) {
      error = 'Authentication token not provided';
      isLoading = false;
      notifyListeners();
      return;
    }

    try {
      isLoading = true;
      notifyListeners();

      final dateRange = _getDateRange(_selectedRange, _selectedMonth);
      final response = await http.get(
        Uri.parse(
          'https://freelance-backend-xx6e.onrender.com/api/v1/symptoms/getsymptoms'
          '?startDate=${dateRange['startDate']}'
          '&endDate=${dateRange['endDate']}'
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          _processSeverityData(data['data'], dateRange['startDate']!, dateRange['endDate']!);
          error = null;
        } else {
          error = data['message'] ?? 'Failed to process severity data';
        }
      } else {
        error = 'Failed to load severity data: ${response.statusCode}';
      }
    } catch (e) {
      error = 'Error: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Map<String, String> _getDateRange(String range, [String? customDate]) {
    final DateTime now = DateTime.now();
    late DateTime startDate;
    late DateTime endDate;
    
    switch (range) {
      case 'week':
        startDate = now.subtract(const Duration(days: 6));
        endDate = now;
        break;
      case 'month':
        startDate = DateTime(now.year, now.month, 1);
        endDate = now;
        break;
      case 'custom':
        if (customDate != null) {
          final date = DateTime.parse('$customDate-01');
          startDate = date;
          endDate = DateTime(date.year, date.month + 1, 0);
        } else {
          startDate = DateTime(now.year, now.month, 1);
          endDate = now;
        }
        break;
      default:
        startDate = now.subtract(const Duration(days: 6));
        endDate = now;
    }

    return {
      'startDate': DateFormat('yyyy-MM-dd').format(startDate),
      'endDate': DateFormat('yyyy-MM-dd').format(endDate),
    };
  }

  void _processSeverityData(List<dynamic> symptoms, String startDate, String endDate) {
    Map<String, List<double>> severityByDay = {};
    Map<String, int> totals = {};

    // Initialize date range
    DateTime start = DateTime.parse(startDate);
    DateTime end = DateTime.parse(endDate);
    
    // Initialize all dates in the range
    for (DateTime date = start; 
         !date.isAfter(end); 
         date = date.add(const Duration(days: 1))) {
      String dateStr = DateFormat('yyyy-MM-dd').format(date);
      severityByDay[dateStr] = [];
    }

    // Process severity data
    for (var symptom in symptoms) {
      String date = DateFormat('yyyy-MM-dd')
          .format(DateTime.parse(symptom['date']).toLocal());
      String severityStr = symptom['severity'];
      int severityValue = severityValues[severityStr] ?? 0;
      
      if (severityValue > 0) {
        severityByDay[date]?.add(severityValue.toDouble());
        totals[severityStr] = (totals[severityStr] ?? 0) + 1;
      }
    }

    _severityByDay = severityByDay;
    _severityTotals = totals;
  }
}