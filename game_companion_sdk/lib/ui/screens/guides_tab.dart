import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../games/gtav/fixtures.dart';
import '../providers/scroll_providers.dart';

class GuidesTab extends ConsumerWidget {
  const GuidesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guides = GTAVFixtures.guides;

    return ListView.builder(
      controller: ref.watch(guidesScrollControllerProvider),
      itemCount: guides.length,
      itemBuilder: (context, index) {
        final guide = guides[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ExpansionTile(
            title: Text(guide.title),
            subtitle: Wrap(
              spacing: 8,
              children: guide.tags.map((t) => Chip(label: Text(t), visualDensity: VisualDensity.compact)).toList(),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: MarkdownBody(data: guide.contentMarkdown),
              ),
              if (guide.videoUrl != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Watch Video Guide'),
                    onPressed: () async {
                      final url = Uri.parse(guide.videoUrl!);
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url);
                      }
                    },
                  ),
                )
            ],
          ),
        );
      },
    );
  }
}
