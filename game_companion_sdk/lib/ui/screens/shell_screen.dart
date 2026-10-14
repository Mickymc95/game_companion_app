import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../sdk/registry/game_registry.dart';
import '../../sdk/models/game_manifest.dart';
import '../widgets/game_switcher_drawer.dart';
import '../widgets/global_search_bar.dart';

class ShellScreen extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const ShellScreen({super.key, required this.navigationShell});

  void _onItemTapped(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentGameId = ref.watch(currentGameIdProvider);
    final registry = ref.watch(gameRegistryProvider);
    final game = registry.getGame(currentGameId);

    if (game?.status == GameStatus.comingSoon) {
      return Scaffold(
        appBar: AppBar(
          title: Text(game?.title ?? ''),
        ),
        drawer: const GameSwitcherDrawer(),
        body: Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${game?.title} is Coming Soon!',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const GlobalSearchBar(),
      ),
      drawer: const GameSwitcherDrawer(),
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.library_books),
            label: 'Wiki',
          ),
          NavigationDestination(
            icon: Icon(Icons.article),
            label: 'Guides',
          ),
        ],
      ),
    );
  }
}
