import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_fin_pwa/models/transaction_model.dart'; // Make sure this path is correct
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String? userId = FirebaseAuth.instance.currentUser?.uid;

  // Helper to get the reference to the user's specific document
  DocumentReference _userDocRef() {
    if (userId == null) throw Exception("User not logged in.");
    return _db.collection('users').doc(userId);
  }

  // Helper to get the reference to the user's transactions sub-collection
  CollectionReference<Map<String, dynamic>> _transactionsCollectionRef() {
    return _userDocRef().collection('transactions');
  }

  // --- REFACTORED METHODS ---

  // Add/Update Transaction
  Future<void> saveTransaction(FinancialTransaction transaction) {
    // Note: We no longer need to check userId here as the helper does it.
    final docRef = _transactionsCollectionRef().doc(transaction.id);
    
    // We create a new transaction map WITHOUT the userId, as it's redundant.
    final transactionData = {
      'amount': transaction.amount,
      'type': transaction.type,
      'category': transaction.category,
      'notes': transaction.notes,
      'date': Timestamp.fromDate(transaction.date),
    };
    return docRef.set(transactionData);
  }

  // Get all transactions for the user
  Stream<List<FinancialTransaction>> getTransactions() {
    if (userId == null) return Stream.value([]);
    // The query is now much cleaner, targeting the sub-collection directly.
    return _transactionsCollectionRef()
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FinancialTransaction.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Delete Transaction
  Future<void> deleteTransaction(String transactionId) {
    return _transactionsCollectionRef().doc(transactionId).delete();
  }

  // Save user budget settings
  Future<void> saveBudget(double monthlyBudget, double yearlyBudget) {
    // This now saves the budget as fields on the user's document.
    return _userDocRef().set({
      'monthlyBudget': monthlyBudget,
      'yearlyBudget': yearlyBudget,
    }, SetOptions(merge: true)); // merge:true ensures we don't overwrite other settings
  }

  // Get user budget settings
  Stream<DocumentSnapshot> getBudget() {
    if (userId == null) return Stream.empty();
    // This correctly gets the user's main document.
    return _userDocRef().snapshots();
  }
}