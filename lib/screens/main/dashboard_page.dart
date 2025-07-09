import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';

import 'package:flutter_fin_pwa/models/transaction_model.dart';
import 'package:flutter_fin_pwa/services/firestore_service.dart';
import 'package:flutter_fin_pwa/services/settings_provider.dart';
import 'package:flutter_fin_pwa/models/currency_model.dart';
import 'package:flutter_fin_pwa/screens/main/transactions_page.dart';
import 'package:flutter_fin_pwa/screens/main/add_transaction_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: false, // Aligns title to the left
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
          final settingsProvider = Provider.of<SettingsProvider>(context);
          final currency = settingsProvider.selectedCurrency;

          final now = DateTime.now();
          final currentMonthTransactions = transactions.where((t) => t.date.month == now.month && t.date.year == now.year).toList();
          
          double totalIncome = currentMonthTransactions.where((t) => t.type == 'income').fold(0.0, (sum, item) => sum + item.amount);
          double totalExpense = currentMonthTransactions.where((t) => t.type == 'outcome').fold(0.0, (sum, item) => sum + item.amount);
          double balance = totalIncome - totalExpense;

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildBalanceCard(context, balance, currency),
              const SizedBox(height: 24),
              _buildSectionHeader(context, 'Quick Stats'),
              _buildQuickStats(currentMonthTransactions, currency),
              const SizedBox(height: 24),
              _buildSectionHeader(context, 'Monthly Budget'),
              _buildBudgetChart(firestoreService, totalExpense, currency),
              const SizedBox(height: 24),

              // --- PIE CHARTS ADDED BACK ---
              _buildSectionHeader(context, 'Spending by Category'),
              _buildCategoryPieChart(currentMonthTransactions),
              const SizedBox(height: 24),
              _buildSectionHeader(context, 'Spending by Person'),
              _buildPersonPieChart(currentMonthTransactions),
              const SizedBox(height: 24),

              _buildSectionHeader(context, 'Recent Activity', onViewAll: () {
                 Navigator.push(context, MaterialPageRoute(builder: (context) => const TransactionsPage()));
              }),
              _buildRecentTransactions(context, transactions.take(4).toList(), currency),
            ],
          );
        },
      ),
    );
  }

  // --- UI HELPER WIDGETS ---

  Widget _buildSectionHeader(BuildContext context, String title, {VoidCallback? onViewAll}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          if (onViewAll != null)
            TextButton(
              onPressed: onViewAll,
              child: const Text('View All'),
            ),
        ],
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

  Widget _buildQuickStats(List<FinancialTransaction> transactions, Currency currency) {
    final expenses = transactions.where((t) => t.type == 'outcome').toList();
    double avgDailySpend = 0;
    String highestSpendingDay = 'N/A';

    if (expenses.isNotEmpty) {
      final daysSoFar = DateTime.now().day;
      final totalSpend = expenses.fold(0.0, (sum, t) => sum + t.amount);
      avgDailySpend = totalSpend / daysSoFar;

      final spendingByDay = groupBy(expenses, (t) => t.date.day);
      if (spendingByDay.isNotEmpty) {
        final topDay = spendingByDay.entries.map((entry) {
          return MapEntry(entry.key, entry.value.fold(0.0, (sum, t) => sum + t.amount));
        }).sorted((a, b) => b.value.compareTo(a.value)).first;
        highestSpendingDay = 'Day ${topDay.key}';
      }
    }

    return Row(
      children: [
        Expanded(child: _buildStatCard('Avg. Daily Spend', NumberFormat.currency(locale: currency.locale, symbol: currency.symbol).format(avgDailySpend), Icons.multiline_chart)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard('Top Spend Day', highestSpendingDay, Icons.calendar_today_outlined)),
      ],
    );
  }
  
  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 28, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetChart(FirestoreService service, double totalExpense, Currency currency) {
    return StreamBuilder<DocumentSnapshot>(
      stream: service.getBudget(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data?.data() == null) {
          return const Card(child: ListTile(title: Text("Set your budget in Settings.")));
        }
        final data = snapshot.data!.data() as Map<String, dynamic>;
        final monthlyBudget = (data['monthlyBudget'] ?? 0.0).toDouble();
        
        if (monthlyBudget <= 0) return const SizedBox.shrink();

        final spentPercentage = (totalExpense / monthlyBudget).clamp(0.0, 1.0);
        final overBudget = totalExpense > monthlyBudget;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Spent: ${NumberFormat.currency(locale: currency.locale, symbol: currency.symbol).format(totalExpense)}'),
                    Text('Budget: ${NumberFormat.currency(locale: currency.locale, symbol: currency.symbol).format(monthlyBudget)}', style: const TextStyle(color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  height: 12,
                  decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Row(
                      children: [
                        FractionallySizedBox(
                          widthFactor: overBudget ? 1.0 : spentPercentage,
                          child: Container(
                            decoration: BoxDecoration(
                              color: overBudget ? Colors.red : Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryPieChart(List<FinancialTransaction> transactions) {
    final spendingByCategory = <String, double>{};
    transactions.where((t) => t.type == 'outcome').forEach((t) {
      spendingByCategory.update(t.category, (value) => value + t.amount, ifAbsent: () => t.amount);
    });

    if (spendingByCategory.isEmpty) return const SizedBox.shrink();

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

  Widget _buildPersonPieChart(List<FinancialTransaction> transactions) {
    final spendingByPerson = <String, double>{};
    transactions.where((t) => t.type == 'outcome').forEach((t) {
      spendingByPerson.update(t.person, (value) => value + t.amount, ifAbsent: () => t.amount);
    });

    if (spendingByPerson.isEmpty) return const SizedBox.shrink();

    final List<Color> chartColors = [Colors.blueAccent, Colors.redAccent, Colors.greenAccent, Colors.orangeAccent, Colors.purpleAccent, Colors.tealAccent];
    int colorIndex = 0;
    
    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sections: spendingByPerson.entries.map((entry) {
            final color = chartColors[colorIndex++ % chartColors.length];
            return PieChartSectionData(
              color: color,
              value: entry.value,
              title: '${entry.key}\n${entry.value.toStringAsFixed(0)}',
              radius: 60,
              titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white, shadows: [Shadow(blurRadius: 2)]),
            );
          }).toList(),
          sectionsSpace: 2,
          centerSpaceRadius: 40,
        ),
      ),
    );
  }

  Widget _buildRecentTransactions(BuildContext context, List<FinancialTransaction> transactions, Currency currency) {
    IconData getIconForCategory(String category) {
      switch (category.toLowerCase()) {
        case 'food': return Icons.fastfood_outlined;
        case 'shopping': return Icons.shopping_cart_outlined;
        case 'transport': return Icons.directions_bus_outlined;
        case 'bills': return Icons.receipt_long_outlined;
        case 'salary': return Icons.work_outline;
        default: return Icons.category_outlined;
      }
    }

    return Column(
      children: transactions.map((transaction) {
        final isIncome = transaction.type == 'income';
        final color = isIncome ? Colors.green : Theme.of(context).colorScheme.primary;
        final amountString = (isIncome ? '+' : '-') + NumberFormat.currency(locale: currency.locale, symbol: currency.symbol).format(transaction.amount);

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(getIconForCategory(transaction.category), size: 20, color: color),
            ),
            title: Text(transaction.category, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(DateFormat.yMMMd().format(transaction.date)),
            trailing: Text(amountString, style: TextStyle(color: isIncome ? Colors.green : Colors.black87, fontWeight: FontWeight.bold)),
             onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => AddTransactionPage(transaction: transaction)));
            },
          ),
        );
      }).toList(),
    );
  }
}