import 'package:flutter/material.dart';
import '../services/local_storage_service.dart';
import '../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _notificationsEnabled = false;
  TimeOfDay _selectedTime = TimeOfDay(hour: 20, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    setState(() {
      _notificationsEnabled = LocalStorageService.notificationsEnabled;
      final timeStr = LocalStorageService.notificationTime;
      if (timeStr != null) {
        final parts = timeStr.split(':');
        if (parts.length == 2) {
          _selectedTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
        }
      }
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() => _notificationsEnabled = value);
    await LocalStorageService.saveNotificationsEnabled(value);

    if (value) {
      await _scheduleNotification();
    } else {
      await NotificationService.cancelAll();
    }
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: isDark ? ThemeData.dark() : ThemeData.light(),
          child: child!,
        );
      }
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
      await LocalStorageService.saveNotificationTime('${picked.hour}:${picked.minute}');
      if (_notificationsEnabled) {
        await _scheduleNotification();
      }
    }
  }

  Future<void> _scheduleNotification() async {
    await NotificationService.scheduleDailyNotification(_selectedTime.hour, _selectedTime.minute);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Daily reminder set for ${_selectedTime.format(context)}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? Color(0xFF252724) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Notification Settings', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: EdgeInsets.all(20),
        children: [
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: Offset(0, 3))],
            ),
            child: Column(
              children: [
                SwitchListTile(
                  activeColor: Color(0xFF1E6E43),
                  title: Text('Daily Reminders', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                  subtitle: Text('Remind me to log my expenses every day.', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                  value: _notificationsEnabled,
                  onChanged: _toggleNotifications,
                ),
                if (_notificationsEnabled) ...[
                  Divider(height: 1, indent: 16, endIndent: 16, color: isDark ? Color(0xFF333533) : Colors.grey[100]),
                  ListTile(
                    title: Text('Reminder Time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
                    subtitle: Text(_selectedTime.format(context), style: TextStyle(color: Color(0xFF1E6E43), fontWeight: FontWeight.bold)),
                    trailing: Icon(Icons.access_time, color: Colors.grey[400]),
                    onTap: _pickTime,
                  ),
                ]
              ],
            ),
          ),
          SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Text(
              'Enabling daily reminders helps you stay consistent and keeps your budget accurate.',
              style: TextStyle(color: Colors.grey[500], fontSize: 12, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 30),
          Center(
            child: ElevatedButton.icon(
              onPressed: () async {
                await NotificationService.showTestNotification();
              },
              icon: Icon(Icons.notifications_active),
              label: Text('Test Notification'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1E6E43),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
