import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'local_storage_service.dart';
import 'main_layout.dart';

class LockScreen extends StatefulWidget {
  @override
  _LockScreenState createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  bool _isAuthenticating = false;
  bool _isAuthenticated = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authenticate();
    });
  }

  Future<void> _authenticate() async {
    if (!LocalStorageService.biometrics) {
      // If biometrics is not enabled in settings, just pass through
      setState(() {
        _isAuthenticated = true;
      });
      return;
    }

    bool authenticated = false;
    try {
      setState(() {
        _isAuthenticating = true;
        _errorMessage = '';
      });
      authenticated = await auth.authenticate(
        localizedReason: 'Please authenticate to access your expense tracker',
      );
    } catch (e) {
      setState(() => _errorMessage = 'Authentication error. Please try again.');
    } finally {
      setState(() {
        _isAuthenticating = false;
        _isAuthenticated = authenticated;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isAuthenticated) {
      return MainLayout();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 80, color: Color(0xFF1E6E43)),
            SizedBox(height: 20),
            Text(
              'App Locked',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            SizedBox(height: 40),
            if (_isAuthenticating)
              CircularProgressIndicator(color: Color(0xFF1E6E43))
            else
              ElevatedButton.icon(
                onPressed: _authenticate,
                icon: Icon(Icons.fingerprint),
                label: Text('Unlock'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF1E6E43),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            if (_errorMessage.isNotEmpty) ...[
              SizedBox(height: 16),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
