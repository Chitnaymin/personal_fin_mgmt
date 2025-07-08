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

  void _showThemeSelectionDialog(BuildContext context, SettingsProvider provider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select App Theme'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: AppTheme.values.length,
              itemBuilder: (BuildContext context, int index) {
                final theme = AppTheme.values[index];
                return RadioListTile<AppTheme>(
                  title: Text(getThemeName(theme)),
                  value: theme,
                  groupValue: provider.appTheme,
                  onChanged: (AppTheme? value) {
                    if (value != null) {
                      provider.updateTheme(value);
                      Navigator.of(context).pop();
                    }
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showCurrencySelectionDialog(BuildContext context, SettingsProvider provider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Currency'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: supportedCurrencies.length,
              itemBuilder: (BuildContext context, int index) {
                final currency = supportedCurrencies[index];
                return RadioListTile<Currency>(
                  title: Text('${currency.name} (${currency.symbol})'),
                  value: currency,
                  groupValue: provider.selectedCurrency,
                  onChanged: (Currency? value) {
                    if (value != null) {
                      provider.updateCurrency(value);
                      Navigator.of(context).pop();
                    }
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use .watch() here to ensure the subtitles update when a selection is made
    final settingsProvider = context.watch<SettingsProvider>();
    final authService = Provider.of<AuthService>(context, listen: false);

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
                Card(
                  child: Column(
                    children: [
                      _buildSettingsTile(context, Icons.color_lens_outlined, 'App Theme', getThemeName(settingsProvider.appTheme), () {
                        _showThemeSelectionDialog(context, settingsProvider);
                      }),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      _buildSettingsTile(context, Icons.attach_money_outlined, 'Currency', '${settingsProvider.selectedCurrency.name} (${settingsProvider.selectedCurrency.symbol})', () {
                        _showCurrencySelectionDialog(context, settingsProvider);
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('Customization'),
                Card(
                  child: Column(
                    children: [
                      _buildSettingsTile(context, Icons.category_outlined, 'Manage Categories', 'Income & Outcome', () {
                         Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageCategoriesPage()));
                      }),
                       const Divider(height: 1, indent: 16, endIndent: 16),
                      _buildSettingsTile(context, Icons.people_outline, 'Manage People', 'Edit members', () {
                         Navigator.push(context, MaterialPageRoute(builder: (_) => const ManagePeoplePage()));
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
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
                    authService.signOut();
                  },
                )
              ],
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8),
      child: Text(
        title,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
      ),
    );
  }
  
  Widget _buildSettingsTile(BuildContext context, IconData icon, String title, String subtitle, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}