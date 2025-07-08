import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'package:flutter_fin_pwa/firebase_options.dart';
import 'package:flutter_fin_pwa/screens/auth/auth_gate.dart';
import 'package:flutter_fin_pwa/services/auth_service.dart';
import 'package:flutter_fin_pwa/services/settings_provider.dart';
import 'package:flutter_fin_pwa/theme/app_themes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Watch the provider to listen for changes
    final settingsProvider = context.watch<SettingsProvider>();

    // While the provider is fetching settings from Firestore, show a loading screen.
    if (settingsProvider.isLoading) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    // Once settings are loaded, build the app with the correct theme.
    return MaterialApp(
      title: 'Finance Tracker',
      theme: getThemeData(settingsProvider.appTheme),
      debugShowCheckedModeBanner: false,
      home: const AuthGate(),
    );
  }
}