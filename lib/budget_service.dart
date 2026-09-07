import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';

class BudgetModel {
  final double monthlyLimit;
  final Map<String, double> categoryLimits;

  BudgetModel({
    required this.monthlyLimit,
    this.categoryLimits = const {},
  });

  factory BudgetModel.fromDoc(DocumentSnapshot doc) {
    if (!doc.exists || doc.data() == null) {
      // Default fallback budget if not set
      return BudgetModel(monthlyLimit: 1000.0, categoryLimits: {});
    }
    final d = doc.data() as Map<String, dynamic>;
    
    Map<String, double> cats = {};
    if (d['categoryLimits'] != null) {
      final Map<String, dynamic> rawCats = d['categoryLimits'];
      rawCats.forEach((key, value) {
        cats[key] = (value as num).toDouble();
      });
    }

    return BudgetModel(
      monthlyLimit: (d['monthlyLimit'] ?? 1000.0).toDouble(),
      categoryLimits: cats,
    );
  }

  // Helper to get limit for a specific category
  double getLimitFor(String categoryName, double fallback) {
    return categoryLimits[categoryName] ?? fallback;
  }
}

class BudgetService {
  static final _db = FirebaseFirestore.instance;

  static Stream<BudgetModel> getBudgetStream() {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return Stream.value(BudgetModel(monthlyLimit: 1000.0));
    
    return _db.collection('budgets').doc(uid).snapshots().map((doc) => BudgetModel.fromDoc(doc));
  }

  static Future<void> updateBudget(double newLimit) async {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return;

    await _db.collection('budgets').doc(uid).set({
      'monthlyLimit': newLimit,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> updateCategoryBudget(String categoryName, double newLimit) async {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return;

    await _db.collection('budgets').doc(uid).set({
      'categoryLimits': {
        categoryName: newLimit,
      },
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
