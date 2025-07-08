import 'package:cloud_firestore/cloud_firestore.dart';

class FinancialTransaction {
  final String? id;
  final String? userId;
  final double amount;
  final String type;
  final String category;
  final String person;
  final String? notes;
  final String? receiptImageBase64;
  final DateTime date;

  FinancialTransaction({
    this.id,
    this.userId,
    required this.amount,
    required this.type,
    required this.category,
    required this.person,
    this.notes,
    this.receiptImageBase64,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'type': type,
      'category': category,
      'person': person,
      'notes': notes,
      'receiptImageBase64': receiptImageBase64,
      'date': Timestamp.fromDate(date),
    };
  }

  factory FinancialTransaction.fromMap(Map<String, dynamic> map, String id) {
    return FinancialTransaction(
      id: id,
      userId: map['userId'],
      amount: map['amount'].toDouble(),
      type: map['type'],
      category: map['category'],
      person: map['person'] ?? 'Unknown',
      notes: map['notes'],
      receiptImageBase64: map['receiptImageBase64'],
      date: (map['date'] as Timestamp).toDate(),
    );
  }
}