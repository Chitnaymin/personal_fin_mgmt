import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Note: We no longer import firebase_storage or image_picker here.
import 'package:flutter_fin_pwa/models/transaction_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String? userId = FirebaseAuth.instance.currentUser?.uid;

  DocumentReference _userDocRef([String? uid]) {
    final docId = uid ?? userId;
    if (docId == null) throw Exception("User not logged in or UID not provided.");
    return _db.collection('users').doc(docId);
  }

  CollectionReference<Map<String, dynamic>> _transactionsCollectionRef() {
    return _userDocRef().collection('transactions');
  }
  
  // Helper to generate a new transaction ID for uploads
  String getNewTransactionId() {
    return _transactionsCollectionRef().doc().id;
  }

  Future<void> createUserDocument(User user) {
    return _userDocRef(user.uid).set({
      'email': user.email,
      'createdAt': FieldValue.serverTimestamp(),
      'monthlyBudget': 0.0,
      'yearlyBudget': 0.0,
      'incomeCategories': ['Salary', 'Gifts', 'Investment'],
      'outcomeCategories': ['Food', 'Transport', 'Shopping', 'Bills', 'Entertainment'],
      'people': ['Me'],
    });
  }

  Future<void> saveBudget(double monthlyBudget, double yearlyBudget) {
    return _userDocRef().update({
      'monthlyBudget': monthlyBudget,
      'yearlyBudget': yearlyBudget,
    });
  }

  Future<void> saveTransaction(FinancialTransaction transaction) {
    final docRef = _transactionsCollectionRef().doc(transaction.id);
    return docRef.set(transaction.toMap());
  }

  Stream<List<FinancialTransaction>> getTransactions() {
    if (userId == null) return Stream.value([]);
    return _transactionsCollectionRef()
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FinancialTransaction.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> deleteTransaction(String transactionId) {
    return _transactionsCollectionRef().doc(transactionId).delete();
  }

  Stream<DocumentSnapshot> getBudget() {
    if (userId == null) return Stream.empty();
    return _userDocRef().snapshots();
  }

  Future<void> addCategory(String newCategory, String type) {
    final field = type == 'income' ? 'incomeCategories' : 'outcomeCategories';
    return _userDocRef().update({
      field: FieldValue.arrayUnion([newCategory])
    });
  }

  Future<void> deleteCategory(String category, String type) {
    final field = type == 'income' ? 'incomeCategories' : 'outcomeCategories';
    return _userDocRef().update({
      field: FieldValue.arrayRemove([category])
    });
  }

  Future<void> addPerson(String newPerson) {
    return _userDocRef().update({
      'people': FieldValue.arrayUnion([newPerson])
    });
  }

  Future<void> deletePerson(String person) {
    return _userDocRef().update({
      'people': FieldValue.arrayRemove([person])
    });
  }
}