class GameManifest {
  final String id;
  final String title;
  final int releaseYear;
  final GameStatus status;

  GameManifest({
    required this.id,
    required this.title,
    required this.releaseYear,
    required this.status,
  });
}

enum GameStatus { active, comingSoon }
