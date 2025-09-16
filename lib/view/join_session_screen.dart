import 'package:flutter/material.dart';
import 'package:pictionary_ia_ry/service/api_service.dart';
import 'package:pictionary_ia_ry/view/team_screen.dart';

class JoinSessionScreen extends StatefulWidget {
  final String nickname;

  const JoinSessionScreen({super.key, required this.nickname});

  @override
  State<JoinSessionScreen> createState() => _JoinSessionScreenState();
}

class _JoinSessionScreenState extends State<JoinSessionScreen> {
  final TextEditingController _sessionIdController = TextEditingController();
  bool _isJoining = false;

  @override
  void dispose() {
    _sessionIdController.dispose();
    super.dispose();
  }

  Future<void> _joinSession() async {
    final sessionId = _sessionIdController.text.trim();
    if (sessionId.isEmpty) {
      _showError('Veuillez saisir un ID de session');
      return;
    }

    setState(() {
      _isJoining = true;
    });

    try {
      // Ici vous pourriez d'abord vérifier si la session existe
      // Pour l'instant on navigue directement vers TeamScreen avec l'ID

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => JoinExistingTeamScreen(
            nickname: widget.nickname,
            sessionId: sessionId,
          ),
        ),
      );
    } catch (e) {
      _showError('Erreur lors de la connexion à la session');
      print('Erreur join session: $e');
    } finally {
      setState(() {
        _isJoining = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C5F66),
      appBar: AppBar(
        title: const Text(
          'Rejoindre une partie',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF137C8B),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instructions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF709CA7),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Column(
                children: [
                  Icon(Icons.info_outline, size: 40, color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'Rejoindre une partie existante',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Demandez l\'ID de session au créateur de la partie et saisissez-le ci-dessous pour rejoindre la partie.',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Champ ID de session
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF709CA7),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ID de la session',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _sessionIdController,
                    enabled: !_isJoining,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: 'Courier',
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF2C5F66),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      hintText: 'ex: abc123def456',
                      hintStyle: const TextStyle(
                        color: Colors.white54,
                        fontFamily: 'Courier',
                      ),
                      prefixIcon: const Icon(Icons.key, color: Colors.white70),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    textCapitalization: TextCapitalization.none,
                    autocorrect: false,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Bouton rejoindre
            ElevatedButton(
              onPressed: _isJoining ? null : _joinSession,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF137C8B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 8,
              ),
              child: _isJoining
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Connexion en cours...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.login, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Rejoindre la partie',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),

            const Spacer(),

            // Note de sécurité
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.security, color: Colors.orange),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Assurez-vous de ne rejoindre que des parties de confiance.',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Écran spécialisé pour rejoindre une session existante
class JoinExistingTeamScreen extends StatefulWidget {
  final String nickname;
  final String sessionId;

  const JoinExistingTeamScreen({
    super.key,
    required this.nickname,
    required this.sessionId,
  });

  @override
  State<JoinExistingTeamScreen> createState() => _JoinExistingTeamScreenState();
}

class _JoinExistingTeamScreenState extends State<JoinExistingTeamScreen> {
  bool _isLoading = true;
  bool _isJoining = false;
  String? _selectedColor;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkSessionExists();
  }

  Future<void> _checkSessionExists() async {
    try {
      // Ici vous pourriez vérifier si la session existe
      // Pour l'instant on simule que ça marche
      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        _isLoading = false;
      });

      _showTeamSelectionDialog();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Session introuvable ou fermée';
      });
    }
  }

  void _showTeamSelectionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF709CA7),
        title: const Text(
          'Choisissez votre équipe',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Session: ${widget.sessionId.substring(0, 8)}...',
              style: const TextStyle(
                color: Colors.white70,
                fontFamily: 'Courier',
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Dans quelle équipe souhaitez-vous jouer ?',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isJoining ? null : () => _joinTeam('blue'),
                    icon: const Icon(Icons.group, color: Colors.white),
                    label: const Text(
                      'Bleue',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isJoining ? null : () => _joinTeam('red'),
                    icon: const Icon(Icons.group, color: Colors.white),
                    label: const Text(
                      'Rouge',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            if (_isJoining) ...[
              const SizedBox(height: 16),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Rejoindre l\'équipe...',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ],
          ],
        ),
        actions: [
          if (!_isJoining)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text(
                'Annuler',
                style: TextStyle(color: Colors.white70),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _joinTeam(String color) async {
    setState(() {
      _isJoining = true;
      _selectedColor = color;
    });

    try {
      final success = await ApiService.joinSession(widget.sessionId, color);
      if (success) {
        Navigator.pop(context); // Ferme le dialog

        // Navigate vers un TeamScreen modifié qui affiche la session existante
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TeamScreen(nickname: widget.nickname),
          ),
        );
      } else {
        _showError('Erreur lors de la jonction à l\'équipe');
        setState(() {
          _isJoining = false;
        });
      }
    } catch (e) {
      _showError('Erreur de connexion');
      setState(() {
        _isJoining = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF2C5F66),
        appBar: AppBar(
          title: const Text('Erreur'),
          backgroundColor: const Color(0xFF137C8B),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 80, color: Colors.red),
                const SizedBox(height: 24),
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Retour'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF2C5F66),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              SizedBox(height: 24),
              Text(
                'Vérification de la session...',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF2C5F66),
      appBar: AppBar(
        title: const Text(
          'Rejoindre la partie',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF137C8B),
      ),
      body: const Center(
        child: Text(
          'Session trouvée ! Choisissez votre équipe.',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
    );
  }
}
