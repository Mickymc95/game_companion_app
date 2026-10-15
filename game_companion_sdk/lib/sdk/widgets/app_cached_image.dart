import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class AppCachedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final BorderRadius? borderRadius;
  final Widget? fallback;
  final IconData? fallbackIcon;
  final Color? fallbackColor;

  const AppCachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit,
    this.borderRadius,
    this.fallback,
    this.fallbackIcon,
    this.fallbackColor,
  });

  Widget _buildFallback(BuildContext context) {
    if (fallback != null) return fallback!;
    return Container(
      width: width,
      height: height,
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      child: Center(
        child: Icon(
          fallbackIcon ?? Icons.image_not_supported,
          color: fallbackColor ?? Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          size: (height != null && height! < 48) ? 20 : 28,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    if (imageUrl.isEmpty) {
      imageWidget = _buildFallback(context);
    } else if (imageUrl.startsWith('assets/')) {
      imageWidget = Image.asset(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildFallback(context),
      );
    } else {
      imageWidget = CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => Container(
          width: width,
          height: height,
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
        errorWidget: (context, url, error) {
          // Attempt offline fallback if URL references a bundled GTAV asset
          final match = RegExp(r'media/gtav/(vehicles|weapons)/([^/?#]+)').firstMatch(imageUrl);
          if (match != null) {
            final category = match.group(1);
            final filename = match.group(2);
            final assetPath = 'assets/media/gtav/$category/$filename';
            return Image.asset(
              assetPath,
              width: width,
              height: height,
              fit: fit,
              errorBuilder: (_, _, _) => _buildFallback(context),
            );
          }
          return _buildFallback(context);
        },
      );
    }

    if (borderRadius != null && borderRadius != BorderRadius.zero) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }
}
