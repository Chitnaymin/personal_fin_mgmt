import 'package:flutter/material.dart';

// An Enum provides a type-safe way to refer to our themes.
enum AppTheme {
  light,
  dark,
  grey,
  lightPink,
  lightPurple,
}

// A map that links each theme enum to its actual ThemeData object.
final Map<AppTheme, ThemeData> appThemeData = {
  AppTheme.light: ThemeData(
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
    useMaterial3: true,
  ),
  AppTheme.dark: ThemeData(
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
  ),
  AppTheme.grey: ThemeData(
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
    ),
    useMaterial3: true,
  ),
  AppTheme.lightPink: ThemeData(
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.pink.shade200),
    scaffoldBackgroundColor: const Color.fromARGB(255, 255, 255, 255),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.pink.shade50,   // A very light pink
      foregroundColor: Colors.pink.shade800, // Dark pink text for contrast
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.pink.shade300, // Button color
        foregroundColor: Colors.white,         // Button text color
      )
    ),

    useMaterial3: true,
  ),
  AppTheme.lightPurple: ThemeData(
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
    scaffoldBackgroundColor: const Color(0xFFF3E5F5), // Light Purple Background
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.deepPurple.shade50,
      foregroundColor: Colors.deepPurple.shade800,
    ),
    useMaterial3: true,
  ),
};

// A helper function to get a user-friendly name for the dropdown menu.
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