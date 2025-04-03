class Validators {
  static bool validateEmail(String email) {
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    return emailRegex.hasMatch(email);
  }

  static bool validatePassword(String password) {
    return password.length >= 8 && 
           password.contains(RegExp(r'[A-Z]')) &&
           password.contains(RegExp(r'[a-z]')) &&
           password.contains(RegExp(r'[0-9]'));
  }

  static bool validateName(String name) {
    return name.trim().length >= 2;
  }

  static bool validateOtp(String otp) {
    return otp.length == 6 && RegExp(r'^\d+$').hasMatch(otp);
  }
}