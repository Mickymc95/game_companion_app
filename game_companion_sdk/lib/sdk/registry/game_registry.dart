import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_manifest.dart';

final gameRegistryProvider = Provider<GameRegistry>((ref) {
  return GameRegistry();
});

final currentGameIdProvider = StateProvider<String>((ref) => 'gtav');

class GameRegistry {
  final Map<String, GameManifest> _games = {
    'gtav': GameManifest(
      id: 'gtav',
      title: 'Grand Theft Auto V',
      releaseYear: 2013,
      status: GameStatus.active,
    ),
    'gta6': GameManifest(
      id: 'gta6',
      title: 'Grand Theft Auto VI',
      releaseYear: 2025,
      status: GameStatus.comingSoon,
    ),
    'rdr2': GameManifest(
      id: 'rdr2',
      title: 'Red Dead Redemption 2',
      releaseYear: 2018,
      status: GameStatus.comingSoon,
    ),
    'witcher3': GameManifest(
      id: 'witcher3',
      title: 'The Witcher 3: Wild Hunt',
      releaseYear: 2015,
      status: GameStatus.comingSoon,
    ),
  };

  List<GameManifest> get allGames => _games.values.toList();

  GameManifest? getGame(String id) => _games[id];
}
