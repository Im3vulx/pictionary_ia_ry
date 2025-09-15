import 'package:flutter/material.dart';
import 'package:pictionary_ia_ry/view/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToLogin();
  }

  Future<void> _navigateToLogin() async {
    await Future.delayed(const Duration(seconds: 2)); // Ajout d'un délai de 2 secondes
    Navigator.pushReplacement(
      mounted
          ? context
          : throw Exception("Le contexte n'est plus monté"),
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF709CA7), // Couleur de fond
      body: Center(
        child: CircularProgressIndicator( // Indicateur de chargement circulaire
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white), // Couleur de l'indicateur
        ),
      ),
    );
  }
}
