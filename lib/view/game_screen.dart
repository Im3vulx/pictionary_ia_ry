import 'package:flutter/material.dart';

class Challenge {
  final int id;
  final String phrase;
  final List<String> forbiddenWords;

  Challenge({
    required this.id,
    required this.phrase,
    required this.forbiddenWords,
  });
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final word1Controller = TextEditingController();
  final word2Controller = TextEditingController();
  final forbiddenWordController = TextEditingController();

  List<bool> article1Selection = [true, false];
  List<bool> article2Selection = [true, false];
  List<bool> article3Selection = [true, false];

  List<String> forbiddenWords = [];
  List<Challenge> challenges = [];
  int nextChallengeId = 1;

  String get selectedArticle1 => article1Selection[0] ? "Un" : "Une";
  String get selectedArticle2 => article2Selection[0] ? "Sur" : "Dans";
  String get selectedArticle3 => article3Selection[0] ? "Un" : "Une";

  @override
  void dispose() {
    word1Controller.dispose();
    word2Controller.dispose();
    forbiddenWordController.dispose();
    super.dispose();
  }

  void _addForbiddenWord() {
    if (forbiddenWordController.text.trim().isNotEmpty) {
      setState(() {
        forbiddenWords.add(forbiddenWordController.text.trim());
        forbiddenWordController.clear();
      });
    }
  }

  void _removeForbiddenWord(int index) {
    setState(() {
      forbiddenWords.removeAt(index);
    });
  }

  void _removeChallenge(int challengeId) {
    setState(() {
      challenges.removeWhere((challenge) => challenge.id == challengeId);
    });
  }

  void _sendChallenges() {
    if (challenges.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucun challenge à envoyer'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // TODO: Implémenter l'envoi des challenges
    // chagement pour les joueurs qui sont prêts à jouer (attend des autres joueurs qui n'ont pas fini de créer leurs challenges) et sauvegardes les challenges dans la partie en cours

    debugPrint("Envoi de ${challenges.length} challenge(s)");
    for (final challenge in challenges) {
      debugPrint("Challenge ${challenge.id}: ${challenge.phrase}");
      debugPrint("Mots interdits: ${challenge.forbiddenWords.join(', ')}");
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${challenges.length} challenge(s) envoyé(s) !'),
        backgroundColor: Colors.green,
      ),
    );

    setState(() {
      challenges.clear();
      nextChallengeId = 1;
    });
  }

  void _addUniverse() {
    if (word1Controller.text.trim().isEmpty ||
        word2Controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir les deux mots'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final phrase =
        "$selectedArticle1 ${word1Controller.text.trim()} $selectedArticle2 $selectedArticle3 ${word2Controller.text.trim()}";

    final newChallenge = Challenge(
      id: nextChallengeId,
      phrase: phrase,
      forbiddenWords: List.from(forbiddenWords),
    );

    setState(() {
      challenges.add(newChallenge);
      nextChallengeId++;

      // Réinitialiser les champs
      word1Controller.clear();
      word2Controller.clear();
      forbiddenWords.clear();
      article1Selection = [true, false];
      article2Selection = [true, false];
      article3Selection = [true, false];
    });

    debugPrint("Challenge ajouté : $phrase");
    debugPrint("Mots interdits : ${newChallenge.forbiddenWords.join(', ')}");
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
                  'Challenge #${challenge.id}',
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
                challenge.phrase,
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
    return Scaffold(
      backgroundColor: const Color(0xFF2C5F66),
      appBar: AppBar(
        backgroundColor: const Color(0xFF137C8B),
        title: const Text(
          'Mes Challenges',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          if (challenges.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ElevatedButton.icon(
                onPressed: _sendChallenges,
                icon: const Icon(Icons.send, color: Colors.white, size: 18),
                label: Text(
                  'Envoyer (${challenges.length})',
                  style: const TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
        ],
      ),
      body: challenges.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.quiz_outlined, size: 80, color: Colors.white54),
                  SizedBox(height: 16),
                  Text(
                    'Aucun challenge créé',
                    style: TextStyle(color: Colors.white54, fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Appuyez sur + pour créer votre premier challenge',
                    style: TextStyle(color: Colors.white38, fontSize: 14),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: challenges.length,
              itemBuilder: (context, index) {
                return _buildChallengeCard(challenges[index]);
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF137C8B),
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              return StatefulBuilder(
                builder: (context, setDialogState) {
                  return AlertDialog(
                    backgroundColor: const Color(0xFF709CA7),
                    title: const Text(
                      'Nouveau challenge',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    content: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildToggleButtons(
                            label: "Article 1",
                            selection: article1Selection,
                            options: ["Un", "Une"],
                            onPressed: (int index) {
                              setDialogState(() {
                                setState(() {
                                  for (
                                    int i = 0;
                                    i < article1Selection.length;
                                    i++
                                  ) {
                                    article1Selection[i] = i == index;
                                  }
                                });
                              });
                            },
                          ),
                          TextField(
                            controller: word1Controller,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Votre premier mot',
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
                            selection: article2Selection,
                            options: ["Sur", "Dans"],
                            onPressed: (int index) {
                              setDialogState(() {
                                setState(() {
                                  for (
                                    int i = 0;
                                    i < article2Selection.length;
                                    i++
                                  ) {
                                    article2Selection[i] = i == index;
                                  }
                                });
                              });
                            },
                          ),
                          _buildToggleButtons(
                            label: "Article 2",
                            selection: article3Selection,
                            options: ["Un", "Une"],
                            onPressed: (int index) {
                              setDialogState(() {
                                setState(() {
                                  for (
                                    int i = 0;
                                    i < article3Selection.length;
                                    i++
                                  ) {
                                    article3Selection[i] = i == index;
                                  }
                                });
                              });
                            },
                          ),
                          TextField(
                            controller: word2Controller,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Votre deuxième mot',
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
                                      borderSide: BorderSide(
                                        color: Colors.white,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  onSubmitted: (_) => {
                                    _addForbiddenWord(),
                                    setDialogState(() {}),
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: () {
                                  _addForbiddenWord();
                                  setDialogState(() {});
                                },
                                icon: const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                ),
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
                                children: forbiddenWords.asMap().entries.map((
                                  entry,
                                ) {
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
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
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
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2C5F66),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white38),
                            ),
                            child: Text(
                              'Aperçu: $selectedArticle1 ${word1Controller.text.isEmpty ? '[mot1]' : word1Controller.text} $selectedArticle2 $selectedArticle3 ${word2Controller.text.isEmpty ? '[mot2]' : word2Controller.text}',
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
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text(
                          'Annuler',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          _addUniverse();
                          Navigator.of(context).pop();
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
                  );
                },
              );
            },
          );
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
