import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../sdk/models/guide_article.dart';
import '../providers/guides_provider.dart';
import '../providers/scroll_providers.dart';
import '../utils/guide_style_helper.dart';
import '../widgets/youtube_thumbnail_card.dart';

/// Screen displaying the curated single-player guides library with
/// dynamic category filter chips, modern expandable Material 3 cards,
/// rich metadata badges, dark-theme markdown rendering, and clickable
/// YouTube thumbnail preview cards with safe URL launching.
class GuidesTab extends ConsumerWidget {
  const GuidesTab({super.key});

  Widget _buildFilterChipsBar(
    BuildContext context,
    WidgetRef ref,
    String? selectedCategory,
    List<String> categories,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: SizedBox(
        height: 40,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final cat = categories[index];
            final isAll = cat.toLowerCase() == 'all';
            final isSelected = isAll
                ? (selectedCategory == null ||
                    selectedCategory.isEmpty ||
                    selectedCategory.toLowerCase() == 'all')
                : (selectedCategory?.toLowerCase() == cat.toLowerCase());

            final icon = getGuideCategoryIcon(isAll ? null : cat);
            final color = getGuideCategoryColor(isAll ? null : cat);

            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: FilterChip(
                avatar: Icon(
                  icon,
                  size: 16,
                  color: isSelected
                      ? Theme.of(context).colorScheme.onSecondaryContainer
                      : color,
                ),
                label: Text(cat),
                selected: isSelected,
                onSelected: (selected) {
                  if (isAll || !selected) {
                    ref.read(selectedGuideCategoryProvider.notifier).state = null;
                  } else {
                    ref.read(selectedGuideCategoryProvider.notifier).state = cat;
                  }
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildGuideCard(BuildContext context, GuideArticle guide) {
    final hasVideo = guide.videoUrl != null && guide.videoUrl!.isNotEmpty;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: Colors.transparent),
        ),
        collapsedShape: const RoundedRectangleBorder(
          side: BorderSide(color: Colors.transparent),
        ),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: EdgeInsets.zero,
        title: Text(
          guide.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  // Category badge (colored pill with thematic icon)
                  buildGuideBadge(
                    icon: getGuideCategoryIcon(guide.category),
                    label: guide.category,
                    color: getGuideCategoryColor(guide.category),
                  ),
                  // Difficulty badge (color-coded)
                  buildGuideBadge(
                    icon: getGuideDifficultyIcon(guide.difficulty),
                    label: guide.difficulty,
                    color: getGuideDifficultyColor(guide.difficulty),
                  ),
                  // Read time badge
                  buildGuideBadge(
                    icon: Icons.schedule,
                    label: '${guide.readTimeMinutes} min',
                    color: const Color(0xFF64B5F6),
                  ),
                  // Video indicator badge
                  if (hasVideo)
                    buildGuideBadge(
                      icon: Icons.videocam,
                      label: 'Video',
                      color: const Color(0xFFE50914),
                    ),
                ],
              ),
              if (guide.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: guide.tags.map((t) {
                    return Chip(
                      label: Text(t, style: const TextStyle(fontSize: 11)),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: MarkdownBody(
              data: guide.contentMarkdown,
              styleSheet: buildGuideMarkdownStyleSheet(context),
              onTapLink: (text, href, title) {
                safeLaunchGuideUrl(context, href);
              },
            ),
          ),
          if (hasVideo)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: YoutubeThumbnailCard(
                videoUrl: guide.videoUrl!,
                thumbnailUrl: guide.youtubeThumbnailUrl,
                title: guide.title,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(selectedGuideCategoryProvider);
    final filteredGuidesAsync = ref.watch(filteredGuidesProvider);
    final allGuidesAsync = ref.watch(guidesProvider);

    // Compute categories: "All" + 5 canonical categories + any extra custom categories
    final allGuides = allGuidesAsync.valueOrNull ?? const <GuideArticle>[];
    final extraCategories = allGuides
        .map((g) => g.category)
        .where((c) => c.isNotEmpty && !canonicalGuideCategories.contains(c))
        .toSet();

    final categories = [
      'All',
      ...canonicalGuideCategories,
      ...extraCategories,
    ];

    return filteredGuidesAsync.when(
      data: (guides) {
        return Column(
          children: [
            _buildFilterChipsBar(context, ref, selectedCategory, categories),
            Expanded(
              child: guides.isEmpty
                  ? ListView(
                      controller: ref.watch(guidesScrollControllerProvider),
                      children: [
                        const SizedBox(height: 60),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant
                                    .withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No guides found in this category.',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      controller: ref.watch(guidesScrollControllerProvider),
                      itemCount: guides.length,
                      itemBuilder: (context, index) {
                        return _buildGuideCard(context, guides[index]);
                      },
                    ),
            ),
          ],
        );
      },
      loading: () => Column(
        children: [
          _buildFilterChipsBar(context, ref, selectedCategory, categories),
          const Expanded(
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ],
      ),
      error: (error, stack) => Column(
        children: [
          _buildFilterChipsBar(context, ref, selectedCategory, categories),
          Expanded(
            child: Center(
              child: Text('Error loading guides: $error'),
            ),
          ),
        ],
      ),
    );
  }
}
