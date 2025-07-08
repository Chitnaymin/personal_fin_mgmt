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
  // Wrap the entire app in MultiProvider to make services available everywhere.
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
    // This 'watch' creates a subscription. When the provider's theme changes,
    // this MyApp widget will rebuild.
    final settingsProvider = context.watch<SettingsProvider>();

    return MaterialApp(
      title: 'Finance Tracker',
      // The theme is now dynamically selected from our appThemeData map.
      theme: appThemeData[settingsProvider.appTheme],
      debugShowCheckedModeBanner: false,
      home: const AuthGate(),
    );
  }
}