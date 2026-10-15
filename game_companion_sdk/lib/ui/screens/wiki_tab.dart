import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../sdk/widgets/app_cached_image.dart';
import '../providers/scroll_providers.dart';
import '../providers/wiki_providers.dart';
import '../utils/wiki_icon_helper.dart';
import '../widgets/wiki_item_thumbnail.dart';

class WikiTab extends ConsumerStatefulWidget {
  const WikiTab({super.key});

  @override
  ConsumerState<WikiTab> createState() => _WikiTabState();
}

class _WikiTabState extends ConsumerState<WikiTab> {
  String? _selectedCategory;

  IconData _getCategoryIcon(String? category) {
    if (category == null) return Icons.grid_view;
    final cat = category.toLowerCase();
    if (cat.contains('vehicle')) return Icons.directions_car;
    if (cat.contains('weapon')) return Icons.gps_fixed;
    return Icons.category;
  }

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
                      avatar: Icon(
                        _getCategoryIcon(null),
                        size: 16,
                        color: _selectedCategory == null
                            ? Theme.of(context).colorScheme.onSecondaryContainer
                            : null,
                      ),
                      label: const Text('All'),
                      selected: _selectedCategory == null,
                      onSelected: (_) {
                        setState(() { _selectedCategory = null; });
                      },
                    ),
                    const SizedBox(width: 8),
                    ...categories.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          avatar: Icon(
                            _getCategoryIcon(cat),
                            size: 16,
                            color: isSelected
                                ? Theme.of(context).colorScheme.onSecondaryContainer
                                : null,
                          ),
                          label: Text(cat),
                          selected: isSelected,
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
                  final meta = getWikiItemMetadata(item);

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    elevation: 1.5,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      leading: WikiItemThumbnail(item: item),
                      title: Text(
                        item.title,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Row(
                          children: [
                            Text(
                              item.category,
                              style: TextStyle(
                                color: meta.accentColor,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                            if (meta.subType.isNotEmpty && meta.subType != item.category) ...[
                              Text(
                                ' • ${meta.subType}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12),
                              ),
                            ],
                          ],
                        ),
                      ),
                      trailing: Icon(
                        Icons.chevron_right,
                        color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                        size: 20,
                      ),
                      onTap: () {
                        // Open detailed view with stats
                        context.push('/wiki/detail', extra: item);
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
