import 'package:flutter/material.dart';
import 'package:pictionary_ia_ry/view/team_screen.dart';

class HomeScreen extends StatefulWidget {
  final String nickname;

  const HomeScreen({super.key, required this.nickname});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pictionary.IA.RY'),
        backgroundColor: const Color(0xFF709CA7),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: Text('Bonjour, ${widget.nickname}!')),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all<Color>(
                  const Color(0xFF137C8B),
                ),
                elevation: WidgetStateProperty.all<double>(0),
                shadowColor: WidgetStateProperty.all<Color>(
                  const Color(0xFF137C8B),
                ),
              ),
              onPressed: () {
                // Action pour "Nouvelle Partie" vers l'écran de composition des équipes et envoi du pseudo
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TeamScreen(nickname: widget.nickname),
                  ),
                );
              },
              child: const Text(
                'Nouvelle Partie',
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all<Color>(
                  const Color(0xFF137C8B),
                ),
                elevation: WidgetStateProperty.all<double>(0),
                shadowColor: WidgetStateProperty.all<Color>(
                  const Color(0xFF137C8B),
                ),
              ),
              onPressed: () {
                // Action pour "Rejoindre une Partie"
              },
              child: const Text(
                'Rejoindre une Partie',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
