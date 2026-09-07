import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'auth_service.dart';
import 'constants/app_categories.dart';

/// Model class for a single expense record.
class ExpenseModel {
  final String? id;
  final String name;
  final String category;
  final double amount;
  final DateTime date;
  final String iconName;
  final int colorValue;
  final String notes;
  final bool isExpense; // true = expense, false = income
  final String paymentMethod; // e.g. Cash, Visa, Bank

  ExpenseModel({
    this.id,
    required this.name,
    required this.category,
    required this.amount,
    required this.date,
    required this.iconName,
    required this.colorValue,
    this.notes = '',
    this.isExpense = true,
    this.paymentMethod = 'Cash',
  });

  // Firestore → ExpenseModel
  factory ExpenseModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ExpenseModel(
      id: doc.id,
      name: d['name'] ?? '',
      category: d['category'] ?? '',
      amount: (d['amount'] ?? 0).toDouble(),
      date: (d['date'] as Timestamp).toDate(),
      iconName: d['iconName'] ?? 'receipt',
      colorValue: d['colorValue'] ?? 0xFFAAAAAA,
      notes: d['notes'] ?? '',
      isExpense: d['isExpense'] ?? true,
      paymentMethod: d['paymentMethod'] ?? 'Cash',
    );
  }

  // ExpenseModel → Firestore Map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'iconName': iconName,
      'colorValue': colorValue,
      'notes': notes,
      'isExpense': isExpense,
      'paymentMethod': paymentMethod,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  // Get Flutter Icon from iconName string
  IconData get icon => AppCategories.iconMap[iconName] ?? Icons.receipt;

  // Get Flutter Color from colorValue int
  Color get color => Color(colorValue);
}

/// Service class for all Expense CRUD operations in Firestore.
class ExpenseService {
  static final _db = FirebaseFirestore.instance;

  /// Returns the subcollection reference for the current user's expenses.
  static CollectionReference<Map<String, dynamic>> get _col {
    final uid = AuthService.currentUser!.uid;
    return _db.collection('expenses').doc(uid).collection('records');
  }

  // ── CREATE ────────────────────────────────────────────────────────────────
  /// Saves a new expense to Firestore.
  static Future<void> addExpense(ExpenseModel expense) async {
    await _col.add(expense.toMap());
  }

  // ── READ (Stream) ─────────────────────────────────────────────────────────
  /// Returns a real-time stream of the user's recent expenses (newest first).
  static Stream<List<ExpenseModel>> getExpensesStream({int limit = 20}) {
    return _col
        .orderBy('date', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map((d) => ExpenseModel.fromDoc(d)).toList());
  }

  // ── READ (Future) ─────────────────────────────────────────────────────────
  /// One-time fetch of all expenses (for summary calculations).
  static Future<List<ExpenseModel>> getAllExpenses() async {
    final snap = await _col.orderBy('date', descending: true).get();
    return snap.docs.map((d) => ExpenseModel.fromDoc(d)).toList();
  }

  // ── DELETE ────────────────────────────────────────────────────────────────
  /// Deletes an expense by its document ID.
  static Future<void> deleteExpense(String docId) async {
    await _col.doc(docId).delete();
  }

  // ── UPDATE ────────────────────────────────────────────────────────────────
  /// Updates an existing expense document.
  static Future<void> updateExpense(String docId, ExpenseModel expense) async {
    await _col.doc(docId).update(expense.toMap());
  }

  // ── SUMMARY HELPERS ───────────────────────────────────────────────────────

  /// Calculate total income for current month.
  static double calcMonthlyIncome(List<ExpenseModel> list) {
    final now = DateTime.now();
    return list
        .where((e) =>
            !e.isExpense &&
            e.date.month == now.month &&
            e.date.year == now.year)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  /// Calculate total expenses for current month.
  static double calcMonthlyExpenses(List<ExpenseModel> list) {
    final now = DateTime.now();
    return list
        .where((e) =>
            e.isExpense &&
            e.date.month == now.month &&
            e.date.year == now.year)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  /// Format date for display (e.g. "Today, 8:14 PM" / "Yesterday" / "May 21")
  static String formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(Duration(days: 1));
    final d = DateTime(date.year, date.month, date.day);

    final hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final ampm = hour >= 12 ? 'PM' : 'AM';
    final h = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final timeStr = '$h:$minute $ampm';

    if (d == today) return 'Today, $timeStr';
    if (d == yesterday) return 'Yesterday';

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  // ── CLEAR HISTORY ─────────────────────────────────────────────────────────
  static Future<void> clearAllHistory() async {
    final batch = _db.batch();
    final snap = await _col.get();
    for (var doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // ── EXPORT CSV ────────────────────────────────────────────────────────────
  static Future<String> generateCSV() async {
    final expenses = await getAllExpenses();
    final rows = <List<dynamic>>[
      ['Date', 'Type', 'Category', 'Name', 'Amount', 'Payment Method', 'Notes'],
    ];

    for (final e in expenses) {
      final dateStr =
          '${e.date.year}-${e.date.month.toString().padLeft(2, '0')}-${e.date.day.toString().padLeft(2, '0')}';
      rows.add([
        dateStr,
        e.isExpense ? 'Expense' : 'Income',
        e.category,
        e.name,
        e.amount,
        e.paymentMethod,
        e.notes,
      ]);
    }

    return const ListToCsvConverter().convert(rows);
  }
}
