import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // --- User Session ---
  static Future<void> saveUserSession(String name, String email) async {
    await _prefs?.setString('user_name', name);
    await _prefs?.setString('user_email', email);
  }

  static String get userName => _prefs?.getString('user_name') ?? 'User';
  static String get userEmail => _prefs?.getString('user_email') ?? '';

  static Future<void> clearSession() async {
    await _prefs?.remove('user_name');
    await _prefs?.remove('user_email');
    // Clear other sensitive data if needed
  }

  // --- Preferences ---
  
  // Currency: USD or LKR
  static Future<void> saveCurrency(String currencyCode) async {
    await _prefs?.setString('pref_currency', currencyCode);
  }
  static String get currency => _prefs?.getString('pref_currency') ?? 'USD';

  // Theme Appearance: System, Dark, Light
  static Future<void> saveAppearance(String theme) async {
    await _prefs?.setString('pref_theme', theme);
  }
  static String get appearance => _prefs?.getString('pref_theme') ?? 'System';

  // Budget Alerts
  static Future<void> saveBudgetAlerts(bool enabled) async {
    await _prefs?.setBool('pref_budget_alerts', enabled);
  }
  static bool get budgetAlerts => _prefs?.getBool('pref_budget_alerts') ?? true;

  // Biometrics Security
  static Future<void> saveBiometrics(bool enabled) async {
    await _prefs?.setBool('pref_biometrics', enabled);
  }
  static bool get biometrics => _prefs?.getBool('pref_biometrics') ?? false;

  // Local Notifications
  static Future<void> saveNotificationsEnabled(bool enabled) async {
    await _prefs?.setBool('notifications_enabled', enabled);
  }
  static bool get notificationsEnabled => _prefs?.getBool('notifications_enabled') ?? false;

  static Future<void> saveNotificationTime(String time) async {
    await _prefs?.setString('notification_time', time);
  }
  static String? get notificationTime => _prefs?.getString('notification_time');
}
