import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'expense_service.dart';
import 'budget_service.dart';
import 'auth_service.dart';
import 'package:provider/provider.dart';
import 'expense_detail.dart';
import 'currency_service.dart';
import 'local_storage_service.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {

  @override
  Widget build(BuildContext context) {
    final currencyService = Provider.of<CurrencyService>(context);
    final currencySymbol = currencyService.currencySymbol;

    return StreamBuilder<List<ExpenseModel>>(
      stream: ExpenseService.getExpensesStream(limit: 50),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: Color(0xFF1A1C19),
            body: Center(child: Text("Error: ${snapshot.error}", style: TextStyle(color: Colors.red, fontSize: 16))),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return Scaffold(
            backgroundColor: Color(0xFF1A1C19),
            body: Center(child: CircularProgressIndicator(color: Color(0xFF1E6E43))),
          );
        }

        final expenses = snapshot.data ?? [];
        
        double totalIncome = currencyService.convert(ExpenseService.calcMonthlyIncome(expenses));
        double totalExpense = currencyService.convert(ExpenseService.calcMonthlyExpenses(expenses));
        double balance = totalIncome - totalExpense;
        
        final currencyFormat = NumberFormat.currency(symbol: currencySymbol, decimalDigits: 2);
        
        String balanceStr = balance.toStringAsFixed(2).replaceAll('-', '');
        List<String> balanceParts = balanceStr.split('.');
        String bDollars = '${balance < 0 ? "-" : ""}$currencySymbol${balanceParts[0]}';
        String bCents = '.${balanceParts[1]}';

        return StreamBuilder<BudgetModel>(
          stream: BudgetService.getBudgetStream(),
          builder: (context, budgetSnapshot) {
            double monthlyLimit = 1000.0;
            if (budgetSnapshot.hasData && budgetSnapshot.data != null) {
              monthlyLimit = currencyService.convert(budgetSnapshot.data!.monthlyLimit);
            }
            
            int budgetPercent = 0;
            if (monthlyLimit > 0) {
              budgetPercent = ((totalExpense / monthlyLimit) * 100).clamp(0, 100).toInt();
            }

            return Scaffold(
              backgroundColor: Color(0xFF1A1C19),
              body: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    // ── TOP DARK SECTION ──
                    Padding(
                      padding: EdgeInsets.fromLTRB(22, 18, 22, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Row with Logo
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  // App Logo
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(13),
                                      image: DecorationImage(
                                        image: AssetImage('assets/images/app_logo.png'),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'GOOD EVENING',
                                        style: TextStyle(
                                          color: Color(0xFF7A7D78),
                                          fontSize: 10,
                                          letterSpacing: 1.2,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(height: 3),
                                      Row(
                                        children: [
                                          Text(
                                            "${AuthService.firstName} ",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              // Notification bell with green dot
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Color(0xFF2A2D29),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Icon(Icons.notifications_none_rounded, color: Colors.white, size: 22),
                                  ),
                                  Positioned(
                                    top: 6,
                                    right: 6,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: Color(0xFF4CAF50),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Color(0xFF1A1C19), width: 1.5),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 28),

                          // Total Balance Card
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: Color(0xFF252724),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: Color(0xFF333533), width: 1),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'TOTAL BALANCE',
                                  style: TextStyle(
                                    color: Color(0xFF7A7D78),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                SizedBox(height: 10),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      bDollars,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 38,
                                        fontWeight: FontWeight.bold,
                                        height: 1,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 5.0),
                                      child: Text(
                                        ' $bCents',
                                        style: TextStyle(color: Color(0xFF7A7D78), fontSize: 18),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 22),
                                Row(
                                  children: [
                                    // Income
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'INCOME',
                                            style: TextStyle(
                                              color: Color(0xFF7A7D78),
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                          SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Icon(Icons.trending_up, color: Color(0xFF4CAF50), size: 15),
                                              SizedBox(width: 4),
                                              Flexible(
                                                child: Text(
                                                  currencyFormat.format(totalIncome),
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(height: 28, width: 1, color: Color(0xFF3A3D39)),
                                    SizedBox(width: 16),
                                    // Expenses
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'EXPENSES',
                                            style: TextStyle(
                                              color: Color(0xFF7A7D78),
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                          SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Icon(Icons.trending_down, color: Colors.redAccent, size: 15),
                                              SizedBox(width: 4),
                                              Flexible(
                                                child: Text(
                                                  currencyFormat.format(totalExpense),
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(height: 28, width: 1, color: Color(0xFF3A3D39)),
                                    SizedBox(width: 16),
                                    // Budget
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'BUDGET',
                                            style: TextStyle(
                                              color: Color(0xFF7A7D78),
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                          SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Icon(Icons.pie_chart_rounded, color: Color(0xFF4CAF50), size: 15),
                                              SizedBox(width: 4),
                                              Text(
                                                '$budgetPercent%',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── BUDGET ALERT BANNER ──
                    if (budgetPercent >= 80 && LocalStorageService.budgetAlerts)
                      Container(
                        width: double.infinity,
                        margin: EdgeInsets.only(left: 22, right: 22, bottom: 20),
                        padding: EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Budget Alert: You have used $budgetPercent% of your monthly budget.',
                                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // ── BOTTOM WHITE SECTION ──
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
                        child: Column(
                          children: [
                            Padding(
                              padding: EdgeInsets.fromLTRB(22, 26, 22, 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Recent Transactions',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    'See all',
                                    style: TextStyle(
                                      color: Color(0xFF1E6E43),
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: expenses.isEmpty 
                                ? Center(
                                    child: Text(
                                      "No recent transactions", 
                                      style: TextStyle(color: Colors.grey)
                                    )
                                  )
                                : ListView.builder(
                                padding: EdgeInsets.symmetric(horizontal: 22),
                                itemCount: expenses.length,
                                itemBuilder: (context, i) {
                                  final expense = expenses[i];
                                  return Dismissible(
                                    key: Key(expense.id ?? i.toString()),
                                    direction: DismissDirection.endToStart,
                                    background: Container(
                                      margin: EdgeInsets.only(bottom: 12),
                                      padding: EdgeInsets.symmetric(horizontal: 20),
                                      decoration: BoxDecoration(
                                        color: Colors.redAccent,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      alignment: Alignment.centerRight,
                                      child: Icon(Icons.delete, color: Colors.white),
                                    ),
                                    onDismissed: (direction) {
                                      if (expense.id != null) {
                                        ExpenseService.deleteExpense(expense.id!);
                                      }
                                    },
                                    child: Container(
                                      margin: EdgeInsets.only(bottom: 12),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.04),
                                            blurRadius: 12,
                                            offset: Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Material(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        clipBehavior: Clip.antiAlias,
                                        child: InkWell(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => ExpenseDetailScreen(expense: expense),
                                              ),
                                            );
                                          },
                                          highlightColor: Colors.grey.withOpacity(0.3),
                                          splashColor: Color(0xFF1E6E43).withOpacity(0.1),
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                            child: Row(
                                              children: [
                                                Container(
                                              width: 46,
                                              height: 46,
                                              decoration: BoxDecoration(
                                                color: expense.color,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(expense.icon, color: Colors.white, size: 20),
                                            ),
                                            SizedBox(width: 14),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    expense.name,
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 14,
                                                      color: Colors.black87,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  SizedBox(height: 3),
                                                  Text(
                                                    expense.category,
                                                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                                  ),
                                                ],
                                              ),
                                            ),
                                                Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  '${expense.isExpense ? "-" : "+"}${currencyFormat.format(currencyService.convert(expense.amount))}',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                    color: expense.isExpense ? Colors.black87 : Colors.green,
                                                  ),
                                                ),
                                                SizedBox(height: 3),
                                                Text(
                                                  ExpenseService.formatDate(expense.date),
                                                  style: TextStyle(color: Colors.grey[400], fontSize: 11),
                                                ),
                                              ],
                                            ),
                                            SizedBox(width: 6),
                                            Icon(Icons.chevron_right, color: Colors.grey[300], size: 18),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
