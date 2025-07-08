import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_fin_pwa/models/currency_model.dart';
import 'package:flutter_fin_pwa/services/auth_service.dart';
import 'package:flutter_fin_pwa/services/firestore_service.dart';
import 'package:flutter_fin_pwa/services/settings_provider.dart';
import 'package:flutter_fin_pwa/theme/app_themes.dart';
import 'package:flutter_fin_pwa/screens/main/manage_categories_page.dart';
import 'package:flutter_fin_pwa/screens/main/manage_people_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _monthlyBudgetController = TextEditingController();
  final _yearlyBudgetController = TextEditingController();
  final _firestoreService = FirestoreService();

  bool _isPageLoading = true;
  bool _isSavingBudget = false;

  @override
  void initState() {
    super.initState();
    _loadBudgets();
  }

  void _loadBudgets() {
    _firestoreService.getBudget().first.then((snapshot) {
      if (mounted) {
        if (snapshot.exists && snapshot.data() != null) {
          final data = snapshot.data() as Map<String, dynamic>;
          _monthlyBudgetController.text = (data['monthlyBudget'] ?? 0.0).toStringAsFixed(2);
          _yearlyBudgetController.text = (data['yearlyBudget'] ?? 0.0).toStringAsFixed(2);
        }
        setState(() {
          _isPageLoading = false;
        });
      }
    });
  }

  void _saveBudgets() {
    setState(() => _isSavingBudget = true);
    final monthly = double.tryParse(_monthlyBudgetController.text) ?? 0.0;
    final yearly = double.tryParse(_yearlyBudgetController.text) ?? 0.0;
    _firestoreService.saveBudget(monthly, yearly).then((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Budget saved successfully!')),
        );
      }
    }).catchError((error) {
      if(mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save budget: $error')),
        );
      }
    }).whenComplete(() {
      if (mounted) {
        setState(() => _isSavingBudget = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: _isPageLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildSectionTitle('Preferences'),
                const SizedBox(height: 16),
                DropdownButtonFormField<Currency>(
                  value: settingsProvider.selectedCurrency,
                  decoration: const InputDecoration(labelText: 'Currency', border: OutlineInputBorder()),
                  items: supportedCurrencies.map((Currency currency) {
                    return DropdownMenuItem<Currency>(value: currency, child: Text('${currency.name} (${currency.symbol})'));
                  }).toList(),
                  onChanged: (Currency? newCurrency) {
                    if (newCurrency != null) {
                      settingsProvider.updateCurrency(newCurrency);
                    }
                  },
                ),
                const SizedBox(height: 16),
                // --- THEME SELECTOR DROPDOWN ---
                DropdownButtonFormField<AppTheme>(
                  value: settingsProvider.appTheme,
                  decoration: const InputDecoration(labelText: 'App Theme', border: OutlineInputBorder()),
                  items: AppTheme.values.map((AppTheme theme) {
                    return DropdownMenuItem<AppTheme>(
                      value: theme,
                      child: Text(getThemeName(theme)),
                    );
                  }).toList(),
                  onChanged: (AppTheme? newTheme) {
                    if (newTheme != null) {
                      // This call updates the state and triggers the UI change
                      settingsProvider.updateTheme(newTheme);
                    }
                  },
                ),
                const SizedBox(height: 16),
                _buildNavigationTile(
                  'Customize Categories',
                  () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageCategoriesPage())),
                ),
                _buildNavigationTile(
                  'Manage People',
                  () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ManagePeoplePage())),
                ),

                const Divider(height: 40),

                _buildSectionTitle('Budget Goals'),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _monthlyBudgetController,
                  decoration: InputDecoration(labelText: 'Monthly Budget', border: const OutlineInputBorder(), prefixText: '${settingsProvider.selectedCurrency.symbol} '),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _yearlyBudgetController,
                  decoration: InputDecoration(labelText: 'Yearly Budget', border: const OutlineInputBorder(), prefixText: '${settingsProvider.selectedCurrency.symbol} '),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size.fromHeight(50),
                  ),
                  onPressed: _isSavingBudget ? null : _saveBudgets,
                  child: _isSavingBudget
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save Budget'),
                ),

                const Divider(height: 40),

                _buildSectionTitle('Account'),
                 const SizedBox(height: 8),
                ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Logout'),
                  onTap: () {
                    Provider.of<AuthService>(context, listen: false).signOut();
                  },
                )
              ],
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.bold,
      ),
    );
  }
  
  Widget _buildNavigationTile(String title, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}