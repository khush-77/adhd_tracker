import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../providers.dart/profile_services.dart';

class ProfileProvider extends ChangeNotifier {
  final ProfileService _service = ProfileService();
  final FlutterSecureStorage _storage = FlutterSecureStorage();
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;

  // Initialize the provider
  Future<void> init() async {
    if (_isInitialized) return;
    
    try {
      // Load any necessary initial data
      await _loadStoredData();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      _error = 'Initialization failed: ${e.toString()}';
      notifyListeners();
    }
  }

  // Load stored data from secure storage
  Future<void> _loadStoredData() async {
    try {
      // Load any necessary data from storage
      await isProfileComplete();
    } catch (e) {
      _error = 'Failed to load stored data: ${e.toString()}';
      notifyListeners();
    }
  }

  // Reset provider state
  void reset() {
    _isLoading = false;
    _error = null;
    _isInitialized = false;
    notifyListeners();
  }

  // Check if profile setup was completed
  Future<bool> isProfileComplete() async {
    final completed = await _storage.read(key: 'profile_completed');
    return completed == 'true';
  }

  Future<bool> uploadProfilePicture(String base64Image) async {
    if (!_isInitialized) await init();
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _service.uploadProfilePicture(base64Image);
      if (result) {
        await _storage.write(key: 'profile_picture_uploaded', value: 'true');
      }
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<String?> convertImageToBase64(File imageFile) async {
    if (!_isInitialized) await init();
    
    try {
      return await ProfileService.convertImageToBase64(imageFile);
    } catch (e) {
      _error = 'Failed to process image: ${e.toString()}';
      notifyListeners();
      return null;
    }
  }

  Future<bool> addMedications(List<String> medications) async {
    if (!_isInitialized) await init();
    
    final result = await _handleRequest(() => _service.addMedications(medications));
    if (result) {
      await _storage.write(key: 'medications_added', value: 'true');
    }
    return result;
  }

  Future<bool> addSymptoms(List<String> symptoms) async {
    if (!_isInitialized) await init();
    
    final result = await _handleRequest(() => _service.addSymptoms(symptoms));
    if (result) {
      await _storage.write(key: 'symptoms_added', value: 'true');
    }
    return result;
  }

  Future<bool> addStrategy(String strategy) async {
    if (!_isInitialized) await init();
    
    final result = await _handleRequest(() => _service.addStrategy(strategy));
    if (result) {
      await _storage.write(key: 'strategy_added', value: 'true');
      await _storage.write(key: 'profile_completed', value: 'true');
    }
    return result;
  }

  Future<bool> _handleRequest(Future<bool> Function() request) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await request();
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> clearProfileStatus() async {
    _isInitialized = false;
    await _storage.delete(key: 'profile_completed');
    await _storage.delete(key: 'profile_picture_uploaded');
    await _storage.delete(key: 'medications_added');
    await _storage.delete(key: 'symptoms_added');
    await _storage.delete(key: 'strategy_added');
    notifyListeners();
  }

  @override
  void dispose() {
    _isInitialized = false;
    super.dispose();
  }
}