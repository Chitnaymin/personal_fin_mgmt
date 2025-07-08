import 'package:flutter/material.dart';
// ignore: unused_import
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter_fin_pwa/models/currency_model.dart';
import 'package:flutter_fin_pwa/theme/app_themes.dart';
import 'package:flutter_fin_pwa/services/firestore_service.dart';

class SettingsProvider extends ChangeNotifier {
  // --- REMOVED THE OLD INSTANCE ---
  // final FirestoreService _firestoreService = FirestoreService(); // This was the problem

  Currency _selectedCurrency = defaultCurrency;
  AppTheme _appTheme = AppTheme.light;
  bool _isLoading = true;

  Currency get selectedCurrency => _selectedCurrency;
  AppTheme get appTheme => _appTheme;
  bool get isLoading => _isLoading;

  SettingsProvider() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _loadUserSettings();
      } else {
        _resetToDefaults();
      }
    });
  }

  Future<void> _loadUserSettings() async {
    _isLoading = true;
    notifyListeners();

    // Create a fresh instance here to ensure it has the current user's ID
    final firestoreService = FirestoreService();
    final userDoc = await firestoreService.getBudget().first;

    if (userDoc.exists) {
      final data = userDoc.data() as Map<String, dynamic>;
      final themeName = data['selectedTheme'] as String? ?? 'light';
      _appTheme = AppTheme.values.firstWhere(
        (e) => e.name == themeName,
        orElse: () => AppTheme.light,
      );
      final currencyCode = data['selectedCurrencyCode'] as String? ?? 'THB';
      _selectedCurrency = supportedCurrencies.firstWhere(
        (c) => c.code == currencyCode,
        orElse: () => defaultCurrency,
      );
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateTheme(AppTheme newTheme) async {
    if (_appTheme != newTheme) {
      _appTheme = newTheme;
      await _savePreferences();
      notifyListeners();
    }
  }

  Future<void> updateCurrency(Currency newCurrency) async {
    if (_selectedCurrency != newCurrency) {
      _selectedCurrency = newCurrency;
      await _savePreferences();
      notifyListeners();
    }
  }

  Future<void> _savePreferences() async {
    try {
      final firestoreService = FirestoreService();
      // This correctly calls the single, consolidated method.
      await firestoreService.saveUserPreferences(
        _appTheme.name,
        _selectedCurrency.code,
      );
    } catch (e) {
      print("Error saving preferences: $e");
    }
  }
  
  void _resetToDefaults() {
    _appTheme = AppTheme.light;
    _selectedCurrency = defaultCurrency;
    _isLoading = false;
    notifyListeners();
  }
}