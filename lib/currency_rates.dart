import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'currency_service.dart';

class CurrencyRatesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final currencyService = Provider.of<CurrencyService>(context);
    final rates = currencyService.rates;
    final currentCurrency = currencyService.currentCurrency;
    
    // Map of flags and names for common currencies
    final Map<String, Map<String, String>> currencyMeta = {
      'USD': {'flag': '🇺🇸', 'name': 'US Dollar'},
      'EUR': {'flag': '🇪🇺', 'name': 'Euro'},
      'GBP': {'flag': '🇬🇧', 'name': 'Brit. Pound'},
      'JPY': {'flag': '🇯🇵', 'name': 'Japanese Yen'},
      'CAD': {'flag': '🇨🇦', 'name': 'Canadian \$'},
      'AUD': {'flag': '🇦🇺', 'name': 'Australian \$'},
      'INR': {'flag': '🇮🇳', 'name': 'Indian Rupee'},
      'LKR': {'flag': '🇱🇰', 'name': 'Sri Lankan Rupee'},
    };

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Color(0xFF1A1C19) : Color(0xFFF9F9F8);
    final cardColor = isDark ? Color(0xFF252724) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Live Rates', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
            Row(
              children: [
                CircleAvatar(radius: 3, backgroundColor: Colors.green),
                SizedBox(width: 5),
                Text('Live · Active: $currentCurrency', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(20),
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? Color(0xFF252724) : Color(0xFF1A1C19),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CONVERTER', style: TextStyle(color: Colors.grey[500], fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('From', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            SizedBox(height: 5),
                            Text('1.00', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                            Text('${currencyMeta['USD']?['flag'] ?? ''} USD', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Color(0xFF1E6E43), shape: BoxShape.circle),
                          child: Icon(Icons.swap_horiz, color: Colors.white, size: 20),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('To', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            SizedBox(height: 5),
                            Text(
                              rates[currentCurrency] != null ? rates[currentCurrency]!.toStringAsFixed(2) : '0.00',
                              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            Text('${currencyMeta[currentCurrency]?['flag'] ?? ''} $currentCurrency', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 25),
                    Center(child: Text('1 USD = ${rates[currentCurrency]?.toStringAsFixed(4) ?? '0.00'} $currentCurrency', style: TextStyle(color: Colors.grey[400], fontSize: 10))),
                  ],
                ),
              ),
            ),
            
            Padding(
              padding: EdgeInsets.fromLTRB(20, 10, 20, 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('ALL CURRENCIES (Tap to set as default)', style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            ),

            Container(
              margin: EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20)),
              child: ListView.separated(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: currencyMeta.keys.length,
                separatorBuilder: (context, index) => Divider(height: 1, indent: 60, color: isDark ? Colors.grey[800] : Colors.grey[100]),
                itemBuilder: (context, index) {
                  final code = currencyMeta.keys.elementAt(index);
                  final meta = currencyMeta[code]!;
                  final rate = (rates[code] as num?)?.toDouble() ?? 0.0;
                  final isCurrent = code == currentCurrency;
                  
                  return InkWell(
                    onTap: () {
                      currencyService.updateCurrency(code);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Currency updated to $code'),
                        backgroundColor: Color(0xFF1E6E43),
                      ));
                    },
                    child: Padding(
                      padding: EdgeInsets.all(15),
                      child: Row(
                        children: [
                          Text(meta['flag']!, style: TextStyle(fontSize: 24)),
                          SizedBox(width: 15),
                          Expanded(
                            child: Row(
                              children: [
                                Text(code, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
                                SizedBox(width: 8),
                                Text(meta['name']!, style: TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(rate.toStringAsFixed(4), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
                              if (isCurrent)
                                Text('Active', style: TextStyle(color: Color(0xFF1E6E43), fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          SizedBox(width: 15),
                          Icon(
                            isCurrent ? Icons.check_circle : Icons.circle_outlined,
                            color: isCurrent ? Color(0xFF1E6E43) : Colors.grey[400]
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
