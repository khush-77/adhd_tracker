import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'dart:convert';
import 'package:intl/intl.dart';

class MoodStatsProvider extends ChangeNotifier {
  String _selectedRange = 'week';
  late String _selectedMonth;

  MoodStatsProvider() {
    _selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());
  }
  
  String get selectedRange => _selectedRange;
  String get selectedMonth => _selectedMonth;
    
  final FlutterSecureStorage _storage = FlutterSecureStorage();
  
  void setRange(String range) {
    _selectedRange = range;
    if (range == 'custom') {
      fetchMoodData(range: 'custom', customDate: _selectedMonth);
    } else {
      fetchMoodData(range: range);
    }
  }

  void setMonth(String month) {
    _selectedMonth = month;
    fetchMoodData(range: 'custom', customDate: month);
  }
  
  final Map<int, String> moodEmojis = {
    1: "😊",
    2: "😐",
    3: "😢",
  };

  Map<String, List<double>> _moodsByDay = {};
  Map<int, int> _moodTotals = {};
  bool isLoading = true;
  String? error;

  Map<String, List<double>> get moodsByDay => _moodsByDay;
  Map<int, int> get moodTotals => _moodTotals;
  
  Future<void> fetchMoodData({String? range, String? customDate}) async {
    // Use provided range or keep existing range
    if (range != null) {
      _selectedRange = range;
    }
    
    // Update selected month if custom date provided
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
          'https://freelance-backend-xx6e.onrender.com/api/v1/mood/mood'
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
          _processMoodData(data['data'], dateRange['startDate']!, dateRange['endDate']!);
          error = null;
        } else {
          error = data['message'] ?? 'Failed to process mood data';
        }
      } else {
        error = 'Failed to load mood data: ${response.statusCode}';
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
          // Get the last day of the selected month
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

  void _processMoodData(List<dynamic> moods, String startDate, String endDate) {
    Map<String, List<double>> moodsByDay = {};
    Map<int, int> totals = {};

    // Initialize date range
    DateTime start = DateTime.parse(startDate);
    DateTime end = DateTime.parse(endDate);
    
    // Initialize all dates in the range
    for (DateTime date = start; 
         !date.isAfter(end); 
         date = date.add(const Duration(days: 1))) {
      String dateStr = DateFormat('yyyy-MM-dd').format(date);
      moodsByDay[dateStr] = [];
    }

    // Process mood data
    for (var mood in moods) {
      String date = DateFormat('yyyy-MM-dd')
          .format(DateTime.parse(mood['date']).toLocal());
      int moodValue = mood['mood'];
      
      moodsByDay[date]?.add(moodValue.toDouble());
      totals[moodValue] = (totals[moodValue] ?? 0) + 1;
    }

    _moodsByDay = moodsByDay;
    _moodTotals = totals;
  }

  double? getAverageMoodForDate(String date) {
    final moods = _moodsByDay[date];
    if (moods == null || moods.isEmpty) return null;
    return moods.reduce((a, b) => a + b) / moods.length;
  }
}