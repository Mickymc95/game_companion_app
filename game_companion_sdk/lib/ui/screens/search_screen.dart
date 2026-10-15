import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../games/gtav/fixtures.dart';
import '../providers/wiki_providers.dart';

class SearchScreen extends ConsumerWidget {
  final String query;

  const SearchScreen({super.key, required this.query});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lowerQuery = query.toLowerCase();

    // Search POIs
    final matchedPois = GTAVFixtures.mapMarkers.where(
      (poi) => poi.name.toLowerCase().contains(lowerQuery) || poi.description.toLowerCase().contains(lowerQuery)
    ).toList();

    // Search Wiki Items
    final wikiItemsAsync = ref.watch(wikiItemsProvider);
    final allWikiItems = wikiItemsAsync.valueOrNull ?? [];

    final matchedWiki = allWikiItems.where(
      (item) => item.title.toLowerCase().contains(lowerQuery) || item.description.toLowerCase().contains(lowerQuery)
    ).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Search Results for "\$query"'),
      ),
      body: CustomScrollView(
        slivers: [
          if (matchedPois.isEmpty && matchedWiki.isEmpty)
            const SliverFillRemaining(
              child: Center(child: Text('No results found.')),
            ),

          if (matchedPois.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Map Locations', style: Theme.of(context).textTheme.titleMedium),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final poi = matchedPois[index];
                  return ListTile(
                    leading: const Icon(Icons.location_on),
                    title: Text(poi.name),
                    subtitle: Text(poi.category),
                    onTap: () {
                      // Navigate to Map Tab centered on POI (For now, we'll just go back and pop)
                      Navigator.pop(context);
                    },
                  );
                },
                childCount: matchedPois.length,
              ),
            ),
          ],

          if (matchedWiki.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Wiki Entries', style: Theme.of(context).textTheme.titleMedium),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = matchedWiki[index];
                  return ListTile(
                    leading: const Icon(Icons.library_books),
                    title: Text(item.title),
                    subtitle: Text(item.category),
                    onTap: () {
                      context.push('/wiki/detail', extra: item);
                    },
                  );
                },
                childCount: matchedWiki.length,
              ),
            ),
          ]
        ],
      ),
    );
  }
}
