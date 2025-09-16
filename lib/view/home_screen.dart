import 'package:flutter/material.dart';
import 'package:pictionary_ia_ry/view/team_screen.dart';
import 'package:pictionary_ia_ry/service/api_service.dart';
import 'package:pictionary_ia_ry/view/widgets/futuristic_scaffold.dart';

class HomeScreen extends StatefulWidget {
  final String nickname;

  const HomeScreen({super.key, required this.nickname});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _creating = false;
  bool _joining = false;

  Future<void> _showJoinDialog() async {
    final TextEditingController sessionController = TextEditingController();
    String selectedColor = 'blue';

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: const Text('Rejoindre une partie'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: sessionController,
                    decoration: const InputDecoration(
                      labelText: 'ID de session',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Couleur:'),
                      const SizedBox(width: 12),
                      DropdownButton<String>(
                        value: selectedColor,
                        items: const [
                          DropdownMenuItem(value: 'blue', child: Text('Bleu')),
                          DropdownMenuItem(value: 'red', child: Text('Rouge')),
                        ],
                        onChanged: (v) {
                          if (v == null) return;
                          setLocalState(() => selectedColor = v);
                        },
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (sessionController.text.trim().isEmpty) return;
                    Navigator.of(context).pop(true);
                  },
                  child: const Text('Rejoindre'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed == true) {
      setState(() {
        _joining = true;
      });
      final String sessionId = sessionController.text.trim();
      final bool ok = await ApiService.joinSession(sessionId, selectedColor);
      if (!mounted) return;
      setState(() {
        _joining = false;
      });
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de rejoindre la session.')),
        );
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TeamScreen(nickname: widget.nickname),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FuturisticScaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: ShaderMask(
                shaderCallback: (rect) => const LinearGradient(
                  colors: [Color(0xFF00F5FF), Color(0xFF7B61FF)],
                ).createShader(rect),
                child: Text(
                  'Bonjour, ${widget.nickname} !',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Bouton Nouvelle Partie
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00F5FF), Color(0xFF7B61FF)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00F5FF).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _creating
                    ? null
                    : () async {
                        setState(() {
                          _creating = true;
                        });
                        final sessionId = await ApiService.createGameSession();
                        setState(() {
                          _creating = false;
                        });
                        if (!mounted) return;
                        if (sessionId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Impossible de créer la session.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                TeamScreen(nickname: widget.nickname),
                          ),
                        );
                      },
                child: _creating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        'Nouvelle Partie',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Bouton Rejoindre une Partie
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFF00F5FF).withOpacity(0.5),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _joining ? null : _showJoinDialog,
                child: _joining
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF00F5FF),
                          ),
                        ),
                      )
                    : const Text(
                        'Rejoindre une Partie',
                        style: TextStyle(
                          color: Color(0xFF00F5FF),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
