import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../data/media/image_store.dart';
import '../../core/theme/tokens.dart';

/// Детерминированная обложка по seed. Плоские формы, без градиентов.
class CoverArt extends StatelessWidget {
  const CoverArt({super.key, required this.seed, this.size, this.path, this.radius = Rad.mdAll});
  final String seed;
  final String? path;
  final double? size;
  final BorderRadius radius;

  static const _palettes = [
    [Color(0xFF2B3A42), Color(0xFFE0825E)],
    [Color(0xFF3D2C2E), Color(0xFFD9B99B)],
    [Color(0xFF1F3A34), Color(0xFFC9D6A3)],
    [Color(0xFF2E2A47), Color(0xFFE6C36A)],
    [Color(0xFF4A2F27), Color(0xFFF0E1CF)],
    [Color(0xFF22303C), Color(0xFF9FB7C9)],
  ];

  @override
  Widget build(BuildContext context) {
    final h = seed.hashCode.abs();
    final p = _palettes[h % _palettes.length];
    final generated = CustomPaint(painter: _CoverPainter(p[0], p[1], h ~/ 7 % 3, h));
    final file = ImageStore.resolve(path);
    final art = AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: radius,
        child: ImageStore.isUrl(path)
            ? CachedNetworkImage(
                imageUrl: path!,
                fit: BoxFit.cover,
                memCacheWidth: 700,
                placeholder: (_, __) => generated,
                errorWidget: (_, __, ___) => generated,
              )
            : file == null
                ? generated
                : Image.file(File(file), fit: BoxFit.cover, cacheWidth: 700, errorBuilder: (_, __, ___) => generated),
      ),
    );
    return size == null ? art : SizedBox(width: size, height: size, child: art);
  }
}

class _CoverPainter extends CustomPainter {
  _CoverPainter(this.bg, this.fg, this.shape, this.h);
  final Color bg, fg;
  final int shape, h;

  @override
  void paint(Canvas c, Size s) {
    c.drawRect(Offset.zero & s, Paint()..color = bg);
    final p = Paint()..color = fg;
    final off = (h % 5) / 10 * s.width;
    if (shape == 0) {
      c.drawCircle(Offset(s.width * .5 + off * .3, s.height * .5), s.width * .28, p);
    } else if (shape == 1) {
      c.drawRect(Rect.fromLTWH(s.width * .18, s.height * .18 + off * .2, s.width * .64, s.height * .22), p);
    } else {
      final path = Path()
        ..moveTo(s.width * .2, s.height * .8)
        ..lineTo(s.width * .5, s.height * .2)
        ..lineTo(s.width * .8, s.height * .8)
        ..close();
      c.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(_CoverPainter o) => o.bg != bg || o.fg != fg || o.shape != shape || o.h != h;
}
