import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// We need to import the FirestoreService to use its methods
import 'package:flutter_fin_pwa/services/firestore_service.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  AuthService() {
    print("AuthService has been created!");
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException {
      rethrow;
    }
  }

  // --- REFACTORED SIGN UP METHOD ---
  Future<UserCredential?> signUpWithEmail(String email, String password) async {
    try {
      // 1. Create the user in Firebase Authentication
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. If successful, get the new user object
      if (userCredential.user != null) {
        // 3. Create the corresponding user document in Firestore
        await _firestoreService.createUserDocument(userCredential.user!);
      }

      // 4. Return the credential to the UI
      return userCredential;
      
    } on FirebaseAuthException {
      // Let the UI handle the specific error
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}