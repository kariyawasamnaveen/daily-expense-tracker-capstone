import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';
import 'signup.dart';
import 'utils/app_snackbar.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool rememberMe = false;
  bool isLoading = false;
  bool _obscurePassword = true;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError("Please enter your email and password");
      return;
    }

    setState(() => isLoading = true);
    try {
      await AuthService.signIn(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      _showError(_friendlyError(e.code));
    } catch (e) {
      _showError("Something went wrong. Please try again.");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      _showError("Please enter your email address first");
      return;
    }
    try {
      await AuthService.sendPasswordReset(email);
      _showSuccess("Password reset email sent! Check your inbox.");
    } on FirebaseAuthException catch (e) {
      _showError(_friendlyError(e.code));
    }
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'user-not-found':
        return "No account found with this email";
      case 'wrong-password':
        return "Incorrect password";
      case 'invalid-email':
        return "Invalid email address";
      case 'user-disabled':
        return "This account has been disabled";
      case 'too-many-requests':
        return "Too many attempts. Try again later";
      default:
        return "Login failed. Please try again";
    }
  }

  void _showError(String msg) => AppSnackBar.showError(context, msg);
  void _showSuccess(String msg) => AppSnackBar.showSuccess(context, msg);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1A1C19),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 50),

              // Logo
              Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: DecorationImage(
                    image: AssetImage('assets/images/app_logo.png'),
                    fit: BoxFit.cover,
                  ),
                  boxShadow: [
                    BoxShadow(color: Color(0xFF1E6E43).withValues(alpha: 0.3), blurRadius: 20, offset: Offset(0, 5)),
                  ],
                ),
              ),
              SizedBox(height: 30),

              Text(
                "Welcome back",
                style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Sign in to your Daily Expense Tracker account',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
              ),
              SizedBox(height: 40),

              // Email field
              _fieldLabel('EMAIL ADDRESS'),
              SizedBox(height: 8),
              TextField(
                controller: emailController,
                style: TextStyle(color: Colors.white),
                keyboardType: TextInputType.emailAddress,
                decoration: _inputDecoration(
                  hint: 'alex@example.com',
                  prefixIcon: Icons.email_outlined,
                ),
              ),
              SizedBox(height: 20),

              // Password field
              _fieldLabel('PASSWORD'),
              SizedBox(height: 8),
              TextField(
                controller: passwordController,
                obscureText: _obscurePassword,
                style: TextStyle(color: Colors.white),
                decoration: _inputDecoration(
                  hint: '••••••••',
                  prefixIcon: Icons.lock_outline,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey[600],
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              SizedBox(height: 14),

              // Remember me + Forgot password
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        height: 22,
                        width: 22,
                        child: Checkbox(
                          value: rememberMe,
                          activeColor: Color(0xFF1E6E43),
                          checkColor: Colors.white,
                          side: BorderSide(color: Colors.grey[600]!),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          onChanged: (v) => setState(() => rememberMe = v!),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text('Remember me', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                    ],
                  ),
                  GestureDetector(
                    onTap: _forgotPassword,
                    child: Text(
                      'Forgot password?',
                      style: TextStyle(color: Color(0xFF4CAF50), fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 32),

              // Sign In button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF1E6E43),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: isLoading ? null : _signIn,
                  child: isLoading
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'Sign In',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),

              // Create account link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('New here? ', style: TextStyle(color: Colors.grey[500])),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => SignupScreen()),
                    ),
                    child: Text(
                      'Create account',
                      style: TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: TextStyle(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      prefixIcon: Icon(prefixIcon, color: Colors.grey[600], size: 20),
      suffixIcon: suffixIcon,
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[700]),
      filled: true,
      fillColor: Color(0xFF252724),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Color(0xFF1E6E43), width: 1.5),
      ),
      contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    );
  }
}
