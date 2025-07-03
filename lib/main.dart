import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_fin_pwa/firebase_options.dart';
import 'package:flutter_fin_pwa/screens/auth/auth_gate.dart';
import 'package:flutter_fin_pwa/services/auth_service.dart';
import 'package:flutter_fin_pwa/services/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // --- Use MultiProvider to provide both services ---
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthService()),
        ChangeNotifierProvider(create: (context) => SettingsProvider()),
      ],
      child: MaterialApp(
        title: 'Finance Tracker',
        theme: ThemeData(
            primarySwatch: Colors.blue,
            useMaterial3: true,
            scaffoldBackgroundColor: Colors.grey[100],
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              elevation: 1,
              iconTheme: IconThemeData(color: Colors.black),
              titleTextStyle: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            )),
        debugShowCheckedModeBanner: false,
        home: const AuthGate(),
      ),
    );
  }
}