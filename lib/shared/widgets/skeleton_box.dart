import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';

class SkeletonBox extends StatefulWidget {
  const SkeletonBox({super.key, this.width, this.height = 16});
  final double? width;
  final double height;
  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final line = Theme.of(context).colorScheme.outline;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(color: Color.lerp(line, line.withAlpha(110), _c.value), borderRadius: Rad.smAll),
      ),
    );
  }
}
