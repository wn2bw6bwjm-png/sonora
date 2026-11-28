import 'package:flutter/material.dart';
import 'package:sonora/core/themes/app_theme.dart';
import 'package:sonora/domain/entities/track.dart';

class MiniPlayer extends StatelessWidget {
  final Track? track;

  const MiniPlayer({super.key, this.track});

  @override
  Widget build(BuildContext context) {
    if (track == null) return const SizedBox.shrink();

    return Container(
      color: AppTheme.cardColor,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _buildCover(),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  track!.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
                Text(
                  track!.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          const Icon(Icons.skip_previous, size: 22, color: AppTheme.textPrimary),
          IconButton(
            icon: const Icon(Icons.play_arrow, size: 26),
            color: AppTheme.textPrimary,
            onPressed: () {},
          ),
          const Icon(Icons.skip_next, size: 22, color: AppTheme.textPrimary),
        ],
      ),
    );
  }

  Widget _buildCover() {
    if (track!.coverUrl != null && track!.coverUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.network(
          track!.coverUrl!,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(),
        ),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Icon(Icons.music_note,
          color: AppTheme.textSecondary, size: 20),
    );
  }
}