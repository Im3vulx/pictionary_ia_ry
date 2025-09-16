import 'package:flutter/material.dart';
import 'package:pictionary_ia_ry/service/api_service.dart';
import 'dart:async';

class GuessingScreen extends StatefulWidget {
  const GuessingScreen({super.key});

  @override
  State<GuessingScreen> createState() => _GuessingScreenState();
}

class _GuessingScreenState extends State<GuessingScreen>
    with TickerProviderStateMixin {
  final TextEditingController _answerController = TextEditingController();

  List<Map<String, dynamic>> _myChallengesToGuess = [];
  int _currentChallengeIndex = 0;
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _currentImageUrl;
  int _score = 100;
  Timer? _phaseTimer;
  int _timeLeft = 300; // 5 minutes en secondes

  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadMyChallengesToGuess();
    _startPhaseTimer();
  }

  @override
  void dispose() {
    _answerController.dispose();
    _phaseTimer?.cancel();
    _slideController.dispose();
    super.dispose();
  }

  void _initAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(-1, 0), end: Offset.zero).animate(
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

  Future<void> _loadMyChallengesToGuess() async {
    if (ApiService.gameSessionId == null) {
      _showError('Aucune session active');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final challenges = await ApiService.getMyChallengesToGuess(
        ApiService.gameSessionId!,
      );
      if (challenges != null && challenges.isNotEmpty) {
        setState(() {
          _myChallengesToGuess = challenges;
          _isLoading = false;
        });
        _loadCurrentImage();
      } else {
        _showError('Aucun challenge à deviner trouvé');
      }
    } catch (e) {
      _showError('Erreur lors du chargement des challenges');
      print('Erreur load challenges to guess: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _loadCurrentImage() {
    final currentChallenge = _getCurrentChallenge();
    if (currentChallenge != null) {
      // Simulation d'une image générée
      setState(() {
        _currentImageUrl =
            'https://via.placeholder.com/400.png?text=Image+à+Deviner';
      });
    }
  }

  Future<void> _submitAnswer() async {
    if (_answerController.text.trim().isEmpty) {
      _showError('Veuillez saisir une réponse');
      return;
    }

    final currentChallenge = _getCurrentChallenge();
    if (currentChallenge == null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final challengeId = currentChallenge['id'] ?? currentChallenge['_id'];
      final answer = _answerController.text.trim();

      // Vérifier si la réponse est correcte (logique simple)
      final wordsToGuess = _extractWordsToGuess(currentChallenge);
      final isResolved = wordsToGuess.any(
        (word) => answer.toLowerCase().contains(word.toLowerCase()),
      );

      final success = await ApiService.answerChallenge(
        ApiService.gameSessionId!,
        challengeId,
        answer,
        isResolved,
      );

      if (success) {
        if (isResolved) {
          _showSuccessSnackBar('Bonne réponse ! +10 points');
          setState(() {
            _score += 10;
          });
        } else {
          _showErrorSnackBar('Mauvaise réponse, essayez encore');
        }
      } else {
        _showError('Erreur lors de l\'envoi de la réponse');
      }
    } catch (e) {
      _showError('Erreur lors de l\'envoi de la réponse');
      print('Erreur submit answer: $e');
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Map<String, dynamic>? _getCurrentChallenge() {
    if (_currentChallengeIndex < _myChallengesToGuess.length) {
      return _myChallengesToGuess[_currentChallengeIndex];
    }
    return null;
  }

  List<String> _extractWordsToGuess(Map<String, dynamic> challenge) {
    final words = <String>[];
    if (challenge.containsKey('first_word')) words.add(challenge['first_word']);
    if (challenge.containsKey('second_word'))
      words.add(challenge['second_word']);
    if (challenge.containsKey('third_word')) words.add(challenge['third_word']);
    if (challenge.containsKey('fourth_word'))
      words.add(challenge['fourth_word']);
    if (challenge.containsKey('fifth_word')) words.add(challenge['fifth_word']);
    return words;
  }

  void _nextChallenge() {
    setState(() {
      if (_currentChallengeIndex < _myChallengesToGuess.length - 1) {
        _currentChallengeIndex++;
        _answerController.clear();
        _loadCurrentImage();
      } else {
        _showDialog(
          title: 'Félicitations !',
          content: 'Vous avez terminé tous les challenges !',
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context); // Retour à l'écran précédent
              },
              child: const Text('Terminer'),
            ),
          ],
        );
      }
    });
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

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showDialog({
    required String title,
    required String content,
    required List<Widget> actions,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF709CA7),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(content, style: const TextStyle(color: Colors.white70)),
        actions: actions,
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
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
          title: Column(
            children: [
              ShaderMask(
                shaderCallback: (rect) => const LinearGradient(
                  colors: [Color(0xFF00F5FF), Color(0xFF7B61FF)],
                ).createShader(rect),
                child: const Text(
                  'Phase: Devinette',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                'Temps restant: ${_formatTime(_timeLeft)}',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00F5FF), Color(0xFF7B61FF)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00F5FF).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Text(
                'Score: $_score',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        body: SlideTransition(
          position: _slideAnimation,
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : _myChallengesToGuess.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.quiz_outlined,
                        size: 80,
                        color: Colors.white54,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Aucun challenge à deviner',
                        style: TextStyle(color: Colors.white54, fontSize: 18),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Image à deviner
                      Container(
                        width: double.infinity,
                        height: 300,
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
                        child: _currentImageUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  _currentImageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.image_not_supported,
                                            size: 64,
                                            color: Colors.white54,
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            'Image non disponible',
                                            style: TextStyle(
                                              color: Colors.white54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              )
                            : const Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(height: 20),

                      // Challenge info
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF11172B).withOpacity(0.8),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF00F5FF).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Challenge ${_currentChallengeIndex + 1}/${_myChallengesToGuess.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Devinez ce qui est représenté dans l\'image !',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Champ de réponse
                      TextField(
                        controller: _answerController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Votre réponse',
                          labelStyle: TextStyle(color: Colors.white70),
                          hintText: 'Tapez votre réponse ici...',
                          hintStyle: TextStyle(color: Colors.white38),
                          border: OutlineInputBorder(),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                          ),
                        ),
                        onSubmitted: (_) => _submitAnswer(),
                      ),
                      const SizedBox(height: 20),

                      // Boutons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isSubmitting ? null : _submitAnswer,
                              icon: _isSubmitting
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : const Icon(Icons.send, color: Colors.white),
                              label: Text(
                                _isSubmitting ? 'Envoi...' : 'Valider',
                                style: const TextStyle(color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: const BorderSide(
                                    color: Color(0xFF00F5FF),
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _nextChallenge,
                              icon: const Icon(
                                Icons.skip_next,
                                color: Colors.white,
                              ),
                              label: const Text(
                                'Passer',
                                style: TextStyle(color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: const BorderSide(
                                    color: Color(0xFF7B61FF),
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
