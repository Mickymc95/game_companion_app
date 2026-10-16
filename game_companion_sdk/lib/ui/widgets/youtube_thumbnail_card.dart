import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../utils/guide_style_helper.dart';

/// Clickable YouTube video preview card displaying a 16:9 thumbnail,
/// centered circular red play button overlay, dark offline fallback,
/// and a dedicated "Watch on YouTube" action button.
class YoutubeThumbnailCard extends StatelessWidget {
  final String videoUrl;
  final String? thumbnailUrl;
  final String? title;

  const YoutubeThumbnailCard({
    super.key,
    required this.videoUrl,
    this.thumbnailUrl,
    this.title,
  });

  Widget _buildOfflineFallback(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFF1E2026),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.play_circle_outline,
            size: 48,
            color: Colors.white.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 8),
          Text(
            'Video Preview',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Watch on YouTube',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayButton() {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFFE50914).withValues(alpha: 0.92),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Center(
        child: Icon(
          Icons.play_arrow,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (videoUrl.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final effectiveThumbnail = thumbnailUrl ?? getYouTubeThumbnailUrl(videoUrl);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => safeLaunchGuideUrl(context, videoUrl),
            borderRadius: BorderRadius.circular(12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: effectiveThumbnail != null && effectiveThumbnail.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: effectiveThumbnail,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: const Color(0xFF1E2026),
                                child: const Center(
                                  child: SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: CircularProgressIndicator(strokeWidth: 2.5),
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => _buildOfflineFallback(context),
                            )
                          : _buildOfflineFallback(context),
                    ),
                    Center(
                      child: _buildPlayButton(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE50914),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text(
                'Watch on YouTube',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              onPressed: () => safeLaunchGuideUrl(context, videoUrl),
            ),
          ],
        ),
      ],
    );
  }
}
