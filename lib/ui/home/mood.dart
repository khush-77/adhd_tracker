import 'package:adhd_tracker/providers.dart/login_provider.dart';
import 'package:adhd_tracker/ui/auth/login.dart';
import 'package:adhd_tracker/ui/home/home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';

import 'package:provider/provider.dart';

class MoodPage extends StatefulWidget {
  @override
  _MoodPageState createState() => _MoodPageState();
}

class _MoodPageState extends State<MoodPage> {
  int? _selectedMood;
  bool _isLoading = false;
  bool _isChecking = true; // New state for initial check

  @override
  void initState() {
     super.initState();
    _checkDailyMoodStatus();
  }



  Future<void> _checkDailyMoodStatus() async {
    setState(() => _isChecking = true);
    
    try {
      final loginProvider = Provider.of<LoginProvider>(context, listen: false);
      final token = loginProvider.token;
      
      if (token == null) {
        final storage = const FlutterSecureStorage();
        final storedToken = await storage.read(key: 'auth_token');
        
        if (storedToken == null) {
          _navigateToLogin();
          return;
        } else {
          loginProvider.setToken(storedToken);
        }
      }

      final today = DateTime.now();
      final dateString = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
      
      final url = Uri.parse(
        'https://freelance-backend-xx6e.onrender.com/api/v1/mood/mood?startDate=$dateString&endDate=$dateString'
      );

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer ${loginProvider.token}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData['success'] == true && 
            responseData['data'] != null && 
            responseData['data'].length > 0) {
          // Mood already recorded for today
          if (mounted) {
            _navigateToHome();
          }
        } else {
          // No mood recorded for today, show mood selection UI
          if (mounted) {
            setState(() => _isChecking = false);
          }
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        // Token expired or invalid
        _navigateToLogin();
      } else {
        throw Exception('Failed to check mood status');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isChecking = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking mood status: ${e.toString()}')),
        );
      }
    }
  }

  void _navigateToLogin() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  void _navigateToHome() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomePage()),
    );
  }
  Future<void> _recordMood() async {
    if (_selectedMood == null) return;

    setState(() {
      _isLoading = true;
    });

    final loginProvider = Provider.of<LoginProvider>(context, listen: false);
    final token = loginProvider.token;

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Authentication error. Please login again.')),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final url = Uri.parse('https://freelance-backend-xx6e.onrender.com/api/v1/mood/addmood');
    final body = jsonEncode({
      'date': DateTime.now().toIso8601String().split('T')[0],
      'mood': _selectedMood!,
    });

    try {
      final response = await http.post(
        url,
        body: body,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        
        

        if (!mounted) return;
        _navigateToHome();
      } else {
        throw Exception('Failed to record mood');
      }
    }catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to record mood: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Color getMoodColor(int mood) {
    switch (mood) {
      case 1:
        return Color(0xFF4CAF50);
      case 2:
        return Color(0xFFFFA726);
      case 3:
        return Color(0xFFE53935);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final fontScale = size.width / 375.0;
    final darkPurple = const Color(0xFF2D2642);

    // Show loading screen while checking mood status
    if (_isChecking) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8D5BFF)),
              ),
              SizedBox(height: 20),
              Text(
                'Checking today\'s mood status...',
                style: GoogleFonts.lato(
                  textStyle: TextStyle(
                    fontSize: 16 * fontScale,
                    color: darkPurple,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final List<Map<String, dynamic>> moods = [
      {"label": "Mild - Can Function", "emoji": "😊", "value": 1},
      {"label": "Moderate - Slowed", "emoji": "😐", "value": 2},
      {"label": "Severe - Cannot Function", "emoji": "😢", "value": 3},
    ];

    // Rest of your existing build method for mood selection UI
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: Text(
          'Record',
          style: GoogleFonts.lato(
            textStyle: TextStyle(
              fontSize: 20 * fontScale,
              fontWeight: FontWeight.bold,
              color: darkPurple,
              letterSpacing: -0.5,
            ),
          ),
        ),
      ),
      backgroundColor: Colors.white,
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(height: 18),
                Text(
                  'How is your mood today?',
                  style: GoogleFonts.lato(
                    textStyle: TextStyle(
                      fontSize: 32 * fontScale,
                      fontWeight: FontWeight.bold,
                      color: darkPurple,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                SizedBox(height: 30),
                Expanded(
                  child: ListView.builder(
                    itemCount: moods.length,
                    itemBuilder: (context, index) {
                      final mood = moods[index];
                      final isSelected = _selectedMood == mood['value'];
                      final moodColor = getMoodColor(mood['value']);

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedMood = isSelected ? null : mood['value'];
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                vertical: 16.0, horizontal: 12.0),
                            decoration: BoxDecoration(
                              color: isSelected ? moodColor : Colors.white,
                              border: Border.all(
                                color: isSelected ? moodColor : Colors.grey.shade300,
                              ),
                              borderRadius: BorderRadius.circular(12.0),
                              boxShadow: [
                                if (isSelected)
                                  BoxShadow(
                                    color: moodColor.withOpacity(0.4),
                                    blurRadius: 10.0,
                                    offset: Offset(0, 4),
                                  ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Text(
                                  mood['emoji'],
                                  style: TextStyle(fontSize: 24.0),
                                ),
                                SizedBox(width: 12.0),
                                Expanded(
                                  child: Text(
                                    mood['label'],
                                    style: TextStyle(
                                      fontSize: 18.0,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? Colors.white
                                          : darkPurple,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (_selectedMood != null)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SafeArea(
                      child: ElevatedButton(
                        onPressed: _recordMood,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: getMoodColor(_selectedMood!),
                          minimumSize: Size(double.infinity, size.height * 0.07),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Confirm',
                          style: TextStyle(
                            fontSize: 18 * fontScale,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}