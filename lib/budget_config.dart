import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'budget_service.dart';
import 'expense_service.dart';
import 'constants/app_categories.dart';

class BudgetConfigScreen extends StatefulWidget {
  @override
  _BudgetConfigScreenState createState() => _BudgetConfigScreenState();
}

class _BudgetConfigScreenState extends State<BudgetConfigScreen> {
  final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

  /// Generic dialog for editing any budget limit (total or per-category).
  Future<void> _showBudgetEditDialog(String title, double currentLimit, Future<void> Function(double) onSave) async {
    final ctrl = TextEditingController(text: currentLimit.toInt().toString());
    final newLimitStr = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1A1C19),
        title: Text(title, style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter amount',
            hintStyle: TextStyle(color: Colors.grey),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF1E6E43))),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF1E6E43)),
            onPressed: () => Navigator.pop(context, ctrl.text),
            child: Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (newLimitStr != null && newLimitStr.isNotEmpty) {
      final val = double.tryParse(newLimitStr);
      if (val != null && val > 0) await onSave(val);
    }
  }

  Widget _errorScaffold(String err) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F3),
      body: Center(child: Text("Error: $err", style: TextStyle(color: Colors.red))),
    );
  }

  Widget _loadingScaffold() {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F3),
      body: Center(child: CircularProgressIndicator(color: Color(0xFF1E6E43))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ExpenseModel>>(
      stream: ExpenseService.getExpensesStream(limit: 500),
      builder: (context, expenseSnap) {
        if (expenseSnap.hasError) return _errorScaffold(expenseSnap.error.toString());
        if (expenseSnap.connectionState == ConnectionState.waiting && !expenseSnap.hasData) return _loadingScaffold();

        final expenses = expenseSnap.data ?? [];
        final totalSpent = ExpenseService.calcMonthlyExpenses(expenses);

        Map<String, double> categorySpent = {};
        for (var c in _baseCategories) {
          categorySpent[c['name']] = 0.0;
        }

        final now = DateTime.now();
        for (var e in expenses) {
          if (e.isExpense && e.date.month == now.month && e.date.year == now.year) {
            categorySpent[e.category] = (categorySpent[e.category] ?? 0.0) + e.amount;
          }
        }

        return StreamBuilder<BudgetModel>(
          stream: BudgetService.getBudgetStream(),
          builder: (context, budgetSnap) {
            if (budgetSnap.hasError) return _errorScaffold(budgetSnap.error.toString());

            final budgetModel = budgetSnap.data ?? BudgetModel(monthlyLimit: AppCategories.defaultMonthlyBudget);
            double monthlyLimit = budgetModel.monthlyLimit;

            int totalPercent = 0;
            if (monthlyLimit > 0) {
              totalPercent = ((totalSpent / monthlyLimit) * 100).clamp(0, 100).toInt();
            }
            double remaining = (monthlyLimit - totalSpent);
            if (remaining < 0) remaining = 0;

            const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
            String monthName = '${months[now.month - 1]} ${now.year}';

            return Scaffold(
              backgroundColor: Color(0xFFF5F5F3),
              appBar: AppBar(
                backgroundColor: Color(0xFFF5F5F3),
                elevation: 0,
                leading: Padding(
                  padding: const EdgeInsets.only(left: 14.0),
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(color: Color(0xFFECECE9), shape: BoxShape.circle),
                      child: Icon(Icons.arrow_back, color: Colors.black87, size: 20),
                    ),
                  ),
                ),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Budget Setup', style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(monthName, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                  ],
                ),
                actions: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 20.0),
                      child: GestureDetector(
                        onTap: () => _showBudgetEditDialog('Total Budget', monthlyLimit, BudgetService.updateBudget),
                        child: Text(
                          'Edit',
                          style: TextStyle(color: Color(0xFF1E6E43), fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              body: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Dark Summary Card ──
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Color(0xFF1A1C19),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('MONTHLY BUDGET', style: TextStyle(color: Color(0xFF7A7D78), fontSize: 10, letterSpacing: 1)),
                                  SizedBox(height: 6),
                                  Text(
                                    currencyFormat.format(monthlyLimit),
                                    style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('SPENT', style: TextStyle(color: Color(0xFF7A7D78), fontSize: 10, letterSpacing: 1)),
                                  SizedBox(height: 6),
                                  Text(
                                    currencyFormat.format(totalSpent),
                                    style: TextStyle(color: Colors.redAccent, fontSize: 22, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
                          Stack(
                            children: [
                              Container(height: 8, decoration: BoxDecoration(color: Color(0xFF3A3D39), borderRadius: BorderRadius.circular(4))),
                              FractionallySizedBox(
                                widthFactor: (totalPercent / 100.0).clamp(0.0, 1.0),
                                child: Container(height: 8, decoration: BoxDecoration(color: Color(0xFF1E6E43), borderRadius: BorderRadius.circular(4))),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('$totalPercent% used', style: TextStyle(color: Color(0xFF4CAF50), fontSize: 12)),
                              Text('${currencyFormat.format(remaining)} remaining', style: TextStyle(color: Color(0xFF7A7D78), fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 28),

                    // ── CATEGORIES SECTION LABEL ──
                    Text(
                      'CATEGORIES',
                      style: TextStyle(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                    SizedBox(height: 14),

                    // ── Individual category cards ──
                    ...AppCategories.all.map((cat) {
                      String catName = cat['name'] ?? cat['label'];
                      Color color = cat['color'];
                      double spent = categorySpent[catName] ?? 0.0;
                      double limit = budgetModel.getLimitFor(catName, 200.0);
                      return _buildCategoryCard(catName, color, spent, limit);
                    }).toList(),
                  ],
                ),
              ),
            );
          }
        );
      }
    );
  }

  Widget _buildCategoryCard(String name, Color color, double spent, double limit) {
    double percent = 0;
    if (limit > 0) percent = spent / limit;
    int spentInt = spent.toInt();
    int totalInt = limit.toInt();

    return GestureDetector(
      onTap: () => _showBudgetEditDialog(
        '$name Budget',
        limit,
        (val) => BudgetService.updateCategoryBudget(name, val),
      ),
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                    SizedBox(width: 10),
                    Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                  ],
                ),
                RichText(
                  text: TextSpan(
                    text: '\$$spentInt ',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                    children: [
                      TextSpan(text: '/ \$$totalInt', style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.normal, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Stack(
              children: [
                Container(height: 6, decoration: BoxDecoration(color: Color(0xFFEEEEEB), borderRadius: BorderRadius.circular(3))),
                FractionallySizedBox(
                  widthFactor: percent.clamp(0.0, 1.0),
                  child: Container(height: 6, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text('${(percent * 100).toInt()}% used', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
