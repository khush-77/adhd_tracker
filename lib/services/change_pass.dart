import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:adhd_tracker/utils/color.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  _ChangePasswordPageState createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscureOldPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showErrorSnackBar('Passwords do not match');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('https://freelance-backend-xx6e.onrender.com/api/v1/users/changepassword'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'currentPassword': _oldPasswordController.text,
          'newPassword': _newPasswordController.text,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Password changed successfully'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        Navigator.pop(context);
      } else {
        final responseData = jsonDecode(response.body);
        String errorMessage = responseData['message'] ?? 'Failed to change password';
        
        if (response.statusCode == 401) {
          errorMessage = 'Current password is incorrect';
        } else if (response.statusCode == 400) {
          errorMessage = 'Invalid password format';
        }

        _showErrorSnackBar(errorMessage);
      }
    } catch (e) {
      _showErrorSnackBar('Network error occurred. Please try again.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String? _getPasswordValidationMessage(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    return null;
  }

  InputDecoration _getInputDecoration({
    required String labelText,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    String? helperText,
  }) {
    return InputDecoration(
      labelText: labelText,
      helperText: helperText,
      helperMaxLines: 2,
      helperStyle: TextStyle(
        color: Theme.of(context).textTheme.bodySmall?.color,
      ),
      border: OutlineInputBorder(
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      labelStyle: TextStyle(
        color: Theme.of(context).textTheme.bodyLarge?.color,
      ),
      suffixIcon: IconButton(
        icon: Icon(
          obscureText ? Icons.visibility_off : Icons.visibility,
          color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
        ),
        onPressed: onToggleVisibility,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        title: Text(
          'Change Password',
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        iconTheme: IconThemeData(
          color: Theme.of(context).iconTheme.color,
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _oldPasswordController,
                            obscureText: _obscureOldPassword,
                            decoration: _getInputDecoration(
                              labelText: 'Current Password',
                              obscureText: _obscureOldPassword,
                              onToggleVisibility: () => setState(() => _obscureOldPassword = !_obscureOldPassword),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your current password';
                              }
                              return null;
                            },
                            style: TextStyle(
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _newPasswordController,
                            obscureText: _obscureNewPassword,
                            decoration: _getInputDecoration(
                              labelText: 'New Password',
                              obscureText: _obscureNewPassword,
                              onToggleVisibility: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
                              helperText: 'Password must contain at least 8 characters, including uppercase, lowercase, and numbers',
                            ),
                            validator: (value) {
                              if (value == _oldPasswordController.text) {
                                return 'New password must be different from current password';
                              }
                              return _getPasswordValidationMessage(value);
                            },
                            style: TextStyle(
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            decoration: _getInputDecoration(
                              labelText: 'Confirm New Password',
                              obscureText: _obscureConfirmPassword,
                              onToggleVisibility: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please confirm your new password';
                              }
                              if (value != _newPasswordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                            style: TextStyle(
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                          const SizedBox(height: 32),
                          const Spacer(),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _changePassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDarkMode 
                                  ? AppTheme.upeiRed.withOpacity(0.8)
                                  : AppTheme.upeiRed,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: isDarkMode ? 0 : 1,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                       Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'Change Password',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}