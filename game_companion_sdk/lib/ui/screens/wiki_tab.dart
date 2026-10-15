import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../sdk/widgets/app_cached_image.dart';
import '../providers/scroll_providers.dart';
import '../providers/wiki_providers.dart';

class WikiTab extends ConsumerStatefulWidget {
  const WikiTab({super.key});

  @override
  ConsumerState<WikiTab> createState() => _WikiTabState();
}

class _WikiTabState extends ConsumerState<WikiTab> {
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final wikiItemsAsyncValue = ref.watch(wikiItemsProvider);

    return wikiItemsAsyncValue.when(
      data: (allItems) {
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
                controller: ref.watch(wikiScrollControllerProvider),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      leading: SizedBox(
                        width: 40,
                        height: 40,
                        child: AppCachedImage(
                          imageUrl: item.thumbnailUrl,
                          fit: BoxFit.cover,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      title: Text(item.title),
                      subtitle: Text(item.category),
                      onTap: () {
                        // Open detailed view with stats
                        context.go('/wiki/detail', extra: item);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }
}
