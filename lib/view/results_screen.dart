import 'package:flutter/material.dart';
import 'package:pictionary_ia_ry/service/api_service.dart';
import 'dart:async';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> _sessionChallenges = [];
  bool _isLoading = true;
  int _blueTeamScore = 0;
  int _redTeamScore = 0;

  late AnimationController _slideController;
  late AnimationController _scoreController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scoreAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadSessionChallenges();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _scoreController.dispose();
    super.dispose();
  }

  void _initAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scoreController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack),
        );
    _scoreAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scoreController, curve: Curves.easeOutCubic),
    );

    _slideController.forward();
    _scoreController.forward();
  }

  Future<void> _loadSessionChallenges() async {
    if (ApiService.gameSessionId == null) {
      _showError('Aucune session active');
      return;
    }

    try {
      final challenges = await ApiService.listSessionChallenges(
        ApiService.gameSessionId!,
      );
      if (challenges != null) {
        setState(() {
          _sessionChallenges = challenges;
          _calculateScores();
          _isLoading = false;
        });
      } else {
        _showError('Erreur lors du chargement des résultats');
      }
    } catch (e) {
      _showError('Erreur lors du chargement des résultats');
      print('Erreur load session challenges: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _calculateScores() {
    // Simulation de calcul des scores
    _blueTeamScore = 150;
    _redTeamScore = 120;
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

  Widget _buildTeamScoreCard({
    required String teamName,
    required int score,
    required Color color,
    required IconData icon,
    required bool isWinner,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: isWinner ? Border.all(color: Colors.yellow, width: 3) : null,
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
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      teamName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isWinner)
                      const Text(
                        '🏆 GAGNANT !',
                        style: TextStyle(
                          color: Colors.yellow,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
              AnimatedBuilder(
                animation: _scoreAnimation,
                builder: (context, child) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Text(
                      '${(score * _scoreAnimation.value).round()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeCard(Map<String, dynamic> challenge) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF709CA7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.quiz, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Challenge ${challenge['id'] ?? 'N/A'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Résolu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (challenge['first_word'] != null) ...[
            Text(
              'Phrase: ${challenge['first_word']} ${challenge['second_word'] ?? ''} ${challenge['third_word'] ?? ''} ${challenge['fourth_word'] ?? ''} ${challenge['fifth_word'] ?? ''}',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ],
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
          title: ShaderMask(
            shaderCallback: (rect) => const LinearGradient(
              colors: [Color(0xFF00F5FF), Color(0xFF7B61FF)],
            ).createShader(rect),
            child: const Text(
              'Résultats de la partie',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          centerTitle: true,
        ),
        body: SlideTransition(
          position: _slideAnimation,
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // Titre principal futuriste
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(20),
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
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF00F5FF),
                                    Color(0xFF7B61FF),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: const Icon(
                                Icons.emoji_events,
                                color: Colors.white,
                                size: 48,
                              ),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Partie terminée !',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Voici les résultats finaux',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Scores des équipes
                      _buildTeamScoreCard(
                        teamName: 'Équipe Bleue',
                        score: _blueTeamScore,
                        color: Colors.blue.shade600,
                        icon: Icons.waves,
                        isWinner: _blueTeamScore > _redTeamScore,
                      ),

                      _buildTeamScoreCard(
                        teamName: 'Équipe Rouge',
                        score: _redTeamScore,
                        color: Colors.red.shade600,
                        icon: Icons.local_fire_department,
                        isWinner: _redTeamScore > _blueTeamScore,
                      ),

                      const SizedBox(height: 24),

                      // Section challenges résolus
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF709CA7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.list_alt,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Challenges résolus',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (_sessionChallenges.isEmpty)
                              const Text(
                                'Aucun challenge disponible',
                                style: TextStyle(color: Colors.white70),
                              )
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _sessionChallenges.length,
                                itemBuilder: (context, index) =>
                                    _buildChallengeCard(
                                      _sessionChallenges[index],
                                    ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Boutons d'action
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pushNamedAndRemoveUntil(
                                    context,
                                    '/home',
                                    (route) => false,
                                  );
                                },
                                icon: const Icon(
                                  Icons.home,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  'Retour à l\'accueil',
                                  style: TextStyle(color: Colors.white),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF137C8B),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  // TODO: Implémenter le partage des résultats
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Fonctionnalité de partage à venir !',
                                      ),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.share,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  'Partager les résultats',
                                  style: TextStyle(color: Colors.white),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
