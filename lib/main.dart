import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:adhd_tracker/helpers/notification.dart';
import 'package:adhd_tracker/helpers/theme.dart';
import 'package:adhd_tracker/providers.dart/home_provider.dart';
import 'package:adhd_tracker/providers.dart/login_provider.dart';
import 'package:adhd_tracker/providers.dart/medication_provider.dart';
import 'package:adhd_tracker/providers.dart/profile_provider.dart';
import 'package:adhd_tracker/providers.dart/signup_provider.dart';
import 'package:adhd_tracker/providers.dart/symptom_provider.dart';
import 'package:adhd_tracker/providers.dart/users_provider.dart';
import 'package:adhd_tracker/ui/auth/create_profile.dart';

import 'package:adhd_tracker/ui/splash.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initializeNotifications();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LoginProvider()..initialize(),),
        ChangeNotifierProvider(create: (_) => SignUpProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => SymptomProvider()),
        ChangeNotifierProvider(create: (_) => MedicationProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => HealthDataProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static Future<bool> checkProfileCreationNeeded() async {
    const storage = FlutterSecureStorage();
    final isPending = await storage.read(key: 'profile_creation_pending');
    return isPending == 'true';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          theme: ThemeData.light().copyWith(
            scaffoldBackgroundColor:
                Colors.white, // Explicitly set white for light mode
          ),
          darkTheme: ThemeData.dark(),
          themeMode:
              themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          debugShowCheckedModeBanner: false,
          home: FutureBuilder<bool>(
            future: checkProfileCreationNeeded(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              // If profile creation is pending, show profile creation page
              if (snapshot.data == true) {
                return const ProfileCreationPage();
              }

              // Otherwise show your normal initial route
              return const SplashScreen();
            },
          ),
        );
      },
    );
  }
}
