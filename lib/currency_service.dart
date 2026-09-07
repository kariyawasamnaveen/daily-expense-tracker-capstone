import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'local_storage_service.dart';

class CurrencyService extends ChangeNotifier {
  Map<String, dynamic> _rates = {};
  bool _isLoading = false;
  String _error = '';

  Map<String, dynamic> get rates => _rates;
  bool get isLoading => _isLoading;
  String get error => _error;

  String get currentCurrency => LocalStorageService.currency;

  CurrencyService() {
    fetchRates();
  }

  Future<void> fetchRates() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final response = await http.get(Uri.parse('https://open.er-api.com/v6/latest/USD'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _rates = data['rates'];
      } else {
        _error = 'Failed to load rates';
      }
    } catch (e) {
      _error = 'Error fetching rates: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Converts a USD amount to the currently selected currency.
  double convert(double amountInUSD) {
    if (_rates.isEmpty || !_rates.containsKey(currentCurrency)) {
      return amountInUSD; // Fallback to original
    }
    double rate = (_rates[currentCurrency] as num?)?.toDouble() ?? 1.0;
    return amountInUSD * rate;
  }

  /// Returns the symbol for the current currency.
  String get currencySymbol {
    switch (currentCurrency) {
      case 'USD': return '\$';
      case 'LKR': return 'Rs';
      case 'EUR': return '€';
      case 'GBP': return '£';
      case 'AUD': return 'A\$';
      case 'INR': return '₹';
      default: return '\$';
    }
  }

  /// Updates the selected currency and saves it to local storage.
  Future<void> updateCurrency(String newCurrency) async {
    await LocalStorageService.saveCurrency(newCurrency);
    notifyListeners();
  }
}
