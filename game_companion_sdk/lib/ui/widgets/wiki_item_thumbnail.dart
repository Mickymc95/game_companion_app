import 'package:flutter/material.dart';
import '../../sdk/models/wiki_item.dart';
import '../../sdk/widgets/app_cached_image.dart';
import '../utils/wiki_icon_helper.dart';

/// Displays the leading visual thumbnail for a [WikiItem] with its
/// category-specific accent border, cached/bundled image, fallback icon,
/// and category badge.
class WikiItemThumbnail extends StatelessWidget {
  final WikiItem item;
  final double size;

  const WikiItemThumbnail({
    super.key,
    required this.item,
    this.size = 52,
  });

  @override
  Widget build(BuildContext context) {
    final meta = getWikiItemMetadata(item);
    final badgeSize = (size * 0.35).clamp(16.0, 20.0);
    final iconSize = (badgeSize * 0.6).clamp(10.0, 13.0);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: meta.accentColor.withValues(alpha: 0.35),
              width: 1.2,
            ),
          ),
          child: AppCachedImage(
            imageUrl: item.thumbnailUrl,
            fit: BoxFit.contain,
            borderRadius: BorderRadius.circular(8),
            fallbackIcon: meta.icon,
            fallbackColor: meta.accentColor,
          ),
        ),
        Positioned(
          right: -3,
          bottom: -3,
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: meta.accentColor,
                width: 1.5,
              ),
            ),
            child: Icon(
              meta.icon,
              size: iconSize,
              color: meta.accentColor,
            ),
          ),
        ),
      ],
    );
  }
}

