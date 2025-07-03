import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Make sure these paths are correct for your project structure
import 'package:flutter_fin_pwa/screens/auth/login_page.dart';
import 'package:flutter_fin_pwa/screens/main/home_page.dart';
import 'package:flutter_fin_pwa/services/auth_service.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        // Listen to the stream from your AuthService
        stream: context.watch<AuthService>().authStateChanges,
        builder: (context, snapshot) {
          // 1. If we are still waiting for a connection, show a loading circle.
          // This is important for the initial app startup.
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. If the stream has data, it means a user is logged in.
          if (snapshot.hasData) {
            // User is logged in, show the main part of the app.
            return const HomePage();
          }

          // 3. If the stream has no data, no user is logged in.
          else {
            // User is not logged in, show the login page.
            return const LoginPage();
          }
        },
      ),
    );
  }
}