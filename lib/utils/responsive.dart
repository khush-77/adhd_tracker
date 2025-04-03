// lib/utils/responsive_utils.dart

import 'package:flutter/material.dart';

class Responsive {
  static late MediaQueryData _mediaQueryData;
  static late double screenWidth;
  static late double screenHeight;
  static late double blockSizeHorizontal;
  static late double blockSizeVertical;
  
  static late double _safeAreaHorizontal;
  static late double _safeAreaVertical;
  static late double safeBlockHorizontal;
  static late double safeBlockVertical;
  
  static late double textScaleFactor;
  static late double scaleFactor;
  
  // Default design dimensions (based on iPhone 12 Pro)
  static const double defaultScreenWidth = 390;
  static const double defaultScreenHeight = 844;
  
  void init(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData.size.width;
    screenHeight = _mediaQueryData.size.height;
    blockSizeHorizontal = screenWidth / 100;
    blockSizeVertical = screenHeight / 100;
    
    _safeAreaHorizontal = _mediaQueryData.padding.left + _mediaQueryData.padding.right;
    _safeAreaVertical = _mediaQueryData.padding.top + _mediaQueryData.padding.bottom;
    safeBlockHorizontal = (screenWidth - _safeAreaHorizontal) / 100;
    safeBlockVertical = (screenHeight - _safeAreaVertical) / 100;
    
    // Calculate scale factor based on screen width
    scaleFactor = screenWidth / defaultScreenWidth;
    textScaleFactor = scaleFactor.clamp(0.8, 1.2); // Limit text scaling
  }
  
  // Helper methods for responsive sizes
  static double hp(double percentage) => screenHeight * (percentage / 100);
  static double wp(double percentage) => screenWidth * (percentage / 100);
  
  // Helper methods for text sizes
  static double sp(double size) => size * textScaleFactor;
  
  // Helper methods for margin and padding
  static EdgeInsets symmetric({double? horizontal, double? vertical}) {
    return EdgeInsets.symmetric(
      horizontal: horizontal != null ? wp(horizontal) : 0,
      vertical: vertical != null ? hp(vertical) : 0,
    );
  }
  
  static EdgeInsets all(double value) {
    return EdgeInsets.all(wp(value));
  }
  
  // Helper method for responsive radius
  static double radius(double value) => value * scaleFactor;
  
  // Helper method for responsive icon sizes
  static double iconSize(double value) => value * scaleFactor;
}