import 'package:flutter/material.dart';
import 'package:pictionary_ia_ry/service/api_service.dart';
import 'package:pictionary_ia_ry/view/guessing_screen.dart';
import 'dart:async';

class DrawingScreen extends StatefulWidget {
  const DrawingScreen({super.key});

  @override
  State<DrawingScreen> createState() => _DrawingScreenState();
}

class _DrawingScreenState extends State<DrawingScreen>
    with TickerProviderStateMixin {
  final TextEditingController _promptController = TextEditingController();

  List<Map<String, dynamic>> _myChallenges = [];
  int _currentChallengeIndex = 0;
  bool _isLoading = false;
  bool _isGenerating = false;
  String? _generatedImageUrl;
  int _score = 100;
  Timer? _phaseTimer;
  int _timeLeft = 300; // 5 minutes en secondes

  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadMyChallenges();
    _startPhaseTimer();
  }

  @override
  void dispose() {
    _promptController.dispose();
    _phaseTimer?.cancel();
    _slideController.dispose();
    super.dispose();
  }

  void _initAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack),
        );
    _slideController.forward();
  }

  void _startPhaseTimer() {
    _phaseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() {
          _timeLeft--;
        });
      } else {
        timer.cancel();
        _handleTimeOut();
      }
    });
  }

  void _handleTimeOut() {
    _showDialog(
      title: 'Temps écoulé !',
      content: 'Le temps imparti pour cette phase est terminé.',
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            _nextChallenge();
          },
          child: const Text('Continuer'),
        ),
      ],
    );
  }

  Future<void> _loadMyChallenges() async {
    if (ApiService.gameSessionId == null) {
      _showError('Aucune session active');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final challenges = await ApiService.getMyChallenges(
        ApiService.gameSessionId!,
      );
      if (challenges != null && challenges.isNotEmpty) {
        setState(() {
          _myChallenges = challenges;
          _isLoading = false;
        });
      } else {
        _showError('Aucun challenge à dessiner trouvé');
      }
    } catch (e) {
      _showError('Erreur lors du chargement des challenges');
      print('Erreur load challenges: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _generateImage() async {
    if (_promptController.text.trim().isEmpty) {
      _showError('Veuillez saisir une description');
      return;
    }

    final currentChallenge = _getCurrentChallenge();
    if (currentChallenge == null) return;

    // Vérification des mots interdits
    final prompt = _promptController.text.toLowerCase();
    final forbiddenWords = List<String>.from(
      currentChallenge['forbidden_words'] ?? [],
    );

    for (final forbiddenWord in forbiddenWords) {
      if (prompt.contains(forbiddenWord.toLowerCase())) {
        _showError(
          'Votre description ne peut pas contenir le mot interdit: "$forbiddenWord"',
        );
        return;
      }
    }

    // Vérification des mots à deviner
    final wordsToGuess = _extractWordsToGuess(currentChallenge);
    for (final word in wordsToGuess) {
      if (prompt.contains(word.toLowerCase())) {
        _showError(
          'Votre description ne peut pas contenir le mot à deviner: "$word"',
        );
        return;
      }
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      final challengeId = currentChallenge['id'] ?? currentChallenge['_id'];
      final success = await ApiService.drawForChallenge(
        ApiService.gameSessionId!,
        challengeId,
        _promptController.text.trim(),
      );

      if (success) {
        // Simulation
        await Future.delayed(const Duration(seconds: 2));
        setState(() {
          _generatedImageUrl =
              'https://via.placeholder.com/300.png?text=Image+Générée';
          _isGenerating = false;
          // Regeneration attempt
          _score = (_score - 10).clamp(0, 100);
        });
      } else {
        _showError('Erreur lors de la génération de l\'image');
        setState(() {
          _isGenerating = false;
        });
      }
    } catch (e) {
      _showError('Erreur lors de la génération de l\'image');
      print('Erreur generate image: $e');
      setState(() {
        _isGenerating = false;
      });
    }
  }

  Map<String, dynamic>? _getCurrentChallenge() {
    if (_currentChallengeIndex < _myChallenges.length) {
      return _myChallenges[_currentChallengeIndex];
    }
    return null;
  }

  List<String> _extractWordsToGuess(Map<String, dynamic> challenge) {
    final words = <String>[];
    if (challenge.containsKey('input1')) words.add(challenge['input1']);
    if (challenge.containsKey('input2')) words.add(challenge['input2']);
    return words;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showDialog({
    required String title,
    required String content,
    required List<Widget> actions,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: actions,
      ),
    );
  }

  void _nextChallenge() {
    setState(() {
      if (_currentChallengeIndex < _myChallenges.length - 1) {
        _currentChallengeIndex++;
        _generatedImageUrl = null;
        _promptController.clear();
      } else {
        // Fin des challenges → naviguer vers l'écran de devinette
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const GuessingScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
              "Phase: Dessin",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        body: SlideTransition(
          position: _slideAnimation,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Zone d'image
                Container(
                  width: double.infinity,
                  height: 300,
                  decoration: BoxDecoration(
                    color: const Color(0xFF11172B).withOpacity(0.8),
                    borderRadius: BorderRadius.circular(16),
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
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF00F5FF),
                            ),
                          ),
                        )
                      : _generatedImageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            _generatedImageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.image_not_supported,
                                      size: 64,
                                      color: Colors.white54,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Image non disponible',
                                      style: TextStyle(color: Colors.white54),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        )
                      : const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.brush,
                                size: 64,
                                color: Colors.white54,
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Aucune image générée",
                                style: TextStyle(color: Colors.white54),
                              ),
                            ],
                          ),
                        ),
                ),
                const SizedBox(height: 24),

                // Champ de saisie
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF11172B).withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF00F5FF).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: _promptController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: "Décris ton image",
                      labelStyle: TextStyle(color: Colors.white70),
                      hintText: "Ex: Un chat orange sur une table en bois",
                      hintStyle: TextStyle(color: Colors.white38),
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF00F5FF)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Bouton de génération
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
                    onPressed: _isGenerating ? null : _generateImage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 32,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isGenerating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            "Générer l'image",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
