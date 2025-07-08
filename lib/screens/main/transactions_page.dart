import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import 'package:flutter_fin_pwa/models/transaction_model.dart';
import 'package:flutter_fin_pwa/services/firestore_service.dart';
import 'package:flutter_fin_pwa/services/settings_provider.dart';
import 'package:flutter_fin_pwa/screens/main/add_transaction_page.dart';
import 'package:flutter_fin_pwa/models/currency_model.dart';

class TransactionsPage extends StatelessWidget {
  const TransactionsPage({super.key});

IconData _getIconForCategory(String category) {
  // --- 1. Keyword Matching (for common and specific terms) ---
  final String lowerCategory = category.toLowerCase();

  // Transportation Keywords
  if (lowerCategory.contains('bts') || lowerCategory.contains('train')) return Icons.train_outlined;
  if (lowerCategory.contains('bus')) return Icons.directions_bus_outlined;
  if (lowerCategory.contains('taxi') || lowerCategory.contains('grab')) return Icons.local_taxi_outlined;
  if (lowerCategory.contains('flight') || lowerCategory.contains('plane')) return Icons.flight_takeoff_outlined;

  // Food & Drink Keywords
  if (lowerCategory.contains('coffee') || lowerCategory.contains('cafe')) return Icons.coffee_outlined;
  if (lowerCategory.contains('food') || lowerCategory.contains('restaurant') || lowerCategory.contains('lunch') || lowerCategory.contains('dinner')) return Icons.fastfood_outlined;
  if (lowerCategory.contains('grocer')) return Icons.local_grocery_store_outlined;

  // Shopping & Bills Keywords
  if (lowerCategory.contains('shop')) return Icons.shopping_cart_outlined;
  if (lowerCategory.contains('bill')) return Icons.receipt_long_outlined;
  
  // Entertainment Keywords
  if (lowerCategory.contains('movie') || lowerCategory.contains('cinema')) return Icons.movie_outlined;
  if (lowerCategory.contains('travel')) return Icons.luggage_outlined;
  if (lowerCategory.contains('health') || lowerCategory.contains('gym')) return Icons.fitness_center_outlined;

  // Income Keywords
  if (lowerCategory.contains('salary') || lowerCategory.contains('work')) return Icons.work_outline;
  if (lowerCategory.contains('gift')) return Icons.card_giftcard_outlined;
  if (lowerCategory.contains('invest')) return Icons.trending_up;


  // --- 2. Fallback Hashing (for all other custom categories) ---
  
  // A predefined list of generic, visually distinct icons.
  const List<IconData> fallbackIcons = [
    Icons.category_outlined,
    Icons.star_border_outlined,
    Icons.label_outline,
    Icons.wallet_outlined,
    Icons.bookmark_border,
    Icons.push_pin_outlined,
    Icons.circle_outlined,
    Icons.square_outlined,
    Icons.hexagon_outlined,
    Icons.grid_view_outlined,
  ];

  // Use the category name's hash code to pick a consistent icon from the list.
  // The modulo operator (%) ensures the index is always within the bounds of the list.
  int hashCode = category.hashCode;
  int index = hashCode.abs() % fallbackIcons.length;
  return fallbackIcons[index];
}

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();
    final currency = Provider.of<SettingsProvider>(context).selectedCurrency;

    return Scaffold(
      appBar: AppBar(title: const Text('All Transactions')),
      body: StreamBuilder<List<FinancialTransaction>>(
        stream: firestoreService.getTransactions(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (snapshot.data!.isEmpty) return const Center(child: Text("No transactions yet."));
          
          final transactions = snapshot.data!;

          return AnimationLimiter(
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 80), // Add padding for FAB
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final transaction = transactions[index];
                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: const Duration(milliseconds: 375),
                  child: SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(
                      child: _buildTransactionTile(context, transaction, currency),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransactionTile(BuildContext context, FinancialTransaction transaction, Currency currency) {
    final isIncome = transaction.type == 'income';
    final color = isIncome ? Colors.green : Colors.red;
    final amountString = (isIncome ? '+' : '-') + NumberFormat.currency(locale: currency.locale, symbol: currency.symbol).format(transaction.amount);

    return GestureDetector(
       onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AddTransactionPage(transaction: transaction)),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            child: Icon(_getIconForCategory(transaction.category), size: 20, color: color),
          ),
          title: Text(transaction.category, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(transaction.person), // Display the person who made the transaction
          trailing: Text(amountString, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      ),
    );
  }
}