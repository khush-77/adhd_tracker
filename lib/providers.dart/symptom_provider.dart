import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import 'package:provider/provider.dart';

// First, let's create the SymptomProvider
class SymptomProvider extends ChangeNotifier {
  final _storage = FlutterSecureStorage();
   String? date;
  Map<String, bool> _symptomSelection = {};
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;
   bool isInitialized = false;
  Map<String, bool> symptomSelection = {};
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool hasSubmittedSymptoms = false;

  
   void initializeWithPredefinedSymptoms(List<String> predefinedSymptoms) {
    // Clear existing symptoms
    symptomSelection.clear();
    
    // Add all predefined symptoms with default value of false (not selected)
    for (final symptom in predefinedSymptoms) {
      symptomSelection[symptom] = false;
    }
    
    isInitialized = true;
    notifyListeners();
  }
  
  // Add a custom symptom
  void addCustomSymptom(String symptom) {
    if (!symptomSelection.containsKey(symptom)) {
      symptomSelection[symptom] = true; // Set to true by default since the user just added it
      notifyListeners();
    }
  }
  
  // Update symptom selection
  void updateSymptomSelection(String symptom, bool isSelected) {
    symptomSelection[symptom] = isSelected;
    notifyListeners();
  }

  Future<void> fetchSymptoms() async {
    if (_isInitialized) return;
    
    _isLoading = true;
    _error = null;
    
    try {
      final token = await _storage.read(key: 'auth_token');
      final response = await http.get(
        Uri.parse('https://freelance-backend-xx6e.onrender.com/api/v1/users/getuserdetails'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final List<String> symptoms =
              List<String>.from(jsonResponse['data']['symptoms'] ?? []);
          _symptomSelection = Map.fromIterable(
            symptoms,
            key: (item) => item.toString(),
            value: (_) => false,
          );
        } else {
          _error = jsonResponse['message'] ?? 'Failed to load symptoms';
        }
      } else {
        _error = 'Failed to load symptoms';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }
  }
void resetSymptomSelections() {
    // Keep the same symptom keys but set all values to false
    symptomSelection.updateAll((key, value) => false);
    notifyListeners();
  }
  
  // Update the date and reset symptom selections
  // void updateDate(String date) {
  //   selectedDate = date;
  //   notifyListeners();
  // }
  void updateDate(String value) {
    date = value.trim();
    notifyListeners();
  }
  void clearSymptomSelections() {
  // Create a new map with all symptoms set to false
  final Map<String, bool> clearedSelections = {};
  for (var symptom in symptomSelection.keys) {
    clearedSelections[symptom] = false;
  }
  symptomSelection = clearedSelections;
  notifyListeners();
}

  Future<bool> logSymptoms({
    required List<String> symptoms,
    required String severity,
    required String timeOfDay,
    required String notes,
  }) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      final response = await http.post(
        Uri.parse('https://freelance-backend-xx6e.onrender.com/api/v1/symptoms/addsymptoms'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'symptoms': symptoms,
          'date': date,
          'severity': severity,
          'timeOfDay': timeOfDay,
          'notes': notes,
        }),
      );
hasSubmittedSymptoms = true;
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}