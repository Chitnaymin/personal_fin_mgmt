import 'package:flutter/material.dart';
import 'package:flutter_fin_pwa/screens/main/manage_categories_page.dart';
import 'package:flutter_fin_pwa/screens/main/manage_people_page.dart';
import 'package:provider/provider.dart';

import 'package:flutter_fin_pwa/models/currency_model.dart';
import 'package:flutter_fin_pwa/services/auth_service.dart';
import 'package:flutter_fin_pwa/services/firestore_service.dart';
import 'package:flutter_fin_pwa/services/settings_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _monthlyBudgetController = TextEditingController();
  final _yearlyBudgetController = TextEditingController();
  final _firestoreService = FirestoreService();
  bool _isLoading = true;

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
          _monthlyBudgetController.text = (data['monthlyBudget'] ?? 0.0).toString();
          _yearlyBudgetController.text = (data['yearlyBudget'] ?? 0.0).toString();
        }
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  void _saveBudgets() {
    setState(() => _isSavingBudget = true); // Start saving indicator
    final monthly = double.tryParse(_monthlyBudgetController.text) ?? 0.0;
    final yearly = double.tryParse(_yearlyBudgetController.text) ?? 0.0;
    _firestoreService.saveBudget(monthly, yearly).then((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Budget saved successfully!')),
        );
      }
    }).whenComplete(() {
      if (mounted) {
        setState(() => _isSavingBudget = false); // Stop saving indicator
      }
    });
  }
  
  // New state for the save budget button
  bool _isSavingBudget = false;

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                const Text('Preferences', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                const Divider(height: 40),
                const Text('Budget Goals', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _monthlyBudgetController,
                  decoration: InputDecoration(labelText: 'Monthly Budget', border: const OutlineInputBorder(), prefixText: '${settingsProvider.selectedCurrency.symbol} '),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _yearlyBudgetController,
                  decoration: InputDecoration(labelText: 'Yearly Budget', border: const OutlineInputBorder(), prefixText: '${settingsProvider.selectedCurrency.symbol} '),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 24),
                // --- MODIFIED BUTTON ---
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
                // Just below the Currency Dropdown, before the Divider
                ListTile(
                  title: const Text('Customize Categories'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ManageCategoriesPage()),
                    );
                  },
                ),
                ListTile(
                  title: const Text('Manage People'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ManagePeoplePage()),
                    );
                  },
                ),
                const Divider(height: 40),
                ListTile(
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
}