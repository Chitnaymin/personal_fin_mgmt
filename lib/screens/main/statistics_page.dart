import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
// ignore: unused_import
import 'package:collection/collection.dart';

import 'package:flutter_fin_pwa/models/transaction_model.dart';
import 'package:flutter_fin_pwa/services/firestore_service.dart';
import 'package:flutter_fin_pwa/services/settings_provider.dart';
import 'package:flutter_fin_pwa/models/currency_model.dart';

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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
      ),
      body: StreamBuilder<List<FinancialTransaction>>(
        stream: firestoreService.getTransactions(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final allTransactions = snapshot.data ?? [];
          final filteredTransactions = _filterTransactions(allTransactions, _selectedPeriod);
          final currency = settings.selectedCurrency;

          double totalIncome = filteredTransactions.where((t) => t.type == 'income').fold(0.0, (sum, t) => sum + t.amount);
          double totalExpense = filteredTransactions.where((t) => t.type == 'outcome').fold(0.0, (sum, t) => sum + t.amount);
          
          final topSpendingCategories = _getTopSpendingCategories(filteredTransactions);

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildTimePeriodSelector(),
              const SizedBox(height: 24),
              _buildSummaryCards(totalIncome, totalExpense, currency),
              const SizedBox(height: 24),
              Text('Top Spending Categories', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              _buildTopSpendingList(topSpendingCategories, currency),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTimePeriodSelector() {
    final List<String> periods = ['Week', 'Month', 'Year'];
    return Center(
      child: ToggleButtons(
        isSelected: TimePeriod.values.map((p) => p == _selectedPeriod).toList(),
        onPressed: (int index) {
          setState(() {
            _selectedPeriod = TimePeriod.values[index];
          });
        },
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade600,
        selectedColor: Colors.white,
        fillColor: Theme.of(context).colorScheme.primary,
        renderBorder: false,
        children: periods.map((period) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Text(period, style: const TextStyle(fontWeight: FontWeight.bold)),
        )).toList(),
      ),
    );
  }

  Widget _buildSummaryCards(double income, double expense, Currency currency) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Income',
                amount: NumberFormat.currency(locale: currency.locale, symbol: currency.symbol).format(income),
                color: Colors.green,
                backgroundColor: Colors.green.withOpacity(0.1),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                title: 'Expenses',
                amount: NumberFormat.currency(locale: currency.locale, symbol: currency.symbol).format(expense),
                color: Colors.red,
                backgroundColor: Colors.red.withOpacity(0.1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildMetricCard(
          title: 'Net Savings',
          amount: NumberFormat.currency(locale: currency.locale, symbol: currency.symbol).format(income - expense),
          color: Colors.blue,
          backgroundColor: Colors.blue.withOpacity(0.1),
        ),
      ],
    );
  }
  
  Widget _buildMetricCard({required String title, required String amount, required Color color, required Color backgroundColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text(amount, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTopSpendingList(List<MapEntry<String, double>> topSpending, Currency currency) {
    if (topSpending.isEmpty) {
      return const Card(child: Padding(padding: EdgeInsets.all(24.0), child: Center(child: Text("No expenses in this period."))));
    }
    return Card(
      child: Column(
        children: topSpending.map((entry) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 18.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  entry.key,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  NumberFormat.currency(locale: currency.locale, symbol: currency.symbol).format(entry.value),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

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

  List<MapEntry<String, double>> _getTopSpendingCategories(List<FinancialTransaction> transactions) {
    final Map<String, double> spending = {};
    transactions.where((t) => t.type == 'outcome').forEach((t) {
      spending.update(t.category, (value) => value + t.amount, ifAbsent: () => t.amount);
    });
    final sortedEntries = spending.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sortedEntries.take(5).toList();
  }
}