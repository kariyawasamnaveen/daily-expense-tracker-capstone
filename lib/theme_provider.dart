import 'package:flutter/material.dart';
import 'local_storage_service.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeProvider() {
    _loadTheme();
  }

  ThemeMode get themeMode => _themeMode;

  void _loadTheme() {
    String themeStr = LocalStorageService.appearance;
    if (themeStr == 'Dark') {
      _themeMode = ThemeMode.dark;
    } else if (themeStr == 'Light') {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    final list = ['System', 'Dark', 'Light'];
    String current = LocalStorageService.appearance;
    int idx = list.indexOf(current);
    if (idx == -1) idx = 0;
    
    String next = list[(idx + 1) % list.length];
    await LocalStorageService.saveAppearance(next);
    
    if (next == 'Dark') {
      _themeMode = ThemeMode.dark;
    } else if (next == 'Light') {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.system;
    }
    
    notifyListeners();
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primarySwatch: Colors.green,
      scaffoldBackgroundColor: Color(0xFFF5F5F3),
      appBarTheme: AppBarTheme(
        backgroundColor: Color(0xFFF5F5F3),
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      cardColor: Colors.white,
      textTheme: TextTheme(
        bodyMedium: TextStyle(color: Colors.black87),
        bodyLarge: TextStyle(color: Colors.black),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primarySwatch: Colors.green,
      scaffoldBackgroundColor: Color(0xFF1A1C19),
      appBarTheme: AppBarTheme(
        backgroundColor: Color(0xFF1A1C19),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardColor: Color(0xFF252724),
      textTheme: TextTheme(
        bodyMedium: TextStyle(color: Colors.white70),
        bodyLarge: TextStyle(color: Colors.white),
      ),
    );
  }
}
