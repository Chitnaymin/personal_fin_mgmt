import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import 'package:flutter_fin_pwa/models/transaction_model.dart';
import 'package:flutter_fin_pwa/services/firestore_service.dart';
import 'package:flutter_fin_pwa/services/settings_provider.dart';
import 'package:flutter_fin_pwa/models/currency_model.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final selectedCurrency = settingsProvider.selectedCurrency;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: StreamBuilder<List<FinancialTransaction>>(
        stream: firestoreService.getTransactions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                "No transactions yet.\nClick the '+' button to add one!",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final transactions = snapshot.data!;
          final now = DateTime.now();
          final currentMonthTransactions = transactions
              .where((t) =>
                  t.date.month == now.month && t.date.year == now.year)
              .toList();
          double totalIncome = currentMonthTransactions
              .where((t) => t.type == 'income')
              .fold(0.0, (sum, item) => sum + item.amount);
          double totalOutcome = currentMonthTransactions
              .where((t) => t.type == 'outcome')
              .fold(0.0, (sum, item) => sum + item.amount);

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildSummaryCard(totalIncome, totalOutcome, selectedCurrency),
              const SizedBox(height: 20),
              _buildBudgetCard(
                  firestoreService, totalOutcome, selectedCurrency),
              const SizedBox(height: 20),
              
              const Text("Spending by Category",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              SizedBox(
                  height: 200,
                  child: _buildCategoryPieChart(currentMonthTransactions)),
              
              const SizedBox(height: 20),
              
              const Text("Spending by Person",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              SizedBox(
                  height: 200,
                  child: _buildPersonPieChart(currentMonthTransactions)),

              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(
      double income, double outcome, Currency selectedCurrency) {
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

  Widget _summaryItem(
      String title, double amount, Color color, Currency selectedCurrency) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        const SizedBox(height: 4),
        Text(
          NumberFormat.currency(
                  locale: selectedCurrency.locale,
                  symbol: selectedCurrency.symbol)
              .format(amount),
          style: TextStyle(
              color: color, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildBudgetCard(FirestoreService service, double totalOutcome,
      Currency selectedCurrency) {
    return StreamBuilder<DocumentSnapshot>(
      stream: service.getBudget(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data?.data() == null) {
          return const Card(
              child: ListTile(title: Text("Set your monthly budget in Settings.")));
        }
        final data = snapshot.data!.data() as Map<String, dynamic>;
        final monthlyBudget = (data['monthlyBudget'] ?? 0.0).toDouble();
        
        if (monthlyBudget <= 0) {
           return const Card(
              child: ListTile(
                leading: Icon(Icons.track_changes),
                title: Text("Set your monthly budget in Settings to track progress.")
              )
            );
        }
        
        final budgetLeft = monthlyBudget - totalOutcome;

        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Monthly Budget",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: totalOutcome / monthlyBudget,
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(5),
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    totalOutcome > monthlyBudget ? Colors.red : Colors.green
                  ),
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

  Widget _buildCategoryPieChart(List<FinancialTransaction> transactions) {
    final spendingByCategory = <String, double>{};
    transactions
        .where((t) => t.type == 'outcome')
        .forEach((t) {
      spendingByCategory.update(t.category, (value) => value + t.amount,
          ifAbsent: () => t.amount);
    });

    if (spendingByCategory.isEmpty) {
      return const Center(child: Text("No expenses to show."));
    }

    final pieChartSections = spendingByCategory.entries.map((entry) {
      return PieChartSectionData(
        value: entry.value,
        title: entry.key,
        radius: 80,
        titleStyle: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white, shadows: [Shadow(blurRadius: 2)]),
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

  Widget _buildPersonPieChart(List<FinancialTransaction> transactions) {
    final spendingByPerson = <String, double>{};
    transactions
        .where((t) => t.type == 'outcome')
        .forEach((t) {
      spendingByPerson.update(t.person, (value) => value + t.amount,
          ifAbsent: () => t.amount);
    });

    if (spendingByPerson.isEmpty) {
      return const Center(child: Text("No expenses to show."));
    }

    final List<Color> chartColors = [
      Colors.blueAccent,
      Colors.redAccent,
      Colors.greenAccent,
      Colors.orangeAccent,
      Colors.purpleAccent,
      Colors.tealAccent
    ];

    int colorIndex = 0;
    final pieChartSections = spendingByPerson.entries.map((entry) {
      final sectionColor = chartColors[colorIndex % chartColors.length];
      colorIndex++;
      return PieChartSectionData(
        color: sectionColor,
        value: entry.value,
        title: '${entry.key}\n${entry.value.toStringAsFixed(0)}',
        radius: 80,
        titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [Shadow(blurRadius: 2)]),
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