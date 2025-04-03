import 'package:adhd_tracker/helpers/theme.dart';
import 'package:adhd_tracker/ui/forget_password.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:adhd_tracker/providers.dart/login_provider.dart';
import 'package:adhd_tracker/providers.dart/signup_provider.dart';
import 'package:adhd_tracker/ui/auth/create_profile.dart';
import 'package:adhd_tracker/ui/auth/signin.dart';
import 'package:adhd_tracker/ui/home/mood.dart';
import 'package:adhd_tracker/utils/color.dart';
import 'package:provider/provider.dart';
import 'package:adhd_tracker/helpers/notification.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _checkNotificationPermission();
  }

  Future<void> _checkNotificationPermission() async {
    final isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      if (!mounted) return;
      await NotificationService.requestPermission(context);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _navigateToMoodPage(BuildContext context) {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MultiProvider(
          providers: [
            ChangeNotifierProvider.value(
              value: Provider.of<LoginProvider>(context, listen: false),
            ),
          ],
          child: MoodPage(),
        ),
      ),
    );
  }

  void _performLogin(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    final loginProvider = Provider.of<LoginProvider>(context, listen: false);

    try {
      final success = await loginProvider.login(
          _emailController.text.trim(), _passwordController.text);

      if (!mounted) return;

      if (success) {
        // Check notification permission after successful login
        final isAllowed = await AwesomeNotifications().isNotificationAllowed();
        if (!isAllowed) {
          if (!mounted) return;
          await NotificationService.requestPermission(context);
        }
        
        _navigateToMoodPage(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loginProvider.errorMessage ?? 'Login failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred during login'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!value.contains('@')) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final fontScale = size.width / 375.0;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final darkPurple = Theme.of(context).textTheme.titleLarge?.color;

    return Scaffold(
      backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      appBar:AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        
        
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.settings, color: Theme.of(context).iconTheme.color),
            onSelected: (value) {
              if (value == 'theme') {
                themeProvider.toggleTheme();
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(
                value: 'theme',
                child: Row(
                  children: [
                    Icon(
                      themeProvider.isDarkMode
                          ? Icons.light_mode
                          : Icons.dark_mode,
                      color: Theme.of(context).iconTheme.color,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      themeProvider.isDarkMode
                          ? 'Switch to Light Mode'
                          : 'Switch to Dark Mode',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<LoginProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        'ADHD Tracker',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Yaro',
                          fontSize: 40 * fontScale,
                          fontWeight: FontWeight.bold,
                          color: darkPurple,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Email',
                      style: GoogleFonts.lato(
                        textStyle: TextStyle(
                          fontSize: 16 * fontScale,
                          fontWeight: FontWeight.bold,
                          color: darkPurple,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                        style: TextStyle(color: Colors.black),
                      controller: _emailController,
                      validator: _validateEmail,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: 'Enter Email',
                        hintStyle: TextStyle(color: Colors.grey[600]),
                        fillColor: Colors.grey[200],
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Password',
                      style: GoogleFonts.lato(
                        textStyle: TextStyle(
                          fontSize: 16 * fontScale,
                          fontWeight: FontWeight.bold,
                          color: darkPurple,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                        style: TextStyle(color: Colors.black),
                      controller: _passwordController,
                      validator: _validatePassword,
                      obscureText: !isPasswordVisible,
                      decoration: InputDecoration(
                        hintText: 'Enter Password',
                        hintStyle: TextStyle(color: Colors.grey[600]),
                        fillColor: Colors.grey[200],
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.grey[600],
                          ),
                          onPressed: () {
                            setState(() {
                              isPasswordVisible = !isPasswordVisible;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ForgotPasswordScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: AppTheme.upeiRed,
                            fontWeight: FontWeight.bold,
                            fontSize: 14 * fontScale,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: provider.isLoading
                            ? null
                            : () => _performLogin(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.upeiRed,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: provider.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : Text(
                                'Login',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16 * fontScale,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 14 * fontScale,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SignUpScreen(),
                                ),
                              );
                            },
                            child: Text(
                              'Sign up',
                              style: TextStyle(
                                color: AppTheme.upeiRed,
                                fontWeight: FontWeight.bold,
                                fontSize: 14 * fontScale,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
