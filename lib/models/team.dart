import 'player.dart';

class Team {
  final String name;
  int score;
  List<Player> players;

  Team({
    required this.name,
    required this.players,
    this.score = 100,
  });
}