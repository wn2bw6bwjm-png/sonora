import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/haptics/haptics.dart';
import '../../core/router/routes.dart';
import '../../core/theme/tokens.dart';
import '../../player/player_controller.dart';
import '../../shared/widgets/cover_art.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(playerProvider);
    final cur = s.current;
    if (cur == null) return const SizedBox.shrink();
    final t = Theme.of(context);
    final ctrl = ref.read(playerProvider.notifier);
    final d = s.durationMs;
    final progress = (d != null && d > 0) ? (s.position.inMilliseconds / d).clamp(0.0, 1.0) : null;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      const Divider(),
      InkWell(
        onTap: () => context.push(Routes.player),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Sp.page, vertical: Sp.sm),
          child: Row(children: [
            CoverArt(seed: cur.coverSeed, path: cur.coverPath, size: 40, radius: Rad.smAll),
            const SizedBox(width: Sp.md),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(cur.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.textTheme.titleSmall),
                Text(cur.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.textTheme.bodySmall),
              ]),
            ),
            IconButton(
              tooltip: s.playing ? 'Пауза' : 'Играть',
              icon: Icon(s.playing ? Icons.pause : Icons.play_arrow),
              onPressed: () {
                Haptics.light();
                ctrl.toggle();
              },
            ),
            IconButton(tooltip: 'Следующий', icon: const Icon(Icons.skip_next), onPressed: ctrl.next),
            IconButton(tooltip: 'Закрыть', icon: const Icon(Icons.close, size: 20), onPressed: ctrl.stop),
          ]),
        ),
      ),
      LinearProgressIndicator(
        value: progress,
        minHeight: 2,
        color: t.colorScheme.primary,
        backgroundColor: t.colorScheme.outline,
      ),
    ]);
  }
}
