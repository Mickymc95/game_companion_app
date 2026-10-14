import 'package:flutter/material.dart';
import '../../games/gtav/fixtures.dart';
import 'wiki_tab.dart'; // For WikiDetailScreen

class SearchScreen extends StatelessWidget {
  final String query;

  const SearchScreen({super.key, required this.query});

  @override
  Widget build(BuildContext context) {
    final lowerQuery = query.toLowerCase();

    // Search POIs
    final matchedPois = GTAVFixtures.mapMarkers.where(
      (poi) => poi.title.toLowerCase().contains(lowerQuery) || poi.description.toLowerCase().contains(lowerQuery)
    ).toList();

    // Search Wiki Items
    final matchedWiki = GTAVFixtures.wikiItems.where(
      (item) => item.title.toLowerCase().contains(lowerQuery) || item.description.toLowerCase().contains(lowerQuery)
    ).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Search Results for "$query"'),
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
                    title: Text(poi.title),
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WikiDetailScreen(item: item),
                        ),
                      );
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
