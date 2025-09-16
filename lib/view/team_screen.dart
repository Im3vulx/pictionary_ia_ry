import 'package:flutter/material.dart';
import 'package:pictionary_ia_ry/models/player.dart';
import 'package:pictionary_ia_ry/models/team.dart';
import 'package:pictionary_ia_ry/view/game_screen.dart';
import 'package:pictionary_ia_ry/service/api_service.dart';
import 'dart:async';

class TeamScreen extends StatefulWidget {
  final String nickname;

  const TeamScreen({super.key, required this.nickname});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> with TickerProviderStateMixin {
  late Team blueTeam;
  late Team redTeam;
  bool _hasStarted = false;
  bool _isCreatingSession = false;
  String? _gameSessionId;
  String? _selectedColor;

  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;

  // Simulation de joueurs qui rejoignent
  final List<String> _simulatedPlayers = ['Alice', 'Bob', 'Charlie'];
  int _nextPlayerIndex = 0;

  @override
  void initState() {
    super.initState();
    blueTeam = Team(name: 'Équipe Bleue', players: []);
    redTeam = Team(name: 'Équipe Rouge', players: []);

    // Initialisation des animations
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.elasticInOut),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack),
        );

    _startPulseAnimation();
    _slideController.forward();

    _createSession();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _startPulseAnimation() {
    _pulseController.repeat(reverse: true);
  }

  Future<void> _createSession() async {
    setState(() {
      _isCreatingSession = true;
    });

    try {
      final sessionId = await ApiService.createGameSession();
      if (sessionId != null) {
        setState(() {
          _gameSessionId = sessionId;
          _isCreatingSession = false;
        });
        _showColorSelectionDialog();
      } else {
        _showError('Erreur lors de la création de la session');
      }
    } catch (e) {
      _showError('Erreur de connexion au serveur');
      print('Erreur création session: $e');
    } finally {
      setState(() {
        _isCreatingSession = false;
      });
    }
  }

  void _showColorSelectionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        contentPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF00A2A8), Color(0xFF7B61FF)],
            ),
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Choisissez votre équipe',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
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
                      onPressed: () => _selectTeam('blue'),
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
                      onPressed: () => _selectTeam('red'),
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
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectTeam(String color) async {
    Navigator.pop(context);

    setState(() {
      _selectedColor = color;
    });

    try {
      if (_gameSessionId != null) {
        // Generate a Player with ID
        final player = Player(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: widget.nickname,
        );

        final success = await ApiService.joinSession(_gameSessionId!, color);
        if (success) {
          setState(() {
            if (color == 'blue') {
              blueTeam.players.add(player);
            } else {
              redTeam.players.add(player);
            }
          });
          _simulatePlayersJoining();
        } else {
          _showError('Erreur lors de la jonction à l\'équipe');
        }
      }
    } catch (e) {
      _showError('Erreur de connexion');
      print('Erreur join session: $e');
    } finally {
      setState(() {
        // completed
      });
    }
  }

  void _simulatePlayersJoining() {
    // Simulation de joueurs qui rejoignent progressivement
    Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_nextPlayerIndex >= _simulatedPlayers.length || _hasStarted) {
        timer.cancel();
        return;
      }

      setState(() {
        final playerName = _simulatedPlayers[_nextPlayerIndex];
        final simulatedPlayer = Player(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: playerName,
        );
        if (blueTeam.players.length <= redTeam.players.length) {
          blueTeam.players.add(simulatedPlayer);
        } else {
          redTeam.players.add(simulatedPlayer);
        }
        _nextPlayerIndex++;
      });

      _checkIfCanStart();
    });
  }

  void _checkIfCanStart() {
    final int blueCount = blueTeam.players.length;
    final int redCount = redTeam.players.length;

    final bool canStart = blueCount >= 2 && redCount >= 2;

    if (canStart && !_hasStarted) {
      _pulseController.stop();
      Future.delayed(const Duration(seconds: 1), _startGame);
    }
  }

  Future<void> _startGame() async {
    if (_hasStarted) return;

    setState(() {
      _hasStarted = true;
    });

    try {
      if (_gameSessionId != null) {
        final success = await ApiService.startSession(_gameSessionId!);
        if (success) {
          _showSuccessMessage();
          Future.delayed(const Duration(seconds: 2), () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const GameScreen()),
            );
          });
        } else {
          _showError('Erreur lors du démarrage de la partie');
        }
      }
    } catch (e) {
      _showError('Erreur lors du démarrage');
      print('Erreur start session: $e');
    }
  }

  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            const Text('La partie commence !'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
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
    final int blueCount = blueTeam.players.length;
    final int redCount = redTeam.players.length;
    final int totalCount = blueCount + redCount;
    final bool canStart = blueCount >= 2 && redCount >= 2 && totalCount >= 4;

    if (_isCreatingSession) {
      return _buildLoadingScreen('Création de la partie...');
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B1020), Color(0xFF11172B), Color(0xFF0B1020)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: ShaderMask(
            shaderCallback: (rect) => const LinearGradient(
              colors: [Color(0xFF00F5FF), Color(0xFF7B61FF)],
            ).createShader(rect),
            child: const Text(
              'Composition des équipes',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SlideTransition(
          position: _slideAnimation,
          child: Column(
            children: [
              // Header avec infos de session futuriste
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF11172B).withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF00F5FF).withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00F5FF).withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Session de jeu',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: _gameSessionId != null
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFF00F5FF),
                                      Color(0xFF7B61FF),
                                    ],
                                  )
                                : LinearGradient(
                                    colors: [
                                      Colors.orange.withOpacity(0.8),
                                      Colors.orange,
                                    ],
                                  ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    (_gameSessionId != null
                                            ? const Color(0xFF00F5FF)
                                            : Colors.orange)
                                        .withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Text(
                            _gameSessionId != null
                                ? 'Connectée'
                                : 'En cours...',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_gameSessionId != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'ID: ${_gameSessionId!.substring(0, _gameSessionId!.length.clamp(0, 8))}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontFamily: 'Courier',
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Équipes
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      // Équipe Bleue
                      Expanded(
                        child: _buildTeamCard(
                          team: blueTeam,
                          color: Colors.blue.shade600,
                          icon: Icons.waves,
                          isUserTeam: _selectedColor == 'blue',
                        ),
                      ),
                      const SizedBox(width: 16),
                      // VS au milieu
                      _buildVSSection(),
                      const SizedBox(width: 16),
                      // Équipe Rouge
                      Expanded(
                        child: _buildTeamCard(
                          team: redTeam,
                          color: Colors.red.shade600,
                          icon: Icons.local_fire_department,
                          isUserTeam: _selectedColor == 'red',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Status et bouton
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF11172B).withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF00F5FF).withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00F5FF).withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    ShaderMask(
                      shaderCallback: (rect) => const LinearGradient(
                        colors: [Color(0xFF00F5FF), Color(0xFF7B61FF)],
                      ).createShader(rect),
                      child: Text(
                        canStart
                            ? _hasStarted
                                  ? 'Démarrage de la partie...'
                                  : 'Les équipes sont prêtes !'
                            : 'En attente de joueurs... ($totalCount/4 minimum)',
                        style: TextStyle(
                          color: canStart ? Colors.white : Colors.white70,
                          fontSize: 16,
                          fontWeight: canStart
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    if (!canStart) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Il faut au minimum 2 joueurs par équipe',
                        style: TextStyle(color: Colors.white54, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if (canStart && !_hasStarted) ...[
                      const SizedBox(height: 12),
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.play_arrow,
                                    color: Color(0xFF00F5FF),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Partie prête !',
                                    style: TextStyle(
                                      color: Color(0xFF00F5FF),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingScreen(String message) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B1020), Color(0xFF11172B), Color(0xFF0B1020)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00F5FF)),
                strokeWidth: 4,
              ),
              const SizedBox(height: 24),
              ShaderMask(
                shaderCallback: (rect) => const LinearGradient(
                  colors: [Color(0xFF00F5FF), Color(0xFF7B61FF)],
                ).createShader(rect),
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamCard({
    required Team team,
    required Color color,
    required IconData icon,
    required bool isUserTeam,
  }) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: isUserTeam ? Border.all(color: Colors.white, width: 3) : null,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header de l'équipe
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                Icon(icon, color: Colors.white, size: 32),
                const SizedBox(height: 8),
                Text(
                  team.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${team.players.length} joueur${team.players.length > 1 ? 's' : ''}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),

          // Liste des joueurs
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: team.players.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_add,
                            color: Colors.white54,
                            size: 32,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'En attente\nde joueurs',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: team.players.length,
                      itemBuilder: (context, index) {
                        final player = team.players[index];
                        final isCurrentUser = player.name == widget.nickname;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(
                              isCurrentUser ? 0.3 : 0.1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            border: isCurrentUser
                                ? Border.all(color: Colors.white, width: 1)
                                : null,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isCurrentUser ? Icons.star : Icons.person,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  isCurrentUser
                                      ? '${player.name} (vous)'
                                      : player.name,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: isCurrentUser
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVSSection() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF11172B).withOpacity(0.8),
        border: Border.all(
          color: const Color(0xFF00F5FF).withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00F5FF).withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Center(
        child: Text(
          'VS',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
