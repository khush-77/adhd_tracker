import 'package:flutter/material.dart';

class ApiConstants {
  static const baseUrl = 'https://freelance-backend-xx6e.onrender.com/api/v1';
  static const registerEndpoint = '$baseUrl/users/register';
  static const sendOtpEndpoint = '$baseUrl/users/sendotp';
  static const verifyOtpEndpoint = '$baseUrl/users/verifyotp';
}