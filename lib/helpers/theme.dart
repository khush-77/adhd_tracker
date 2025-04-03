import 'package:flutter/material.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeData get currentTheme => _isDarkMode ? darkTheme : lightTheme;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
    void setLightMode() {
    _isDarkMode = false;
    notifyListeners();
  }

  static final lightTheme = ThemeData(
    brightness: Brightness.light,
     scaffoldBackgroundColor: Colors.white, 
     colorScheme: const ColorScheme.light(
      background: Colors.white,  
      surface: Colors.white,    
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      iconTheme: IconThemeData(color: Color(0xFF2D2642)),
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(color: Color(0xFF2D2642)),
      bodyLarge: TextStyle(color: Color(0xFF2D2642)),
      bodyMedium: TextStyle(color: Color(0xFF2D2642)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      fillColor: Colors.grey[200],
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    ),
    iconTheme: const IconThemeData(color: Color(0xFF2D2642)),
  );

  static final darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF121212),
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(color: Colors.white),
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white),
    ),
    inputDecorationTheme: InputDecorationTheme(
      fillColor: Colors.grey[800],
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      hintStyle: const TextStyle(color: Colors.grey),
    ),
    iconTheme: const IconThemeData(color: Colors.white),
  );
}
