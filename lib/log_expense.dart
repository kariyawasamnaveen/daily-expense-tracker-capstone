import 'package:flutter/material.dart';
import 'expense_service.dart';
import 'main_layout.dart';
import 'constants/app_categories.dart';
import 'utils/app_snackbar.dart';

class LogExpenseScreen extends StatefulWidget {
  @override
  _LogExpenseScreenState createState() => _LogExpenseScreenState();
}

class _LogExpenseScreenState extends State<LogExpenseScreen> {
  // ── State ──────────────────────────────────────────────────────────────────
  int _selectedCategoryIndex = 0;
  bool _isExpense = true; // true = Expense, false = Income
  bool _isSaving = false;
  DateTime _selectedDate = DateTime.now();
  String _selectedPayment = 'Cash';

  final List<String> _paymentMethods = ['Cash', 'Visa Card', 'Master Card', 'Bank Transfer'];

  final TextEditingController _amountCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  // ── Save to Firestore ──────────────────────────────────────────────────────
  Future<void> _saveExpense() async {
    final amountText = _amountCtrl.text.trim();
    final desc = _descCtrl.text.trim();

    if (amountText.isEmpty) {
      AppSnackBar.showError(context, 'Please enter an amount');
      return;
    }
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      AppSnackBar.showError(context, 'Please enter a valid amount');
      return;
    }
    if (desc.isEmpty) {
      AppSnackBar.showError(context, 'Please enter a description');
      return;
    }

    setState(() => _isSaving = true);

    final cat = AppCategories.all[_selectedCategoryIndex];
    final expense = ExpenseModel(
      name: desc,
      category: cat['label'],
      amount: amount,
      date: _selectedDate,
      iconName: cat['iconName'],
      colorValue: (cat['color'] as Color).value,
      notes: _notesCtrl.text.trim(),
      isExpense: _isExpense,
      paymentMethod: _selectedPayment,
    );

    try {
      await ExpenseService.addExpense(expense);
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => MainLayout(initialIndex: 0)),
        (route) => false,
      );
    } catch (e) {
      AppSnackBar.showError(context, 'Failed to save. Please try again.');
      setState(() => _isSaving = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: ColorScheme.dark(primary: Color(0xFF1E6E43)),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  String _formatDate(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
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
              width: 38, height: 38,
              decoration: BoxDecoration(color: Color(0xFFECECE9), shape: BoxShape.circle),
              child: Icon(Icons.arrow_back, color: Colors.black87, size: 20),
            ),
          ),
        ),
        title: Text('Log Expense', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Amount Card ──
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Color(0xFF1A1C19),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                children: [
                  Text('AMOUNT', style: TextStyle(color: Color(0xFF7A7D78), fontSize: 10, letterSpacing: 1)),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('\$', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                      SizedBox(width: 4),
                      IntrinsicWidth(
                        child: TextField(
                          controller: _amountCtrl,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            hintText: '0.00',
                            hintStyle: TextStyle(color: Color(0xFF4A4D49), fontSize: 36, fontWeight: FontWeight.bold),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  // Expense / Income toggle
                  Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Color(0xFF252724),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildToggleBtn('Expense', true),
                        SizedBox(width: 4),
                        _buildToggleBtn('Income', false),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),

            // ── Category ──
            _sectionLabel('CATEGORY'),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(AppCategories.all.length, (i) => _buildCatIcon(i)),
            ),
            SizedBox(height: 24),

            // ── Description ──
            _sectionLabel('DESCRIPTION'),
            SizedBox(height: 8),
            _buildInputField(
              controller: _descCtrl,
              hint: 'e.g. Nobu Restaurant - dinner',
              icon: Icons.edit_outlined,
            ),
            SizedBox(height: 16),

            // ── Date row ──
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionLabel('DATE'),
                      SizedBox(height: 8),
                      GestureDetector(
                        onTap: _pickDate,
                        child: Container(
                          padding: EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: Offset(0, 2))],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_formatDate(_selectedDate), style: TextStyle(fontSize: 13, color: Colors.black87)),
                              Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionLabel('PAYMENT'),
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: Offset(0, 2))],
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedPayment,
                            icon: Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey),
                            isExpanded: true,
                            style: TextStyle(fontSize: 13, color: Colors.black87),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedPayment = newValue;
                                });
                              }
                            },
                            items: _paymentMethods.map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // ── Notes ──
            _sectionLabel('NOTES (optional)'),
            SizedBox(height: 8),
            _buildInputField(
              controller: _notesCtrl,
              hint: 'Business dinner with clients...',
              icon: Icons.notes_outlined,
              maxLines: 3,
            ),
            SizedBox(height: 30),
          ],
        ),
      ),

      // ── Save button ──
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 10, 20, 10),
          child: SizedBox(
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1E6E43),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              onPressed: _isSaving ? null : _saveExpense,
              child: _isSaving
                  ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(
                      _isExpense ? 'Save Expense' : 'Save Income',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _buildToggleBtn(String label, bool isExpenseBtn) {
    final isSelected = _isExpense == isExpenseBtn;
    return GestureDetector(
      onTap: () => setState(() => _isExpense = isExpenseBtn),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 22, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF1E6E43) : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[600],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildCatIcon(int index) {
    final cat = AppCategories.all[index];
    final bool isSel = _selectedCategoryIndex == index;
    final Color col = cat['color'];
    return GestureDetector(
      onTap: () => setState(() => _selectedCategoryIndex = index),
      child: Column(
        children: [
          AnimatedContainer(
            duration: Duration(milliseconds: 200),
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isSel ? col : col.withOpacity(0.12),
              shape: BoxShape.circle,
              boxShadow: isSel
                  ? [BoxShadow(color: col.withOpacity(0.4), blurRadius: 10, offset: Offset(0, 4))]
                  : [],
            ),
            child: Icon(cat['icon'], color: isSel ? Colors.white : col, size: 22),
          ),
          SizedBox(height: 6),
          Text(
            cat['label'],
            style: TextStyle(fontSize: 11, color: isSel ? Colors.black87 : Colors.grey[500], fontWeight: isSel ? FontWeight.bold : FontWeight.normal),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[500], letterSpacing: 0.8),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.grey[400], size: 20),
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Color(0xFF1E6E43), width: 1.5),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      ),
    );
  }
}
