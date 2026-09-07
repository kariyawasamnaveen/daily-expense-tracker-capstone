import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import 'auth_service.dart';
import 'expense_service.dart';
import 'currency_service.dart';
import 'local_storage_service.dart';
import 'currency_rates.dart';
import 'notifications.dart';
import 'theme_provider.dart';
import 'main.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Local states based on LocalStorageService
  bool _budgetAlerts = true;
  bool _biometrics = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  void _loadPreferences() {
    setState(() {
      _budgetAlerts = LocalStorageService.budgetAlerts;
      _biometrics = LocalStorageService.biometrics;
    });
  }



  Future<void> _toggleAppearance() async {
    await Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
  }

  Future<void> _toggleBudgetAlerts() async {
    bool next = !_budgetAlerts;
    await LocalStorageService.saveBudgetAlerts(next);
    setState(() => _budgetAlerts = next);
  }

  Future<void> _toggleBiometrics() async {
    final newValue = !_biometrics;
    setState(() {
      _biometrics = newValue;
    });
    await LocalStorageService.saveBiometrics(newValue);
  }

  Future<void> _exportData() async {
    try {
      final csvData = await ExpenseService.generateCSV();
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/expenses_export.csv';
      final file = File(path);
      await file.writeAsString(csvData);

      final xfile = XFile(path);
      await Share.shareXFiles([xfile], text: 'My Expense Data');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to export data.')));
    }
  }

  Future<void> _clearHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1A1C19),
        title: Text('Clear History', style: TextStyle(color: Colors.redAccent)),
        content: Text('Are you sure you want to delete ALL your expense history? This cannot be undone.', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ExpenseService.clearAllHistory();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('History cleared.'), backgroundColor: Color(0xFF1E6E43)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyService = Provider.of<CurrencyService>(context);
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Color(0xFF1A1C19) : Color(0xFFF5F5F3);
    final cardColor = isDark ? Color(0xFF252724) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.grey[500];
    final dividerColor = isDark ? Color(0xFF333533) : Colors.grey[100];

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 24, 20, 100), // Added bottom padding to prevent FAB overlap
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── USER PROFILE HEADER ──
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: Offset(0, 3)),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.black87,
                      child: Text(
                        AuthService.displayName.isNotEmpty
                            ? AuthService.displayName[0].toUpperCase()
                            : 'U',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AuthService.displayName,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
                          ),
                          SizedBox(height: 2),
                          Text(
                            '${AuthService.currentUser?.email ?? ''} · Premium',
                            style: TextStyle(color: subTextColor, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 14),

              // ── PREMIUM PLAN CARD ──
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Color(0xFF1E6E43).withValues(alpha: 0.15) : Color(0xFFEDF5EE),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Color(0xFF1E6E43).withValues(alpha: 0.15), width: 1),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Color(0xFF1E6E43), shape: BoxShape.circle),
                      child: Icon(Icons.flash_on, color: Colors.white, size: 16),
                    ),
                    SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Premium Plan', style: TextStyle(color: Color(0xFF1E6E43), fontWeight: FontWeight.bold, fontSize: 14)),
                        SizedBox(height: 2),
                        Text('Renews June 1, 2026 · \$4.99/mo', style: TextStyle(color: Color(0xFF2E7D52), fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 28),

              // ── ACCOUNT SECTION ──
              _sectionLabel('ACCOUNT'),
              SizedBox(height: 10),
              _settingsGroup([
                _SettingItem(
                  icon: Icons.person_outline,
                  iconColor: Color(0xFF1E6E43),
                  title: 'Profile',
                  subtitle: AuthService.displayName,
                  onTap: () {},
                ),
                _SettingItem(
                  icon: Icons.shield_outlined,
                  iconColor: Color(0xFF1565C0),
                  title: 'Security',
                  subtitle: 'Biometrics ${_biometrics ? 'on' : 'off'}',
                  onTap: _toggleBiometrics,
                ),
                _SettingItem(
                  icon: Icons.notifications_outlined,
                  iconColor: Color(0xFFE65100),
                  title: 'Notifications',
                  subtitle: 'Settings',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => NotificationsScreen()));
                  },
                  isLast: true,
                ),
              ]),

              SizedBox(height: 28),

              // ── PREFERENCES SECTION ──
              _sectionLabel('PREFERENCES'),
              SizedBox(height: 10),
              _settingsGroup([
                _SettingItem(
                  icon: Icons.language,
                  iconColor: Color(0xFF7B3FA0),
                  title: 'Currency',
                  subtitle: 'Live Rates & Settings',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => CurrencyRatesScreen()));
                  },
                ),
                _SettingItem(
                  icon: Icons.dark_mode_outlined,
                  iconColor: Color(0xFF555555),
                  title: 'Appearance',
                  subtitle: LocalStorageService.appearance,
                  onTap: _toggleAppearance,
                ),
                _SettingItem(
                  icon: Icons.tune,
                  iconColor: Color(0xFFE53935),
                  title: 'Budget Alerts',
                  subtitle: _budgetAlerts ? 'Enabled' : 'Disabled',
                  onTap: _toggleBudgetAlerts,
                  isLast: true,
                ),
              ]),

              SizedBox(height: 28),

              // ── DATA SECTION ──
              _sectionLabel('DATA'),
              SizedBox(height: 10),
              _settingsGroup([
                _SettingItem(
                  icon: Icons.download_outlined,
                  iconColor: Color(0xFFFF6B35),
                  title: 'Export Data',
                  subtitle: 'CSV Format',
                  onTap: _exportData,
                ),
                _SettingItem(
                  icon: Icons.delete_outline,
                  iconColor: Color(0xFFE53935),
                  title: 'Clear History',
                  subtitle: 'Erase all records',
                  onTap: _clearHistory,
                  isLast: true,
                ),
              ]),

              SizedBox(height: 28),

              // ── SIGN OUT BUTTON ──
              Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  color: isDark ? Color(0xFFE53935).withValues(alpha: 0.1) : Color(0xFFFFF0EE),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Color(0xFFE53935).withValues(alpha: 0.4), width: 1.5),
                ),
                child: TextButton.icon(
                  onPressed: () async {
                    await AuthService.signOut();
                    if (context.mounted) {
                      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => AuthWrapper()),
                        (route) => false,
                      );
                    }
                  },
                  icon: Icon(Icons.logout, color: Color(0xFFE53935), size: 18),
                  label: Text('Sign Out', style: TextStyle(color: Color(0xFFE53935), fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
              SizedBox(height: 14),

              Center(
                child: Text('Daily Expense Tracker v2.4.1 · Build 20260524', style: TextStyle(color: Colors.grey[400], fontSize: 11)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      label,
      style: TextStyle(color: isDark ? Colors.white54 : Colors.grey[500], fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0),
    );
  }

  Widget _settingsGroup(List<_SettingItem> items) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? Color(0xFF252724) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.grey[500];
    final dividerColor = isDark ? Color(0xFF333533) : Colors.grey[100];

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: Offset(0, 3))],
      ),
      child: Column(
        children: items.map((item) {
          bool isLast = item.isLast;
          return Column(
            children: [
              ListTile(
                onTap: item.onTap,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(color: item.iconColor, shape: BoxShape.circle),
                  child: Icon(item.icon, color: Colors.white, size: 18),
                ),
                title: Text(item.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
                subtitle: Text(item.subtitle, style: TextStyle(color: subTextColor, fontSize: 12)),
                trailing: Icon(Icons.chevron_right, color: isDark ? Colors.white30 : Colors.grey[350], size: 20),
              ),
              if (!isLast) Divider(height: 1, indent: 70, endIndent: 16, color: dividerColor),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _SettingItem {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool isLast;

  _SettingItem({required this.icon, required this.iconColor, required this.title, required this.subtitle, this.onTap, this.isLast = false});
}
