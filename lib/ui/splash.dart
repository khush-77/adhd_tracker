import 'dart:convert';

import 'package:adhd_tracker/ui/auth/create_profile.dart';
import 'package:flutter/material.dart';
import 'package:adhd_tracker/helpers/notification.dart';
import 'package:adhd_tracker/utils/color.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:adhd_tracker/providers.dart/login_provider.dart';
import 'package:adhd_tracker/ui/auth/login.dart';
import 'package:adhd_tracker/ui/home/mood.dart';
import 'package:adhd_tracker/ui/home/home.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;

  bool isFirstTime = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.7, curve: Curves.elasticOut),
      ),
    );

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
    _initializeApp();
  }

 Future<void> _initializeApp() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final loginProvider = Provider.of<LoginProvider>(context, listen: false);
    final storage = const FlutterSecureStorage();
    
    if (!mounted) return;
    
    setState(() {
      isFirstTime = prefs.getBool('is_first_time') ?? true;
    });

    // First time users should stay on splash screen
    if (isFirstTime) {
      return;
    }

    // Wait for animation to complete
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;

    // Check if user is authenticated
    final String? authToken = await storage.read(key: 'auth_token');
    if (authToken == null) {
      _navigateToPage(const LoginPage());
      return;
    }

    // Update login provider with token
    loginProvider.setToken(authToken);

    // Validate token
    final bool isValidToken = await _validateToken(authToken);
    if (!isValidToken) {
      await storage.delete(key: 'auth_token');
      _navigateToPage(const LoginPage());
      return;
    }

    // Check if profile is completed
    final bool isProfileCompleted = await _checkProfileCompletion(authToken);
    if (!isProfileCompleted) {
      _navigateToPage(const ProfileCreationPage());
      return;
    }

    // Profile is complete, check if mood is recorded for today
    final bool hasMoodRecorded = await _checkTodaysMoodStatus(authToken);
    if (hasMoodRecorded) {
      _navigateToPage(HomePage());
    } else {
      _navigateToPage(MoodPage());
    }
  } catch (e) {
    debugPrint('Error in _initializeApp: $e');
    if (mounted) {
      _navigateToPage(const LoginPage());
    }
  }
}

Future<bool> _validateToken(String token) async {
  try {
    final response = await http.get(
      Uri.parse('https://freelance-backend-xx6e.onrender.com/api/v1/users/getuserdetails'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    
    return response.statusCode == 200;
  } catch (e) {
    debugPrint('Error validating token: $e');
    return false;
  }
}

Future<bool> _checkProfileCompletion(String token) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final cachedCompletion = prefs.getBool('has_completed_profile') ?? false;
    
    if (cachedCompletion) {
      return true;
    }
    
    final response = await http.get(
      Uri.parse('https://freelance-backend-xx6e.onrender.com/api/v1/users/getuserdetails'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body)['data'];
      final isComplete = data['isProfilePictureSet'] && 
                         data['addMedication'] && 
                         data['addSymptoms'] && 
                         data['addStrategies'];
      
      // Cache the result to avoid unnecessary API calls
      if (isComplete) {
        await prefs.setBool('has_completed_profile', true);
      }
      
      return isComplete;
    }
    return false;
  } catch (e) {
    debugPrint('Error checking profile completion: $e');
    return false;
  }
}

Future<bool> _checkTodaysMoodStatus(String token) async {
  try {
    final today = DateTime.now();
    final dateString = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
    
    final url = Uri.parse(
      'https://freelance-backend-xx6e.onrender.com/api/v1/mood/mood?startDate=$dateString&endDate=$dateString'
    );
    
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      return responseData['success'] == true && 
             responseData['data'] != null && 
             responseData['data'].length > 0;
    }
    return false;
  } catch (e) {
    debugPrint('Error checking mood status: $e');
    return false;
  }
}

  Future<void> _handleGetStarted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_first_time', false);

    // Request notification permissions when user clicks "Get Started"
    if (mounted) {
      await NotificationService.requestPermission(context);
    }

    if (!mounted) return;
    _navigateToPage(const LoginPage());
  }

  void _navigateToPage(Widget page) {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final logoSize = size.width * 0.30;
    final fontScale = size.width / 375.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: size.width * 0.06),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Update the logo container part in the build method:

                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: ScaleTransition(
                            scale: _scaleAnimation,
                            child: Container(
                              width: logoSize,
                              height: logoSize,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                // Add ClipOval to ensure circular clipping
                                child: Container(
                                  padding: EdgeInsets.all(logoSize *
                                      0.15), // Increase padding for better containment
                                  child: Image.asset(
                                    'assets/images/logo.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: size.height * 0.05),
                        Transform.translate(
                          offset: Offset(0, _slideAnimation.value),
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: Column(
                              children: [
                                Text(
                                  'ADHD Tracker',
                                  style: TextStyle(
                                    fontFamily: 'Yaro',
                                    fontSize: 44 * fontScale,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.upeiRed,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                SizedBox(height: size.height * 0.02),
                                Text(
                                  'Your personal ADHD companion\nPowered by UPEI',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Yaro',
                                    fontSize: 20 * fontScale,
                                    color: AppTheme.upeiGreen.withOpacity(0.8),
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (isFirstTime)
                  Transform.translate(
                    offset: Offset(0, _slideAnimation.value),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: size.height * 0.02,
                          horizontal: size.width * 0.06,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(32),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 20,
                              offset: const Offset(0, -5),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _handleGetStarted,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.upeiRed,
                            minimumSize:
                                Size(double.infinity, size.height * 0.07),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Get Started',
                            style: TextStyle(
                              fontSize: 18 * fontScale,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
