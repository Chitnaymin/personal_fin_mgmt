import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_fin_pwa/models/transaction_model.dart';
import 'package:flutter_fin_pwa/services/firestore_service.dart';
import 'package:flutter_fin_pwa/services/settings_provider.dart';
import 'package:flutter_fin_pwa/models/currency_model.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();
    final currency = Provider.of<SettingsProvider>(context).selectedCurrency;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: false,
      ),
      body: StreamBuilder<List<FinancialTransaction>>(
        stream: firestoreService.getTransactions(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final transactions = snapshot.data ?? [];
          double totalIncome = transactions.where((t) => t.type == 'income').fold(0.0, (sum, t) => sum + t.amount);
          double totalExpense = transactions.where((t) => t.type == 'outcome').fold(0.0, (sum, t) => sum + t.amount);
          double balance = totalIncome - totalExpense;

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildBalanceCard(context, balance, currency),
              const SizedBox(height: 24),
              _buildIncomeExpenseRow(context, totalIncome, totalExpense, currency),
              const SizedBox(height: 24),
              Text('Spending Breakdown', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              _buildSpendingChart(transactions),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context, double balance, Currency currency) {
    return Card(
      color: Theme.of(context).colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current Balance', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white70)),
            const SizedBox(height: 8),
            Text(
              NumberFormat.currency(locale: currency.locale, symbol: currency.symbol).format(balance),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white, fontSize: 32),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomeExpenseRow(BuildContext context, double income, double expense, Currency currency) {
    return Row(
      children: [
        Expanded(child: _buildStatCard(context, 'Income', NumberFormat.currency(locale: currency.locale, symbol: currency.symbol).format(income), Colors.green)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard(context, 'Expense', NumberFormat.currency(locale: currency.locale, symbol: currency.symbol).format(expense), Colors.red)),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String amount, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text(amount, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildSpendingChart(List<FinancialTransaction> transactions) {
    final spendingByCategory = <String, double>{};
    transactions.where((t) => t.type == 'outcome').forEach((t) {
      spendingByCategory.update(t.category, (value) => value + t.amount, ifAbsent: () => t.amount);
    });

    if (spendingByCategory.isEmpty) {
      return const SizedBox(height: 200, child: Center(child: Text("No spending data yet.")));
    }
    
    final List<Color> chartColors = [Colors.pink, Colors.blue, Colors.orange, Colors.purple, Colors.teal, Colors.green];
    int colorIndex = 0;

    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sections: spendingByCategory.entries.map((entry) {
            final color = chartColors[colorIndex++ % chartColors.length];
            return PieChartSectionData(
              value: entry.value,
              color: color,
              title: entry.key,
              radius: 60,
              titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
            );
          }).toList(),
          sectionsSpace: 4,
          centerSpaceRadius: 40,
        ),
      ),
    );
  }
}