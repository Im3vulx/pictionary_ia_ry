import 'package:flutter/material.dart';
import 'package:pictionary_ia_ry/view/splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData base = ThemeData.dark(useMaterial3: true);
    final Color primary = const Color(0xFF00F5FF); // cyan néon
    final Color secondary = const Color(0xFF7B61FF); // violet néon
    final Color background = const Color(0xFF0B1020); // noir bleuté futuriste

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        colorScheme: base.colorScheme.copyWith(
          primary: primary,
          secondary: secondary,
          surface: const Color(0xFF11172B),
          onSurface: Colors.white,
        ),
        scaffoldBackgroundColor: background,
        textTheme: base.textTheme.apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
            fontSize: 20,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
            elevation: 0,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF11172B),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: primary.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: primary),
            borderRadius: BorderRadius.circular(12),
          ),
          labelStyle: const TextStyle(color: Colors.white70),
          hintStyle: const TextStyle(color: Colors.white54),
        ),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF1C2440),
          contentTextStyle: TextStyle(color: Colors.white),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF11172B),
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: primary.withOpacity(0.1)),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
