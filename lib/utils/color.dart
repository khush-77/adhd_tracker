
import 'package:flutter/material.dart';

class AppTheme {
  // Primary Colors
  static const Color upeiRed = Color(0xFF8B2942);
  static const Color upeiGreen = Color(0xFF2C5234);
  
  // Secondary Colors
  static const Color lightRed = Color(0xFFB84D66);
  static const Color lightGreen = Color(0xFF4A7254);
  
  // Background Colors
  static const Color background = Colors.white;
  static const Color surfaceBackground = Color(0xFFF5F5F5);
  
  // Text Colors
  static const Color primaryText = Color(0xFF2C5234);
  static const Color secondaryText = Color(0xFF666666);
  static const Color disabledText = Color(0xFF999999);
  
  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFFA726);
  static const Color info = Color(0xFF2196F3);
  
  // Border Colors
  static const Color border = Color(0xFFE0E0E0);
  static const Color divider = Color(0xFFEEEEEE);
  
  // Shadow
  static final BoxShadow defaultShadow = BoxShadow(
    color: Colors.black.withOpacity(0.1),
    blurRadius: 20,
    offset: const Offset(0, 10),
  );
  
  // Text Styles
  static const TextStyle headingLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: primaryText,
    fontFamily: 'Yaro',
  );
  
  static const TextStyle headingMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: primaryText,
    fontFamily: 'Yaro',
  );
  
  static const TextStyle headingSmall = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: primaryText,
    fontFamily: 'Yaro',
  );
  
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 18,
    color: secondaryText,
    fontFamily: 'Yaro',
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 16,
    color: secondaryText,
    fontFamily: 'Yaro',
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 14,
    color: secondaryText,
    fontFamily: 'Yaro',
  );
  
  // Button Styles
  static final ButtonStyle primaryButton = ElevatedButton.styleFrom(
    backgroundColor: upeiRed,
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    elevation: 0,
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
  );
  
  static final ButtonStyle secondaryButton = ElevatedButton.styleFrom(
    backgroundColor: Colors.white,
    foregroundColor: upeiRed,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: upeiRed),
    ),
    elevation: 0,
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
  );
  
  // Input Decoration
  static const InputDecorationTheme inputDecorationTheme = InputDecorationTheme(
    filled: true,
    fillColor: surfaceBackground,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide.none,
    ),
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );
  
  // Card Theme
  static final CardTheme cardTheme = CardTheme(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    color: Colors.white,
  );
  
  // Spacing Constants
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;
  
  // Border Radius
  static const double borderRadiusS = 8.0;
  static const double borderRadiusM = 12.0;
  static const double borderRadiusL = 16.0;
  static const double borderRadiusXL = 24.0;
}