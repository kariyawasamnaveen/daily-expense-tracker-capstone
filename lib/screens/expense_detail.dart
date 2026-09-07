import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/expense_service.dart';
import '../services/currency_service.dart';

class ExpenseDetailScreen extends StatelessWidget {
  final ExpenseModel expense;

  const ExpenseDetailScreen({Key? key, required this.expense}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final symbol = Provider.of<CurrencyService>(context).currencySymbol;
    final currencyFormat = NumberFormat.currency(symbol: symbol, decimalDigits: 2);
    final dateFormat = DateFormat('EEEE, d MMMM yyyy · h:mm a');

    return Scaffold(
      backgroundColor: Color(0xFF1A1C19),
      appBar: AppBar(
        backgroundColor: Color(0xFF1A1C19),
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 14.0),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Color(0xFF2A2D29),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.arrow_back, color: Colors.white, size: 20),
            ),
          ),
        ),
        title: Text(
          'Transaction Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: Column(
        children: [
          // ── Top Dark Section ──
          Padding(
            padding: EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Column(
              children: [
                // Icon + Amount
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: expense.color,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(expense.icon, color: Colors.white, size: 34),
                ),
                SizedBox(height: 18),
                Text(
                  expense.name,
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  '${expense.isExpense ? '-' : '+'}${currencyFormat.format(expense.amount)}',
                  style: TextStyle(
                    color: expense.isExpense ? Colors.redAccent : Color(0xFF4CAF50),
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                SizedBox(height: 6),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: expense.isExpense ? Colors.red.withOpacity(0.15) : Colors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    expense.isExpense ? 'Expense' : 'Income',
                    style: TextStyle(
                      color: expense.isExpense ? Colors.redAccent : Color(0xFF4CAF50),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── White Details Section ──
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Color(0xFFF5F5F3),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(24, 28, 24, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DETAILS',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    SizedBox(height: 14),

                    _buildDetailCard([
                      _DetailRow(
                        icon: Icons.category_outlined,
                        label: 'Category',
                        value: expense.category,
                        iconColor: expense.color,
                      ),
                      _DetailRow(
                        icon: Icons.calendar_today_outlined,
                        label: 'Date & Time',
                        value: dateFormat.format(expense.date),
                        iconColor: Color(0xFF1565C0),
                      ),
                      _DetailRow(
                        icon: Icons.payment_outlined,
                        label: 'Payment Method',
                        value: expense.paymentMethod,
                        iconColor: Color(0xFF7B3FA0),
                      ),
                      if (expense.notes.isNotEmpty)
                        _DetailRow(
                          icon: Icons.notes_outlined,
                          label: 'Notes',
                          value: expense.notes,
                          iconColor: Color(0xFFFF6B35),
                          isLast: true,
                        )
                      else
                        _DetailRow(
                          icon: Icons.notes_outlined,
                          label: 'Notes',
                          value: 'No notes added',
                          iconColor: Colors.grey,
                          isLast: true,
                        ),
                    ]),

                    SizedBox(height: 32),

                    // ── Delete Button ──
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFFFF0EE),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.redAccent.withOpacity(0.4), width: 1.5),
                          ),
                        ),
                        icon: Icon(Icons.delete_outline, color: Colors.redAccent),
                        label: Text(
                          'Delete Transaction',
                          style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: Color(0xFF1A1C19),
                              title: Text('Delete?', style: TextStyle(color: Colors.white)),
                              content: Text('Are you sure you want to delete "${expense.name}"?', style: TextStyle(color: Colors.grey[400])),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: Text('Cancel', style: TextStyle(color: Colors.grey)),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: Text('Delete', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true && expense.id != null) {
                            await ExpenseService.deleteExpense(expense.id!);
                            if (context.mounted) Navigator.pop(context);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(List<_DetailRow> rows) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: rows.map((row) {
          return Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: row.iconColor.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(row.icon, color: row.iconColor, size: 18),
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(row.label, style: TextStyle(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.w600)),
                          SizedBox(height: 3),
                          Text(row.value, style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (!row.isLast)
                Divider(height: 1, indent: 66, endIndent: 16, color: Colors.grey[100]),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _DetailRow {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final bool isLast;

  _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    this.isLast = false,
  });
}
