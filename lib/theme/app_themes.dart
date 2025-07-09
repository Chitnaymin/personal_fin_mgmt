import 'package:flutter/material.dart';

// --- ENUM WITH ALL 5 THEMES ---
enum AppTheme {
  light,
  dark,
  grey,
  lightPink,
  lightPurple,
}

ThemeData getThemeData(AppTheme theme) {
  const serenePrimaryColor = Color(0xFFE91E63);
  const sereneTextColor = Color(0xFF333333);

  // The base theme that all themes will share
  final baseTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Inter',
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(color: Colors.grey.shade200),
      ),
    ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(fontWeight: FontWeight.bold, color: sereneTextColor, fontSize: 28),
      titleLarge: TextStyle(fontWeight: FontWeight.bold, color: sereneTextColor, fontSize: 20),
      bodyLarge: TextStyle(color: sereneTextColor, fontSize: 16),
      bodyMedium: TextStyle(color: Colors.grey, fontSize: 14),
    ),
  );

  switch (theme) {
    // --- 1. THE TRADITIONAL LIGHT THEME (BLUE) ---
    case AppTheme.light:
      return baseTheme.copyWith(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF9FAFC),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        appBarTheme: baseTheme.appBarTheme.copyWith(
          backgroundColor: const Color(0xFFF9FAFC),
          foregroundColor: sereneTextColor,
          titleTextStyle: const TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.bold, color: sereneTextColor),
        ),
      );
    
    // --- 2. THE DARK THEME ---
    case AppTheme.dark:
       return baseTheme.copyWith(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: ColorScheme.fromSeed(
          seedColor: serenePrimaryColor, // Pink accent on dark theme
          brightness: Brightness.dark,
        ),
      );

    // --- 3. THE GREY THEME ---
    case AppTheme.grey:
      return baseTheme.copyWith(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.blueGrey.shade50,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
         appBarTheme: baseTheme.appBarTheme.copyWith(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          titleTextStyle: const TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
      );

    // --- 4. THE LIGHT PINK THEME ---
    case AppTheme.lightPink:
      return baseTheme.copyWith(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color.fromARGB(255, 255, 251, 252),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 240, 36, 104)),
        appBarTheme: baseTheme.appBarTheme.copyWith(
          backgroundColor: const Color.fromARGB(255, 255, 252, 253),
          foregroundColor: const Color.fromARGB(255, 230, 34, 119),
          titleTextStyle: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.bold, color: const Color.fromARGB(255, 189, 25, 96)),
        ),
      );
    
    // --- 5. THE LIGHT PURPLE THEME ---
    case AppTheme.lightPurple:
      return baseTheme.copyWith(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF3E5F5),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
         appBarTheme: baseTheme.appBarTheme.copyWith(
          backgroundColor: Colors.deepPurple.shade50,
          foregroundColor: const Color.fromARGB(255, 80, 47, 180),
           titleTextStyle: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple.shade800),
        ),
      );
  }
}

// --- HELPER FUNCTION WITH ALL 5 NAMES ---
String getThemeName(AppTheme theme) {
  switch (theme) {
    case AppTheme.light:
      return 'Light';
    case AppTheme.dark:
      return 'Dark';
    case AppTheme.grey:
      return 'Grey';
    case AppTheme.lightPink:
      return 'Light Pink';
    case AppTheme.lightPurple:
      return 'Light Purple';
  }
}