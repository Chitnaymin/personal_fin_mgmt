import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:flutter_fin_pwa/models/transaction_model.dart';
import 'package:flutter_fin_pwa/screens/main/add_transaction_page.dart';
import 'package:flutter_fin_pwa/services/firestore_service.dart';
import 'package:flutter_fin_pwa/services/settings_provider.dart';

class TransactionsPage extends StatelessWidget {
  const TransactionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();
    final selectedCurrency = Provider.of<SettingsProvider>(context).selectedCurrency;

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Transactions'),
      ),
      body: StreamBuilder<List<FinancialTransaction>>(
        stream: firestoreService.getTransactions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No transactions found."));
          }
          final transactions = snapshot.data!;
          return ListView.builder(
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              final isIncome = transaction.type == 'income';
              final amountColor = isIncome ? Colors.green : Colors.red;
              final amountPrefix = isIncome ? '+' : '-';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: amountColor.withOpacity(0.2),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(isIncome ? Icons.arrow_upward : Icons.arrow_downward, color: amountColor, size: 20),
                        if (transaction.receiptImageBase64 != null)
                          const Positioned(
                            bottom: 0,
                            right: 0,
                            child: Icon(Icons.receipt_long, size: 12, color: Colors.blueGrey),
                          )
                      ],
                    ),
                  ),
                  title: Text(transaction.category, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(transaction.notes ?? 'No notes'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$amountPrefix${NumberFormat.currency(locale: selectedCurrency.locale, symbol: selectedCurrency.symbol).format(transaction.amount)}',
                        style: TextStyle(color: amountColor, fontWeight: FontWeight.bold),
                      ),
                      Text(DateFormat.yMMMd().format(transaction.date), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => AddTransactionPage(transaction: transaction)));
                  },
                  onLongPress: transaction.receiptImageBase64 != null
                      ? () {
                          showDialog(
                            context: context,
                            builder: (_) => Dialog(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Image.memory(base64Decode(transaction.receiptImageBase64!)),
                              ),
                            ),
                          );
                        }
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}