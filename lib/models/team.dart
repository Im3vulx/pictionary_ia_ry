import 'player.dart';

class Team {
  final String name;
  int score;
  List<Player> players;
  final String? color;

  Team({
    required this.name,
    required this.players,
    this.score = 100,
    this.color,
  });
}