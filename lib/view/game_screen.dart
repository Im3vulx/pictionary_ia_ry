import 'package:flutter/material.dart';
import 'package:pictionary_ia_ry/service/api_service.dart';
import 'package:pictionary_ia_ry/view/drawing_screen.dart';
import 'package:pictionary_ia_ry/view/guessing_screen.dart';
import 'package:pictionary_ia_ry/view/results_screen.dart';
import 'dart:async';

class Challenge {
  final String id;
  final String firstWord;
  final String secondWord;
  final String thirdWord;
  final String fourthWord;
  final String fifthWord;
  final List<String> forbiddenWords;

  Challenge({
    required this.id,
    required this.firstWord,
    required this.secondWord,
    required this.thirdWord,
    required this.fourthWord,
    required this.fifthWord,
    required this.forbiddenWords,
  });

  String get fullPhrase =>
      '$firstWord $secondWord $thirdWord $fourthWord $fifthWord';
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  // Controllers pour les 5 mots
  final word1Controller = TextEditingController();
  final word2Controller = TextEditingController();
  final word3Controller = TextEditingController();
  final word4Controller = TextEditingController();
  final word5Controller = TextEditingController();
  final forbiddenWordController = TextEditingController();

  // Sélections d'articles prédéfinis
  List<bool> article1Selection = [true, false]; // Un/Une
  List<bool> prepositionSelection = [true, false]; // Sur/Dans
  List<bool> article2Selection = [true, false]; // Un/Une

  List<String> forbiddenWords = [];
  List<Challenge> challenges = [];
  bool _isSending = false;
  String _gamePhase = 'challenge'; // challenge, drawing, guessing, finished
  Timer? _phaseTimer;
  int _timeLeft = 180; // 3 minutes en secondes

  String get selectedArticle1 => article1Selection[0] ? "Un" : "Une";
  String get selectedPreposition => prepositionSelection[0] ? "Sur" : "Dans";
  String get selectedArticle2 => article2Selection[0] ? "Un" : "Une";

  @override
  void initState() {
    super.initState();
    _checkGamePhase();
    _startPhaseTimer();
  }

  @override
  void dispose() {
    word1Controller.dispose();
    word2Controller.dispose();
    word3Controller.dispose();
    word4Controller.dispose();
    word5Controller.dispose();
    forbiddenWordController.dispose();
    _phaseTimer?.cancel();
    super.dispose();
  }

  void _startPhaseTimer() {
    _phaseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() {
          _timeLeft--;
        });
      } else {
        timer.cancel();
        _handlePhaseTimeout();
      }
    });
  }

  Future<void> _checkGamePhase() async {
    if (ApiService.gameSessionId == null) return;

    try {
      final status = await ApiService.getSessionStatus(
        ApiService.gameSessionId!,
      );
      if (status != null && status != _gamePhase) {
        setState(() {
          _gamePhase = status;
        });
        _handlePhaseChange();
      }
    } catch (e) {
      print('Erreur vérification phase: $e');
    }
  }

  void _handlePhaseChange() {
    switch (_gamePhase) {
      case 'drawing':
        _navigateToDrawingPhase();
        break;
      case 'guessing':
        _navigateToGuessingPhase();
        break;
      case 'finished':
        _navigateToResults();
        break;
    }
  }

  void _handlePhaseTimeout() {
    _showDialog(
      title: 'Temps écoulé !',
      content: 'Le temps imparti pour cette phase est terminé.',
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            _sendChallenges(); // Envoie automatiquement
          },
          child: const Text('Continuer'),
        ),
      ],
    );
  }

  void _navigateToDrawingPhase() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const DrawingScreen()),
    );
  }

  void _navigateToGuessingPhase() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const GuessingScreen()),
    );
  }

  void _navigateToResults() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ResultsScreen()),
    );
  }

  void _addForbiddenWord() {
    final word = forbiddenWordController.text.trim();
    if (word.isNotEmpty && !forbiddenWords.contains(word.toLowerCase())) {
      setState(() {
        forbiddenWords.add(word.toLowerCase());
        forbiddenWordController.clear();
      });
    }
  }

  void _removeForbiddenWord(int index) {
    setState(() {
      forbiddenWords.removeAt(index);
    });
  }

  void _removeChallenge(String challengeId) {
    setState(() {
      challenges.removeWhere((challenge) => challenge.id == challengeId);
    });
  }

  Future<void> _sendChallenges() async {
    if (challenges.isEmpty) {
      _showErrorSnackBar('Aucun challenge à envoyer');
      return;
    }

    if (ApiService.gameSessionId == null) {
      _showErrorSnackBar('Aucune session active');
      return;
    }

    setState(() {
      _isSending = true;
    });

    int successCount = 0;

    for (final challenge in challenges) {
      try {
        final result = await ApiService.sendChallenge(
          ApiService.gameSessionId!,
          firstWord: challenge.firstWord,
          secondWord: challenge.secondWord,
          thirdWord: challenge.thirdWord,
          fourthWord: challenge.fourthWord,
          fifthWord: challenge.fifthWord,
          forbiddenWords: challenge.forbiddenWords,
        );

        if (result != null) {
          successCount++;
        }
      } catch (e) {
        print('Erreur envoi challenge ${challenge.id}: $e');
      }
    }

    setState(() {
      _isSending = false;
    });

    if (successCount == challenges.length) {
      _showSuccessSnackBar('$successCount challenge(s) envoyé(s) !');
      setState(() {
        challenges.clear();
      });
      _waitForOtherPlayers();
    } else {
      _showErrorSnackBar('Erreur lors de l\'envoi de certains challenges');
    }
  }

  void _waitForOtherPlayers() {
    _showDialog(
      title: 'Challenges envoyés !',
      content: 'En attente que tous les joueurs terminent leurs challenges...',
      barrierDismissible: false,
    );

    // Vérifier périodiquement si on peut passer à la phase suivante
    Timer.periodic(const Duration(seconds: 2), (timer) {
      _checkGamePhase();
      if (_gamePhase != 'challenge') {
        timer.cancel();
        Navigator.pop(context); // Ferme le dialog d'attente
      }
    });
  }

  void _addChallenge() {
    // Validation
    if (word1Controller.text.trim().isEmpty ||
        word2Controller.text.trim().isEmpty ||
        word3Controller.text.trim().isEmpty ||
        word4Controller.text.trim().isEmpty ||
        word5Controller.text.trim().isEmpty) {
      _showErrorSnackBar('Veuillez remplir tous les mots');
      return;
    }

    if (challenges.length >= 3) {
      _showErrorSnackBar('Maximum 3 challenges par joueur');
      return;
    }

    final newChallenge = Challenge(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      firstWord: selectedArticle1,
      secondWord: word1Controller.text.trim(),
      thirdWord: selectedPreposition,
      fourthWord: selectedArticle2,
      fifthWord: word2Controller.text.trim(),
      forbiddenWords: List.from(forbiddenWords),
    );

    setState(() {
      challenges.add(newChallenge);

      // Réinitialiser les champs
      word1Controller.clear();
      word2Controller.clear();
      word3Controller.clear();
      word4Controller.clear();
      word5Controller.clear();
      forbiddenWords.clear();
      article1Selection = [true, false];
      prepositionSelection = [true, false];
      article2Selection = [true, false];
    });
  }

  void _showDialog({
    required String title,
    required String content,
    List<Widget>? actions,
    bool barrierDismissible = true,
  }) {
    showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF709CA7),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(content, style: const TextStyle(color: Colors.white70)),
        actions:
            actions ??
            [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK', style: TextStyle(color: Colors.white)),
              ),
            ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
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

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Widget _buildToggleButtons({
    required String label,
    required List<bool> selection,
    required List<String> options,
    required Function(int) onPressed,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ToggleButtons(
          isSelected: selection,
          onPressed: onPressed,
          borderRadius: BorderRadius.circular(8),
          selectedColor: Colors.white,
          fillColor: const Color(0xFF137C8B),
          color: Colors.white,
          children: options
              .map(
                (option) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(option),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildChallengeCard(Challenge challenge) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFF709CA7),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Challenge #${challenges.indexOf(challenge) + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => _removeChallenge(challenge.id),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Supprimer ce challenge',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2C5F66),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                challenge.fullPhrase,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            if (challenge.forbiddenWords.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Mots interdits:',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: challenge.forbiddenWords.map((word) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF137C8B),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      word,
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
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
                  'Phase: Création des challenges',
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
            if (challenges.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: _isSending
                    ? const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: _sendChallenges,
                        icon: const Icon(
                          Icons.send,
                          color: Colors.white,
                          size: 18,
                        ),
                        label: Text(
                          'Envoyer (${challenges.length}/3)',
                          style: const TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
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
          ],
        ),
        body: challenges.isEmpty
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
                      'Créez vos challenges',
                      style: TextStyle(color: Colors.white54, fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Vous devez créer 3 challenges pour l\'équipe adverse',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Temps restant: ${_formatTime(_timeLeft)}',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: challenges.length,
                itemBuilder: (context, index) =>
                    _buildChallengeCard(challenges[index]),
              ),
        floatingActionButton: challenges.length < 3
            ? Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00F5FF), Color(0xFF7B61FF)],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00F5FF).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: FloatingActionButton.extended(
                  backgroundColor: Colors.transparent,
                  onPressed: () => _showChallengeCreationDialog(),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: Text(
                    'Challenge ${challenges.length + 1}/3',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              )
            : null,
      ),
    );
  }

  void _showChallengeCreationDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF11172B).withOpacity(0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: const Color(0xFF00F5FF).withOpacity(0.3),
              width: 1,
            ),
          ),
          title: const Text(
            'Nouveau challenge',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Structure: Article1 + Mot1 + Préposition + Article2 + Mot2
                _buildToggleButtons(
                  label: "Article 1",
                  selection: article1Selection,
                  options: ["Un", "Une"],
                  onPressed: (int index) {
                    setDialogState(() {
                      for (int i = 0; i < article1Selection.length; i++) {
                        article1Selection[i] = i == index;
                      }
                    });
                  },
                ),

                TextField(
                  controller: word1Controller,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Premier mot (ex: chat)',
                    hintStyle: TextStyle(color: Colors.white70),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                _buildToggleButtons(
                  label: "Préposition",
                  selection: prepositionSelection,
                  options: ["Sur", "Dans"],
                  onPressed: (int index) {
                    setDialogState(() {
                      for (int i = 0; i < prepositionSelection.length; i++) {
                        prepositionSelection[i] = i == index;
                      }
                    });
                  },
                ),

                _buildToggleButtons(
                  label: "Article 2",
                  selection: article2Selection,
                  options: ["Un", "Une"],
                  onPressed: (int index) {
                    setDialogState(() {
                      for (int i = 0; i < article2Selection.length; i++) {
                        article2Selection[i] = i == index;
                      }
                    });
                  },
                ),

                TextField(
                  controller: word2Controller,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Deuxième mot (ex: camion)',
                    hintStyle: TextStyle(color: Colors.white70),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Mots interdits
                const Text(
                  'Mots interdits',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: forbiddenWordController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Ajouter un mot interdit',
                          hintStyle: TextStyle(color: Colors.white70),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                          ),
                        ),
                        onSubmitted: (_) {
                          _addForbiddenWord();
                          setDialogState(() {});
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                        _addForbiddenWord();
                        setDialogState(() {});
                      },
                      icon: const Icon(Icons.add, color: Colors.white),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFF137C8B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (forbiddenWords.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C5F66),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: forbiddenWords.asMap().entries.map((entry) {
                        final index = entry.key;
                        final word = entry.value;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF137C8B),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                word,
                                style: const TextStyle(color: Colors.white),
                              ),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () {
                                  _removeForbiddenWord(index);
                                  setDialogState(() {});
                                },
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                const SizedBox(height: 16),

                // Aperçu
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C5F66),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white38),
                  ),
                  child: Text(
                    'Aperçu: $selectedArticle1 ${word1Controller.text.isEmpty ? '[mot1]' : word1Controller.text} $selectedPreposition $selectedArticle2 ${word2Controller.text.isEmpty ? '[mot2]' : word2Controller.text}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Annuler',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                _addChallenge();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF137C8B),
              ),
              child: const Text(
                'Ajouter',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
