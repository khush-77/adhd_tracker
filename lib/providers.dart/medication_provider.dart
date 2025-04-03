// medication_provider.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../ui/home/home.dart';

class MedicationProvider with ChangeNotifier {
  String? medicationName;
  String? dosage;
  String? timeOfTheDay;
  String? date;
  List<String> effects = [];
  bool isLoading = false;
  String error = '';
  String? successMessage;
  
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  void updateMedicationName(String value) {
    medicationName = value.trim();
    notifyListeners();
  }

  void updateDosage(String value) {
    dosage = value.trim();
    notifyListeners();
  }

  void updateTimeOfDay(String value) {
    timeOfTheDay = value.trim();
    notifyListeners();
  }

  void updateDate(String value) {
    date = value.trim();
    notifyListeners();
  }

  void updateEffects(String value) {
    // Handle empty string case
    if (value.trim().isEmpty) {
      effects = [];
    } else {
      effects = value
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    notifyListeners();
  }

  Future<bool> submitMedication(BuildContext context) async {
    try {
      // Validate all required fields
      if (medicationName?.isEmpty ?? true) {
        error = 'Please fill in all required fields';
        notifyListeners();
        return false;
      }

      isLoading = true;
      notifyListeners();

      final token = await _storage.read(key: 'auth_token');
      if (token == null) {
        error = 'Authentication token not found';
        isLoading = false;
        notifyListeners();
        return false;
      }

      // Ensure all fields are non-null in the request body
      final requestBody = {
        'medicationName': medicationName ?? '',
        'date': date ?? '',
        'dosage': dosage ?? '',
        'timeOfTheDay': timeOfTheDay ?? '',
        'effects':
            effects.isEmpty ? [''] : effects, // Ensure effects is never null
      };

      final response = await http.post(
        Uri.parse(
            'https://freelance-backend-xx6e.onrender.com/api/v1/medication/addmedication'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = json.decode(response.body);
        successMessage =
            responseData['message'] ?? 'Medication added successfully';

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(successMessage!),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );

          // Delay navigation to allow snackbar to be visible
          Future.delayed(const Duration(seconds: 2), () {
            if (context.mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        HomePage()), // Remove PageRouteBuilder
              );
            }
          });
        }

        clearForm();
        return true;
      } else {
        final errorData = json.decode(response.body);
        error = errorData['message'] ??
            errorData['error'] ??
            'Failed to submit medication';
        notifyListeners();
        return false;
      }
    } catch (e) {
      error = 'Network error: ${e.toString()}';
      notifyListeners();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void clearForm() {
    medicationName = null;
    dosage = null;
    timeOfTheDay = null;
    date = null;
    effects = [];
    error = '';
    successMessage = null;
    notifyListeners();
  }
}
