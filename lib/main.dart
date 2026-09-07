import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'screens/login.dart';
import 'screens/main_layout.dart';
import 'screens/lock_screen.dart';
import 'services/local_storage_service.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'services/currency_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await LocalStorageService.init();
  await NotificationService.init();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => CurrencyService()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Daily Expense Tracker',
            theme: ThemeProvider.lightTheme,
            darkTheme: ThemeProvider.darkTheme,
            themeMode: themeProvider.themeMode,
            home: AuthWrapper(), 
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: AuthService.authStateChanges,
      initialData: AuthService.currentUser,
      builder: (context, snapshot) {
        // Logged in → go to lock screen
        if (snapshot.hasData && snapshot.data != null) {
          return LockScreen();
        }
        // Show loading only if we don't have initial data and still waiting
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF1E6E43)),
            ),
          );
        }
        // Not logged in → go to Login screen
        return LoginScreen();
      },
    );
  }
}
