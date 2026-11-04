import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';
import '../../data/media/image_store.dart';
import 'cover_art.dart';

/// Мозаика 2x2 из обложек альбомов коллекции.
class CollectionCover extends StatelessWidget {
  const CollectionCover({super.key, required this.seeds, this.size = 64, this.path});
  final List<String> seeds;
  final String? path;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    if (ImageStore.isUrl(path) || ImageStore.resolve(path) != null) return CoverArt(seed: 'collection', path: path, size: size);
    if (seeds.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(borderRadius: Rad.mdAll, border: Border.all(color: c.outline)),
        child: Icon(Icons.folder_outlined, color: c.onSurfaceVariant),
      );
    }
    if (seeds.length < 4) return CoverArt(seed: seeds.first, size: size);
    final h = size / 2;
    return ClipRRect(
      borderRadius: Rad.mdAll,
      child: SizedBox(
        width: size,
        height: size,
        child: Column(children: [
          for (var r = 0; r < 2; r++)
            Row(children: [
              for (var i = 0; i < 2; i++)
                CoverArt(seed: seeds[r * 2 + i], size: h, radius: BorderRadius.zero),
            ]),
        ]),
      ),
    );
  }
}
