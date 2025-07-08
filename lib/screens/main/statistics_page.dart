import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:flutter_fin_pwa/models/transaction_model.dart';
import 'package:flutter_fin_pwa/services/firestore_service.dart';
import 'package:flutter_fin_pwa/services/settings_provider.dart';

enum TimePeriod { week, month, year }

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  TimePeriod _selectedPeriod = TimePeriod.month;

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
      ),
      body: StreamBuilder<List<FinancialTransaction>>(
        stream: firestoreService.getTransactions(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (snapshot.data!.isEmpty) return const Center(child: Text("No data for statistics yet."));

          final transactions = _filterTransactions(snapshot.data!, _selectedPeriod);
          final currency = settings.selectedCurrency;

          double totalIncome = transactions.where((t) => t.type == 'income').fold(0.0, (sum, t) => sum + t.amount);
          double totalOutcome = transactions.where((t) => t.type == 'outcome').fold(0.0, (sum, t) => sum + t.amount);
          
          final topSpendingCategories = _getTopSpendingCategories(transactions);

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // --- Time Period Selector ---
              Center(
                child: ToggleButtons(
                  isSelected: [
                    _selectedPeriod == TimePeriod.week,
                    _selectedPeriod == TimePeriod.month,
                    _selectedPeriod == TimePeriod.year,
                  ],
                  onPressed: (index) {
                    setState(() {
                      _selectedPeriod = TimePeriod.values[index];
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  children: const [
                    Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Week')),
                    Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Month')),
                    Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Year')),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // --- Key Metrics ---
              Row(
                children: [
                  Expanded(child: _buildMetricCard('Income', totalIncome, Colors.green, currency)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildMetricCard('Expenses', totalOutcome, Colors.red, currency)),
                ],
              ),
              const SizedBox(height: 16),
              _buildMetricCard('Net Savings', totalIncome - totalOutcome, Colors.blue, currency, isLarge: true),
              const SizedBox(height: 24),

              // --- Top Spending Categories ---
              Text('Top Spending Categories', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              if (topSpendingCategories.isEmpty)
                const Text('No expenses in this period.', style: TextStyle(color: Colors.grey))
              else
                Card(
                  child: Column(
                    children: topSpendingCategories.map((entry) {
                      return ListTile(
                        title: Text(entry.key),
                        trailing: Text(
                          NumberFormat.currency(locale: currency.locale, symbol: currency.symbol).format(entry.value),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // Helper method to build metric cards
  Widget _buildMetricCard(String title, double amount, Color color, dynamic currency, {bool isLarge = false}) {
    return Card(
      // ignore: deprecated_member_use
      color: color.withOpacity(0.1),
      elevation: 0,
      child: Padding(
        padding: isLarge ? const EdgeInsets.all(24.0) : const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              NumberFormat.currency(locale: currency.locale, symbol: currency.symbol).format(amount),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: isLarge ? 24 : 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper to filter transactions based on the selected period
  List<FinancialTransaction> _filterTransactions(List<FinancialTransaction> all, TimePeriod period) {
    final now = DateTime.now();
    switch (period) {
      case TimePeriod.week:
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        return all.where((t) => t.date.isAfter(startOfWeek)).toList();
      case TimePeriod.month:
        return all.where((t) => t.date.month == now.month && t.date.year == now.year).toList();
      case TimePeriod.year:
        return all.where((t) => t.date.year == now.year).toList();
    }
  }

  // Helper to calculate top spending categories
  List<MapEntry<String, double>> _getTopSpendingCategories(List<FinancialTransaction> transactions) {
    final Map<String, double> spending = {};
    transactions.where((t) => t.type == 'outcome').forEach((t) {
      spending.update(t.category, (value) => value + t.amount, ifAbsent: () => t.amount);
    });

    final sortedEntries = spending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
      
    return sortedEntries.take(5).toList(); // Return top 5
  }
}