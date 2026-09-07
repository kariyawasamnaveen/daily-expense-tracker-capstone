import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/favorite_service.dart';
import '../services/expense_service.dart';
import '../services/currency_service.dart';
import '../constants/app_categories.dart';
import '../utils/app_snackbar.dart';

class FavoritesScreen extends StatefulWidget {
  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  NumberFormat get currencyFormat => NumberFormat.currency(
    symbol: Provider.of<CurrencyService>(context).currencySymbol, 
    decimalDigits: 0
  );
  String _searchQuery = '';

  // For the bottom sheet Add form
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  String _selectedFrequency = 'Monthly';
  int _selectedCategoryIndex = 0;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _logExpenseFromFav(FavoriteModel fav) async {
    final expense = ExpenseModel(
      name: fav.name,
      category: fav.category,
      amount: fav.amount,
      date: DateTime.now(),
      iconName: fav.iconName,
      colorValue: fav.colorValue,
      notes: 'Added from Quick Log',
      isExpense: true,
      paymentMethod: 'Cash',
    );

    try {
      await ExpenseService.addExpense(expense);
      if (mounted) {
        AppSnackBar.showSuccess(context, 'Logged ${fav.name} successfully!');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Failed to log expense.');
      }
    }
  }

  void _showAddFavoriteSheet() {
    _nameCtrl.clear();
    _amountCtrl.clear();
    _selectedFrequency = 'Monthly';
    _selectedCategoryIndex = 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
              decoration: BoxDecoration(
                color: Color(0xFFF5F5F3),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('New Template', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    SizedBox(height: 20),
                    
                    TextField(
                      controller: _nameCtrl,
                      decoration: InputDecoration(
                        hintText: 'Template Name (e.g. Netflix)',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      ),
                    ),
                    SizedBox(height: 12),
                    
                    TextField(
                      controller: _amountCtrl,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        hintText: 'Amount (${Provider.of<CurrencyService>(context, listen: false).currencySymbol})',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      ),
                    ),
                    SizedBox(height: 12),

                    // Frequency Dropdown
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedFrequency,
                          isExpanded: true,
                          items: ['Daily', 'Weekly', 'Monthly', 'Yearly'].map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                          onChanged: (v) { if (v != null) setModalState(() => _selectedFrequency = v); },
                        ),
                      ),
                    ),
                    SizedBox(height: 20),

                    Text('CATEGORY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                    SizedBox(height: 10),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: List.generate(AppCategories.all.length, (i) {
                        final cat = AppCategories.all[i];
                        final isSel = _selectedCategoryIndex == i;
                        return GestureDetector(
                          onTap: () => setModalState(() => _selectedCategoryIndex = i),
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 200),
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSel ? cat['color'] : Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: isSel ? [BoxShadow(color: cat['color'].withOpacity(0.4), blurRadius: 8, offset: Offset(0, 3))] : [],
                            ),
                            child: Icon(cat['icon'], color: isSel ? Colors.white : cat['color'], size: 24),
                          ),
                        );
                      }),
                    ),
                    SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF1E6E43),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        onPressed: () async {
                          final name = _nameCtrl.text.trim();
                          final amt = double.tryParse(_amountCtrl.text.trim());
                          if (name.isEmpty || amt == null || amt <= 0) return;

                          final cat = AppCategories.all[_selectedCategoryIndex];
                          final fav = FavoriteModel(
                            name: name,
                            amount: amt,
                            category: cat['label'],
                            frequency: _selectedFrequency,
                            colorValue: (cat['color'] as Color).value,
                            iconName: cat['iconName'],
                          );
                          await FavoriteService.addFavorite(fav);
                          if (context.mounted) Navigator.pop(context);
                        },
                        child: Text('Save Template', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F3),
      appBar: AppBar(
        backgroundColor: Color(0xFFF5F5F3),
        elevation: 0,
        titleSpacing: 22,
        title: StreamBuilder<List<FavoriteModel>>(
          stream: FavoriteService.getFavoritesStream(),
          builder: (context, snapshot) {
            int count = snapshot.data?.length ?? 0;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Favorites', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 24)),
                Text('$count saved templates', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              ],
            );
          }
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 20),
            child: GestureDetector(
              onTap: _showAddFavoriteSheet,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                child: Icon(Icons.add, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.fromLTRB(20, 10, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar
            Container(
              decoration: BoxDecoration(color: Color(0xFFECECE9), borderRadius: BorderRadius.circular(30)),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.search, color: Colors.grey[500], size: 20),
                  hintText: "Search favorites...",
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            SizedBox(height: 22),

            Text('QUICK LOG', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[500], letterSpacing: 1.0)),
            SizedBox(height: 12),

            Expanded(
              child: StreamBuilder<List<FavoriteModel>>(
                stream: FavoriteService.getFavoritesStream(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return Center(child: Text('Error loading favorites'));
                  if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                    return Center(child: CircularProgressIndicator(color: Color(0xFF1E6E43)));
                  }

                  final allFavs = snapshot.data ?? [];
                  final filteredFavs = allFavs.where((f) => f.name.toLowerCase().contains(_searchQuery)).toList();

                  if (filteredFavs.isEmpty) {
                    return Center(child: Text('No templates found.', style: TextStyle(color: Colors.grey)));
                  }

                  return ListView.builder(
                    itemCount: filteredFavs.length,
                    itemBuilder: (context, i) {
                      final fav = filteredFavs[i];
                      return Container(
                        margin: EdgeInsets.only(bottom: 12),
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: Offset(0, 3))],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(color: fav.color, shape: BoxShape.circle),
                              child: Icon(fav.icon, color: Colors.white, size: 20),
                            ),
                            SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(fav.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                                  SizedBox(height: 3),
                                  Text(fav.frequency, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                                ],
                              ),
                            ),
                            Text(currencyFormat.format(fav.amount), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
                            SizedBox(width: 12),
                            GestureDetector(
                              onTap: () => _logExpenseFromFav(fav),
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(color: Color(0xFFECECE9), shape: BoxShape.circle),
                                child: Icon(Icons.add, size: 18, color: Colors.black54),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }
              ),
            ),

            Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star_border, color: Colors.grey[400], size: 14),
                    SizedBox(width: 5),
                    Text('Click + to quickly log an expense', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
