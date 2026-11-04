import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/format.dart';
import '../../domain/entities/album_view.dart';
import 'cover_art.dart';

class AlbumTile extends StatelessWidget {
  const AlbumTile({super.key, required this.album, required this.onTap, this.trailing, this.heroTag});
  final AlbumView album;
  final VoidCallback onTap;
  final Widget? trailing;

  /// Уникальный в пределах экрана тег для Hero-перехода обложки.
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cover = CoverArt(seed: album.coverSeed, path: album.coverPath, size: 56);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Sp.page, vertical: Sp.sm),
        child: Row(
          children: [
            heroTag == null ? cover : Hero(tag: heroTag!, child: cover),
            const SizedBox(width: Sp.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(album.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    album.year == null ? album.artist : '${album.artist} · ${album.year}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (album.isFavorite)
              Padding(
                padding: const EdgeInsets.only(right: Sp.sm),
                child: Icon(Icons.favorite, size: 16, color: t.colorScheme.primary),
              ),
            if (album.rating != null)
              Text(fmtRating(album.rating!), style: t.textTheme.titleMedium?.copyWith(color: t.colorScheme.primary)),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
