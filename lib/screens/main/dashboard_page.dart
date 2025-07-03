import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import 'package:flutter_fin_pwa/models/transaction_model.dart';
import 'package:flutter_fin_pwa/services/firestore_service.dart';
import 'package:flutter_fin_pwa/services/settings_provider.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();
    // Get the selected currency from the provider
    final selectedCurrency = Provider.of<SettingsProvider>(context).selectedCurrency;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: StreamBuilder<List<FinancialTransaction>>(
        stream: firestoreService.getTransactions(),
        builder: (context, snapshot) {
          // ... (builder logic remains the same)
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No transactions yet. Add one to see your dashboard."));
          }

          final transactions = snapshot.data!;
          final now = DateTime.now();
          final currentMonthTransactions = transactions.where((t) => t.date.month == now.month && t.date.year == now.year).toList();
          double totalIncome = currentMonthTransactions.where((t) => t.type == 'income').fold(0.0, (sum, item) => sum + item.amount);
          double totalOutcome = currentMonthTransactions.where((t) => t.type == 'outcome').fold(0.0, (sum, item) => sum + item.amount);

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildSummaryCard(totalIncome, totalOutcome, selectedCurrency),
              const SizedBox(height: 20),
              _buildBudgetCard(firestoreService, totalOutcome, selectedCurrency),
              const SizedBox(height: 20),
              const Text("Spending by Category", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              SizedBox(height: 200, child: _buildPieChart(currentMonthTransactions)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(double income, double outcome, dynamic selectedCurrency) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _summaryItem('Income', income, Colors.green, selectedCurrency),
            _summaryItem('Outcome', outcome, Colors.red, selectedCurrency),
            _summaryItem('Balance', income - outcome, Colors.blue, selectedCurrency),
          ],
        ),
      ),
    );
  }
  
  Widget _summaryItem(String title, double amount, Color color, dynamic selectedCurrency) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        const SizedBox(height: 4),
        Text(
          NumberFormat.currency(locale: selectedCurrency.locale, symbol: selectedCurrency.symbol).format(amount),
          style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildBudgetCard(FirestoreService service, double totalOutcome, dynamic selectedCurrency) {
    return StreamBuilder<DocumentSnapshot>(
      stream: service.getBudget(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data?.data() == null) {
          return const Card(child: ListTile(title: Text("Set your monthly budget in Settings.")));
        }
        final data = snapshot.data!.data() as Map<String, dynamic>;
        final monthlyBudget = (data['monthlyBudget'] ?? 0.0).toDouble();
        final budgetLeft = monthlyBudget - totalOutcome;

        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Monthly Budget", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: monthlyBudget > 0 ? totalOutcome / monthlyBudget : 0,
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(5),
                ),
                const SizedBox(height: 10),
                Text("Left to spend: ${NumberFormat.currency(locale: selectedCurrency.locale, symbol: selectedCurrency.symbol).format(budgetLeft)}"),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildPieChart(List<FinancialTransaction> transactions) {
    final spendingByCategory = <String, double>{};
    transactions.where((t) => t.type == 'outcome').forEach((t) {
      spendingByCategory.update(t.category, (value) => value + t.amount, ifAbsent: () => t.amount);
    });

    if (spendingByCategory.isEmpty) {
      return const Center(child: Text("No expenses to show."));
    }

    final pieChartSections = spendingByCategory.entries.map((entry) {
      return PieChartSectionData(
        value: entry.value,
        title: entry.key,
        radius: 80,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();

    return PieChart(
      PieChartData(
        sections: pieChartSections,
        centerSpaceRadius: 40,
        sectionsSpace: 2,
      ),
    );
  }
}