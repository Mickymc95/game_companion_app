import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../sdk/models/wiki_item.dart';
import '../../sdk/widgets/app_cached_image.dart';

class WikiDetailScreen extends StatelessWidget {
  final WikiItem item;
  const WikiDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(item.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/wiki');
            }
          },
          tooltip: 'Back',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCachedImage(
            imageUrl: item.thumbnailUrl,
            height: 200,
            fit: BoxFit.cover,
            borderRadius: BorderRadius.circular(12),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.category, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.primary)),
                  const SizedBox(height: 8),
                  Text(item.description, style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Statistics', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          ...item.stats.entries.map((e) {
            final double statValue = (e.value is num) ? (e.value as num).toDouble() : 0.0;
            final String formattedValue = '${(statValue * 100).toStringAsFixed(0)}%';

            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(e.key, style: Theme.of(context).textTheme.titleSmall),
                      Text(formattedValue, style: Theme.of(context).textTheme.labelMedium),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: statValue,
                    minHeight: 12,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ],
              ),
            );
          })
        ],
      ),
    );
  }
}
