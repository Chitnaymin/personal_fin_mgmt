import 'package:cloud_firestore/cloud_firestore.dart';

class FinancialTransaction {
  final String? id;
  // This is now optional as it's not stored in the transaction document itself.
  final String? userId; 
  final double amount;
  final String type; // 'income' or 'outcome'
  final String category;
  final String? notes;
  final DateTime date;

  FinancialTransaction({
    this.id,
    this.userId, // Optional
    required this.amount,
    required this.type,
    required this.category,
    this.notes,
    required this.date,
  });

  // This map no longer includes the userId
  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'type': type,
      'category': category,
      'notes': notes,
      'date': Timestamp.fromDate(date),
    };
  }

  // The factory can stay the same, it just won't find a 'userId' in the map,
  // which is fine since the property is nullable.
  factory FinancialTransaction.fromMap(Map<String, dynamic> map, String id) {
    return FinancialTransaction(
      id: id,
      userId: map['userId'], // This will be null, which is now okay.
      amount: map['amount'].toDouble(),
      type: map['type'],
      category: map['category'],
      notes: map['notes'],
      date: (map['date'] as Timestamp).toDate(),
    );
  }
}