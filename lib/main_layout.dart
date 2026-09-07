import 'package:flutter/material.dart';
import 'dashboard.dart';
import 'budget_config.dart';
import 'favorites.dart';
import 'settings.dart';
import 'log_expense.dart';

class MainLayout extends StatefulWidget {
  final int initialIndex;
  MainLayout({this.initialIndex = 0});

  @override
  _MainLayoutState createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  final List<Widget> _pages = [
    DashboardScreen(),
    BudgetConfigScreen(),
    FavoritesScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Color(0xFF1A1C19) : Color(0xFFF6F6F6);

    return Scaffold(
      backgroundColor: bgColor, // Match bottom bar color
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomAppBar(
        color: bgColor,
        elevation: 0,
        child: Container(
          height: 60,
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.home_filled, color: _currentIndex == 0 ? Color(0xFF1E6E43) : Colors.grey[400], size: 28),
                onPressed: () => setState(() => _currentIndex = 0),
              ),
              IconButton(
                icon: Icon(Icons.pie_chart, color: _currentIndex == 1 ? Color(0xFF1E6E43) : Colors.grey[400], size: 28),
                onPressed: () => setState(() => _currentIndex = 1),
              ),
              SizedBox(width: 48), // Space for FAB
              IconButton(
                icon: Icon(Icons.bookmark, color: _currentIndex == 2 ? Color(0xFF1E6E43) : Colors.grey[400], size: 28),
                onPressed: () => setState(() => _currentIndex = 2),
              ),
              IconButton(
                icon: Icon(Icons.settings, color: _currentIndex == 3 ? Color(0xFF1E6E43) : Colors.grey[400], size: 28),
                onPressed: () => setState(() => _currentIndex = 3),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Container(
        height: 60,
        width: 60,
        child: FloatingActionButton(
          backgroundColor: Color(0xFF1E6E43),
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          child: Icon(Icons.add, color: Colors.white, size: 30),
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => LogExpenseScreen()));
          },
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
