class Player {
  final String id;
  final String name;
  bool isDrawer;
  final String? teamColor;

  Player({
    required this.id,
    required this.name,
    this.isDrawer = false,
    this.teamColor,
  });
}
