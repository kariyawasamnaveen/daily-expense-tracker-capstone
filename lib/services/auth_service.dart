import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/local_storage_service.dart';

/// Central authentication & user profile service.
/// All screens should use this class instead of calling FirebaseAuth directly.
class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Current user ──────────────────────────────────────────────────────────
  static User? get currentUser => _auth.currentUser;
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Sign Up ───────────────────────────────────────────────────────────────
  /// Creates a new Firebase Auth user, updates displayName, and saves a
  /// Firestore user document under /users/{uid}.
  static Future<void> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    // 1. Create auth user
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    // 2. Update display name on the Auth profile
    await cred.user!.updateDisplayName(name.trim());

    // 3. Save extra data (name, phone) to Firestore
    await _db.collection('users').doc(cred.user!.uid).set({
      'uid': cred.user!.uid,
      'name': name.trim(),
      'email': email.trim(),
      'phone': phone.trim(),
      'plan': 'free',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 4. Save to Local Storage
    await LocalStorageService.saveUserSession(name.trim(), email.trim());
  }

  // ── Sign In ───────────────────────────────────────────────────────────────
  static Future<void> signIn({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    // Save to Local Storage
    final user = cred.user;
    if (user != null) {
      await LocalStorageService.saveUserSession(user.displayName ?? 'User', user.email ?? '');
    }
  }

  // ── Forgot Password ───────────────────────────────────────────────────────
  static Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  // ── Sign Out ──────────────────────────────────────────────────────────────
  static Future<void> signOut() async {
    await LocalStorageService.clearSession();
    await _auth.signOut();
  }

  // ── Get user profile from Firestore ──────────────────────────────────────
  static Future<Map<String, dynamic>?> getUserProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Returns display name from Auth profile (fast, no network call).
  static String get displayName {
    final name = _auth.currentUser?.displayName;
    if (name == null || name.trim().isEmpty) {
      // Fallback to local storage if Firebase name is empty
      return LocalStorageService.userName;
    }
    return name;
  }

  /// Returns first name only.
  static String get firstName {
    final full = displayName;
    return full.split(' ').first;
  }

  /// Returns user email.
  static String get email => _auth.currentUser?.email ?? '';
}
