import 'package:flutter/material.dart';
import 'package:flutter_fin_pwa/models/currency_model.dart';

class SettingsProvider extends ChangeNotifier {
  Currency _selectedCurrency = defaultCurrency;

  Currency get selectedCurrency => _selectedCurrency;

  void updateCurrency(Currency newCurrency) {
    if (_selectedCurrency != newCurrency) {
      _selectedCurrency = newCurrency;
      // Tell all listening widgets that they need to rebuild
      notifyListeners();
    }
  }
}