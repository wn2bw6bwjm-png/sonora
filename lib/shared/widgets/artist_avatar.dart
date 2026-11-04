import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../data/media/image_store.dart';

class ArtistAvatar extends StatelessWidget {
  const ArtistAvatar({super.key, required this.name, this.imagePath, this.size = 48});
  final String name;
  final String? imagePath;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final initials = name.trim().isEmpty ? '?' : name.trim().characters.first.toUpperCase();
    final fallback = ColoredBox(
      color: t.colorScheme.outline,
      child: Center(child: Text(initials, style: t.textTheme.titleMedium)),
    );
    final file = ImageStore.resolve(imagePath);
    final Widget content;
    if (ImageStore.isUrl(imagePath)) {
      content = CachedNetworkImage(
        imageUrl: imagePath!,
        fit: BoxFit.cover,
        memCacheWidth: 300,
        placeholder: (_, __) => fallback,
        errorWidget: (_, __, ___) => fallback,
      );
    } else if (file != null) {
      content = Image.file(File(file), fit: BoxFit.cover, cacheWidth: 300, errorBuilder: (_, __, ___) => fallback);
    } else {
      content = fallback;
    }
    return ClipOval(child: SizedBox(width: size, height: size, child: content));
  }
}
