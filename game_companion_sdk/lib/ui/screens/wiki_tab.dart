import 'package:flutter/material.dart';
import '../../games/gtav/fixtures.dart';
import '../../sdk/models/wiki_item.dart';

class WikiTab extends StatefulWidget {
  const WikiTab({super.key});

  @override
  State<WikiTab> createState() => _WikiTabState();
}

class _WikiTabState extends State<WikiTab> {
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final allItems = GTAVFixtures.wikiItems;
    final categories = allItems.map((i) => i.category).toSet().toList();

    final items = _selectedCategory == null
        ? allItems
        : allItems.where((i) => i.category == _selectedCategory).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _selectedCategory == null,
                  onSelected: (_) {
                    setState(() { _selectedCategory = null; });
                  },
                ),
                const SizedBox(width: 8),
                ...categories.map((cat) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text(cat),
                      selected: _selectedCategory == cat,
                      onSelected: (_) {
                        setState(() { _selectedCategory = cat; });
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(item.thumbnailUrl),
                  ),
                  title: Text(item.title),
                  subtitle: Text(item.category),
                  onTap: () {
                    // Open detailed view with stats
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WikiDetailScreen(item: item),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class WikiDetailScreen extends StatelessWidget {
  final WikiItem item;
  const WikiDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(item.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Image.network(item.thumbnailUrl, height: 200, fit: BoxFit.cover),
          const SizedBox(height: 16),
          Text(item.description, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 24),
          Text('Statistics', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          ...item.stats.entries.map((e) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.key),
                LinearProgressIndicator(
                  value: e.value / 100,
                  minHeight: 12,
                  borderRadius: BorderRadius.circular(6),
                ),
                const SizedBox(height: 12),
              ],
            );
          })
        ],
      ),
    );
  }
}
