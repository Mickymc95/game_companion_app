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
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/icons/app_icon.png',
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Games Companion',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Select Game',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8),
                            ),
                      ),
                    ],
                  ),
                ),
              ],
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
