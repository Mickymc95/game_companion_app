import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'ui/theme/app_theme.dart';
import 'ui/screens/shell_screen.dart';
import 'ui/screens/map_tab.dart';
import 'ui/screens/wiki_tab.dart';
import 'ui/screens/guides_tab.dart';
import 'ui/screens/search_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sdk/storage/collection_tracker.dart';
import 'sdk/models/wiki_item.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const GameCompanionApp(),
    ),
  );
}

final _router = GoRouter(
  initialLocation: '/map',
  routes: [
    GoRoute(
      path: '/',
      redirect: (context, state) => '/map',
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ShellScreen(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/map',
              builder: (context, state) => const MapTab(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/wiki',
              builder: (context, state) => const WikiTab(),
              routes: [
                GoRoute(
                  path: 'detail',
                  builder: (context, state) {
                    final item = state.extra as WikiItem?;
                    if (item == null) {
                      // Fallback for web refresh without extra state
                      return const Scaffold(body: Center(child: Text('Item not found')));
                    }
                    return WikiDetailScreen(item: item);
                  },
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/guides',
              builder: (context, state) => const GuidesTab(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/search',
      builder: (context, state) {
        final query = state.extra as String? ?? '';
        return SearchScreen(query: query);
      },
    ),
  ],
);

class GameCompanionApp extends StatelessWidget {
  const GameCompanionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Game Companion',
      theme: appTheme,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
