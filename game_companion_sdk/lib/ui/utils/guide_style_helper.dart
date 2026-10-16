import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

/// The 5 canonical single-player guide categories in GTA V Companion.
const List<String> canonicalGuideCategories = [
  'Money & Stock Market',
  '100% Completion',
  'Stunt Jumps',
  'Aerial & Flight Challenges',
  'Secrets, Weapons & Rare Vehicles',
];

/// Returns the thematic icon associated with a guide category.
IconData getGuideCategoryIcon(String? category) {
  if (category == null || category.isEmpty) {
    return Icons.menu_book;
  }
  final lower = category.toLowerCase();
  if (lower.contains('money') || lower.contains('stock')) {
    return Icons.monetization_on;
  }
  if (lower.contains('100%') || lower.contains('completion')) {
    return Icons.emoji_events;
  }
  if (lower.contains('stunt') || lower.contains('jump')) {
    return Icons.sports_motorsports;
  }
  if (lower.contains('aerial') || lower.contains('flight')) {
    return Icons.flight;
  }
  if (lower.contains('secret') || lower.contains('weapon') || lower.contains('rare')) {
    return Icons.auto_awesome;
  }
  return Icons.category;
}

/// Returns the thematic accent color associated with a guide category.
Color getGuideCategoryColor(String? category) {
  if (category == null || category.isEmpty) {
    return const Color(0xFF90A4AE); // Blue Grey
  }
  final lower = category.toLowerCase();
  if (lower.contains('money') || lower.contains('stock')) {
    return const Color(0xFF00E676); // Vibrant Green
  }
  if (lower.contains('100%') || lower.contains('completion')) {
    return const Color(0xFFFFB300); // Amber / Gold
  }
  if (lower.contains('stunt') || lower.contains('jump')) {
    return const Color(0xFFFF6D00); // Deep Orange
  }
  if (lower.contains('aerial') || lower.contains('flight')) {
    return const Color(0xFF00B0FF); // Light Blue / Cyan
  }
  if (lower.contains('secret') || lower.contains('weapon') || lower.contains('rare')) {
    return const Color(0xFFBA68C8); // Soft Purple
  }
  return const Color(0xFF90A4AE);
}

/// Returns the color coding for difficulty levels (Beginner, Intermediate, Advanced).
Color getGuideDifficultyColor(String? difficulty) {
  if (difficulty == null) return const Color(0xFF9E9E9E);
  switch (difficulty.trim().toLowerCase()) {
    case 'beginner':
    case 'Beginner':
      return const Color(0xFF4CAF50); // Green
    case 'intermediate':
    case 'Intermediate':
      return const Color(0xFFFFB300); // Amber
    case 'advanced':
    case 'Advanced':
      return const Color(0xFFFF5252); // Crimson / Red
    default:
      return const Color(0xFF9E9E9E);
  }
}

/// Returns the icon associated with a difficulty level (Beginner, Intermediate, Advanced).
IconData getGuideDifficultyIcon(String? difficulty) {
  if (difficulty == null) return Icons.bar_chart;
  switch (difficulty.trim().toLowerCase()) {
    case 'beginner':
    case 'Beginner':
      return Icons.signal_cellular_alt_1_bar;
    case 'intermediate':
    case 'Intermediate':
      return Icons.signal_cellular_alt_2_bar;
    case 'advanced':
    case 'Advanced':
      return Icons.signal_cellular_alt;
    default:
      return Icons.bar_chart;
  }
}

/// Extracts an 11-character YouTube video ID from various URL formats.
String? extractYouTubeVideoId(String? url) {
  if (url == null || url.trim().isEmpty) return null;
  final match = RegExp(r'(?:v=|\/)([0-9A-Za-z_-]{11})(?:[&?]|\b|$)').firstMatch(url);
  return match?.group(1);
}

/// Derives the high-quality YouTube thumbnail preview URL.
String? getYouTubeThumbnailUrl(String? url) {
  final videoId = extractYouTubeVideoId(url);
  if (videoId == null) return null;
  return 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
}

/// Reusable metadata badge pill with icon and colored border/background.
Widget buildGuideBadge({
  required IconData icon,
  required String label,
  required Color color,
  Color? backgroundColor,
  double iconSize = 13,
  double fontSize = 11,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: backgroundColor ?? color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: color.withValues(alpha: 0.45),
        width: 1,
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: iconSize, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    ),
  );
}

/// Launches a URL safely with fallback mode and SnackBar feedback.
Future<bool> safeLaunchGuideUrl(BuildContext context, String? urlString) async {
  if (urlString == null || urlString.trim().isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No video URL available.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
    return false;
  }

  final trimmed = urlString.trim();
  Uri? uri;
  try {
    uri = Uri.parse(trimmed);
    if (!uri.hasScheme) {
      uri = Uri.tryParse('https://$trimmed');
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid URL format: $trimmed'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
    return false;
  }

  if (uri == null) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid URL: $trimmed'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
    return false;
  }

  try {
    bool launched = false;
    try {
      // First attempt: external application (e.g. YouTube app or external browser)
      launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Fallback: standard platform default launch
      if (await canLaunchUrl(uri)) {
        launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    }

    if (!launched) {
      // Second fallback attempt
      try {
        if (await canLaunchUrl(uri)) {
          launched = await launchUrl(uri);
        }
      } catch (_) {}
    }

    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open video URL: $trimmed'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
    return launched;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to open video: ${e.toString()}'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
    return false;
  }
}

/// Builds a customized dark-theme [MarkdownStyleSheet] for guide articles.
MarkdownStyleSheet buildGuideMarkdownStyleSheet(BuildContext context) {
  final theme = Theme.of(context);
  return MarkdownStyleSheet.fromTheme(theme).copyWith(
    h1: theme.textTheme.titleLarge?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: 20,
      height: 1.4,
    ),
    h2: theme.textTheme.titleMedium?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: 16,
      height: 1.4,
    ),
    h3: theme.textTheme.titleSmall?.copyWith(
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.w600,
      fontSize: 14,
      height: 1.3,
    ),
    p: theme.textTheme.bodyMedium?.copyWith(
      color: Colors.white.withValues(alpha: 0.9),
      fontSize: 14,
      height: 1.5,
    ),
    code: const TextStyle(
      fontFamily: 'monospace',
      color: Color(0xFF64B5F6),
      fontSize: 13,
      backgroundColor: Colors.transparent,
    ),
    codeblockPadding: const EdgeInsets.all(12),
    codeblockDecoration: BoxDecoration(
      color: const Color(0xFF16181D),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: const Color(0xFF2C2E3B),
        width: 1,
      ),
    ),
    blockquote: theme.textTheme.bodyMedium?.copyWith(
      color: Colors.white.withValues(alpha: 0.85),
      fontStyle: FontStyle.italic,
      height: 1.4,
    ),
    blockquotePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    blockquoteDecoration: BoxDecoration(
      color: const Color(0xFF1E2026),
      borderRadius: BorderRadius.circular(6),
      border: Border(
        left: BorderSide(
          color: theme.colorScheme.primary,
          width: 4,
        ),
      ),
    ),
    a: TextStyle(
      color: theme.colorScheme.primary,
      decoration: TextDecoration.underline,
    ),
    listBullet: TextStyle(
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.bold,
    ),
  );
}
