import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'constants/app_categories.dart';

class FavoriteModel {
  final String? id;
  final String name;
  final double amount;
  final String category;
  final String frequency;
  final int colorValue;
  final String iconName;

  FavoriteModel({
    this.id,
    required this.name,
    required this.amount,
    required this.category,
    required this.frequency,
    required this.colorValue,
    required this.iconName,
  });

  factory FavoriteModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return FavoriteModel(
      id: doc.id,
      name: d['name'] ?? '',
      amount: (d['amount'] ?? 0).toDouble(),
      category: d['category'] ?? '',
      frequency: d['frequency'] ?? '',
      colorValue: d['colorValue'] ?? 0xFFAAAAAA,
      iconName: d['iconName'] ?? 'receipt',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'amount': amount,
      'category': category,
      'frequency': frequency,
      'colorValue': colorValue,
      'iconName': iconName,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  IconData get icon => AppCategories.iconMap[iconName] ?? Icons.receipt;
  Color get color => Color(colorValue);
}

class FavoriteService {
  static final _db = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> get _col {
    final uid = AuthService.currentUser!.uid;
    return _db.collection('favorites').doc(uid).collection('items');
  }

  static Future<void> addFavorite(FavoriteModel fav) async {
    await _col.add(fav.toMap());
  }

  static Stream<List<FavoriteModel>> getFavoritesStream() {
    return _col
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => FavoriteModel.fromDoc(d)).toList());
  }

  static Future<void> deleteFavorite(String docId) async {
    await _col.doc(docId).delete();
  }
}
