import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class AppCachedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final BorderRadius? borderRadius;

  const AppCachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget = CachedNetworkImage(
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
      errorWidget: (context, url, error) => Container(
        width: width,
        height: height,
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        child: const Center(
          child: Icon(Icons.image_not_supported),
        ),
      ),
    );

    if (borderRadius != null && borderRadius != BorderRadius.zero) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }
}
