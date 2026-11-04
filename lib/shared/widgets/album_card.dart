import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';
import '../../domain/entities/album_view.dart';
import 'cover_art.dart';

class AlbumCard extends StatelessWidget {
  const AlbumCard({super.key, required this.album, required this.onTap, this.heroTag, this.width = 140});
  final AlbumView album;
  final VoidCallback onTap;
  final String? heroTag;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cover = CoverArt(seed: album.coverSeed, path: album.coverPath);
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            heroTag == null ? cover : Hero(tag: heroTag!, child: cover),
            const SizedBox(height: Sp.sm),
            Text(album.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.textTheme.titleSmall),
            Text(album.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
