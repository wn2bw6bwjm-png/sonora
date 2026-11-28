import 'package:flutter/material.dart';
import 'package:sonora/core/themes/app_theme.dart';
import 'package:sonora/domain/entities/track.dart';

class TrackTile extends StatelessWidget {
  final Track track;
  final bool isCurrent;
  final VoidCallback onTap;
  final Widget? trailing;

  const TrackTile({
    super.key,
    required this.track,
    required this.onTap,
    this.isCurrent = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: _buildCover(),
      title: Text(
        track.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: isCurrent ? AppTheme.accentColor : AppTheme.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        track.artist,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: AppTheme.textSecondary),
      ),
      trailing: trailing ??
          Text(
            _formatDuration(track.duration),
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
    );
  }

  Widget _buildCover() {
    if (track.coverUrl != null && track.coverUrl!.isNotEmpty) {
      return Hero(
        tag: 'album-art-${track.id}',
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.network(
            track.coverUrl!,
            width: 48,
            height: 48,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _placeholder(),
          ),
        ),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Icon(Icons.music_note,
          color: AppTheme.textSecondary, size: 22),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(1);
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}