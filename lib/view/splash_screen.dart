import 'package:flutter/material.dart';
import 'package:pictionary_ia_ry/view/auth_screen.dart';
import 'package:pictionary_ia_ry/view/widgets/futuristic_scaffold.dart';

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
    await Future.delayed(const Duration(seconds: 2));
    Navigator.pushReplacement(
      mounted ? context : throw Exception("Le contexte n'est plus monté"),
      MaterialPageRoute(builder: (context) => const AuthScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FuturisticScaffold(
      appBar: null,
      body: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
    );
  }
}
