import 'package:flutter/material.dart';

/// Single source of truth for all expense/income categories.
/// Used by LogExpenseScreen, FavoritesScreen, and BudgetConfigScreen.
class AppCategories {
  AppCategories._(); // prevent instantiation

  static const List<Map<String, dynamic>> all = [
    {'label': 'Food',   'icon': Icons.restaurant,    'iconName': 'restaurant',    'color': Color(0xFFFF6B35)},
    {'label': 'Shop',   'icon': Icons.shopping_bag,  'iconName': 'shopping_bag',  'color': Color(0xFF7B3FA0)},
    {'label': 'Bills',  'icon': Icons.flash_on,      'iconName': 'flash_on',      'color': Color(0xFFFFAA00)},
    {'label': 'Travel', 'icon': Icons.flight,        'iconName': 'flight',        'color': Color(0xFF1565C0)},
    {'label': 'Health', 'icon': Icons.local_hospital,'iconName': 'local_hospital','color': Color(0xFFE53935)},
    {'label': 'Other',  'icon': Icons.more_horiz,    'iconName': 'more_horiz',    'color': Color(0xFF777777)},
  ];

  /// Shared icon map used by ExpenseModel and FavoriteModel.
  static const Map<String, IconData> iconMap = {
    'restaurant':    Icons.restaurant,
    'shopping_bag':  Icons.shopping_bag,
    'flash_on':      Icons.flash_on,
    'tv':            Icons.tv,
    'flight':        Icons.flight,
    'receipt':       Icons.receipt,
    'directions_car':Icons.directions_car,
    'local_hospital':Icons.local_hospital,
    'school':        Icons.school,
    'more_horiz':    Icons.more_horiz,
  };

  /// Default monthly budget limit used as a fallback across the app.
  static const double defaultMonthlyBudget = 1000.0;
}
