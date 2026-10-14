import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../sdk/registry/game_registry.dart';
import '../../sdk/models/game_manifest.dart';

class GameSwitcherDrawer extends ConsumerWidget {
  const GameSwitcherDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registry = ref.watch(gameRegistryProvider);
    final currentGameId = ref.watch(currentGameIdProvider);
    final games = registry.allGames;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
            child: Text(
              'Select Game',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          ...games.map((game) {
            final isSelected = game.id == currentGameId;
            return ListTile(
              title: Text(game.title),
              subtitle: game.status == GameStatus.comingSoon
                  ? const Text('Coming Soon')
                  : null,
              selected: isSelected,
              onTap: () {
                ref.read(currentGameIdProvider.notifier).state = game.id;
                Navigator.of(context).pop();
              },
            );
          }),
        ],
      ),
    );
  }
}
