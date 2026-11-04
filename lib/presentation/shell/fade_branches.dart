import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';

/// Контейнер вкладок: состояние каждой сохраняется, активная плавно проявляется.
class FadeBranches extends StatelessWidget {
  const FadeBranches({super.key, required this.index, required this.children});
  final int index;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Stack(children: [
        for (var i = 0; i < children.length; i++)
          Offstage(
            offstage: i != index,
            child: TickerMode(
              enabled: i == index,
              child: AnimatedOpacity(
                opacity: i == index ? 1 : 0,
                duration: Dur.normal,
                curve: Dur.curve,
                child: children[i],
              ),
            ),
          ),
      ]);
}
