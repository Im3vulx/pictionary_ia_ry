import 'package:flutter/material.dart';
import 'package:pictionary_ia_ry/models/player.dart';
import 'package:pictionary_ia_ry/models/team.dart';
import 'package:pictionary_ia_ry/view/game_screen.dart';

class TeamScreen extends StatefulWidget {
  final String nickname;

  const TeamScreen({super.key, required this.nickname});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  late Team blueTeam;
  late Team redTeam;
  bool _hasStarted = false;

  @override
  void initState() {
    super.initState();
    blueTeam = Team(name: 'Équipe Bleue', players: []);
    redTeam = Team(name: 'Équipe Rouge', players: []);

    blueTeam.players.add(Player(name: widget.nickname));
  }

  @override
  Widget build(BuildContext context) {
    final int blueCount = blueTeam.players.length;
    final int redCount = redTeam.players.length;
    final int totalCount = blueCount + redCount;
    final bool canStart = blueCount >= 2 && redCount >= 2 && totalCount >= 4;

    if (canStart && !_hasStarted) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeStartGame());
    }

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
            const Center(
              child: Text(
                'Composition des équipes:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 16),
            _buildTeamSection(team: blueTeam),
            const SizedBox(height: 12),
            _buildTeamSection(team: redTeam),
            SizedBox(height: 8),
            Text(
              canStart
                  ? 'Les équipes sont prêtes. La partie va démarrer.'
                  : 'Il faut au minimum 4 joueurs et 2 par équipe pour lancer la partie.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamSection({required Team team}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${team.name} :'),
        ...team.players.map((player) {
          final bool isCurrentUser = player.name == widget.nickname;
          return Text(isCurrentUser ? '${player.name} (vous)' : player.name);
        }).toList(),
        if (team.players.isEmpty) const Text('<en attente>'),
      ],
    );
  }

  void _maybeStartGame() {
    if (_hasStarted) return;
    final bool canStart =
        blueTeam.players.length >= 2 && redTeam.players.length >= 2;
    if (!canStart) return;

    _hasStarted = true;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('La partie commence !')));
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => GameScreen() ) );
  }
}
