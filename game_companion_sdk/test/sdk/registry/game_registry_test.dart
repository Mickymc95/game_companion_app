import 'package:flutter_test/flutter_test.dart';
import 'package:game_companion_sdk/sdk/registry/game_registry.dart';
import 'package:game_companion_sdk/sdk/models/game_manifest.dart';

void main() {
  group('GameRegistry', () {
    late GameRegistry registry;

    setUp(() {
      registry = GameRegistry();
    });

    test('Loads predefined games', () {
      final games = registry.allGames;
      expect(games.length, 4);
      expect(games.any((g) => g.id == 'gtav'), isTrue);
      expect(games.any((g) => g.id == 'gta6'), isTrue);
    });

    test('Retrieves specific game by id', () {
      final game = registry.getGame('gtav');
      expect(game, isNotNull);
      expect(game!.title, 'Grand Theft Auto V');
      expect(game.status, GameStatus.active);
    });

    test('Returns null for unknown game id', () {
      final game = registry.getGame('unknown_game');
      expect(game, isNull);
    });
  });
}
