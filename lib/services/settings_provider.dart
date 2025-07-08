import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter_fin_pwa/models/currency_model.dart';
import 'package:flutter_fin_pwa/theme/app_themes.dart';
import 'package:flutter_fin_pwa/services/firestore_service.dart';

class SettingsProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  Currency _selectedCurrency = defaultCurrency;
  AppTheme _appTheme = AppTheme.light;

  Currency get selectedCurrency => _selectedCurrency;
  AppTheme get appTheme => _appTheme;

  // --- NEW: Load settings when the provider is created ---
  SettingsProvider() {
    _loadSettings();
  }

  void _loadSettings() {
    _firestoreService.getBudget().listen((DocumentSnapshot snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data() as Map<String, dynamic>;
        
        // Load the theme from Firestore
        final String themeName = data['theme'] ?? 'light';
        // Convert the string name back to our AppTheme enum
        _appTheme = AppTheme.values.firstWhere(
          (e) => e.name == themeName,
          orElse: () => AppTheme.light, // Default to light if not found
        );
        
        // We notify listeners here to update the UI once settings are loaded
        notifyListeners();
      }
    });
  }

  void updateCurrency(Currency newCurrency) {
    if (_selectedCurrency != newCurrency) {
      _selectedCurrency = newCurrency;
      notifyListeners();
      // In the future, you could save the currency preference here too
    }
  }

  void updateTheme(AppTheme newTheme) {
    if (_appTheme != newTheme) {
      _appTheme = newTheme;
      notifyListeners();
      // --- NEW: Save the theme choice to Firestore ---
      // We save the theme by its string name (e.g., 'light', 'dark')
      _firestoreService.saveTheme(newTheme.name);
    }
  }
}