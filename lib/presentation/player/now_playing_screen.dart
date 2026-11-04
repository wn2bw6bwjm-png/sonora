import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/haptics/haptics.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/format.dart';
import '../../player/player_controller.dart';
import '../../shared/widgets/cover_art.dart';
import '../../shared/widgets/empty_state.dart';

class NowPlayingScreen extends ConsumerWidget {
  const NowPlayingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final s = ref.watch(playerProvider);
    final ctrl = ref.read(playerProvider.notifier);
    final cur = s.current;
    final back = IconButton(icon: const Icon(Icons.keyboard_arrow_down), onPressed: () => context.pop());
    if (cur == null) {
      return Scaffold(
        appBar: AppBar(leading: back),
        body: const EmptyState(
            icon: Icons.music_note_outlined, title: 'Ничего не играет', message: 'Откройте альбом и нажмите «Слушать».'),
      );
    }
    final d = s.durationMs;
    final posMs = s.position.inMilliseconds;
    return Scaffold(
      appBar: AppBar(
        leading: back,
        title: Text(cur.albumTitle, style: t.textTheme.titleSmall),
        actions: [
          IconButton(
            tooltip: 'Очередь',
            icon: const Icon(Icons.queue_music),
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              showDragHandle: true,
              isScrollControlled: true,
              builder: (_) => const _QueueSheet(),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(Sp.page, Sp.lg, Sp.page, Sp.xl),
        child: Column(children: [
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: CoverArt(seed: cur.coverSeed, path: cur.coverPath),
              ),
            ),
          ),
          const SizedBox(height: Sp.xl),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(cur.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: t.textTheme.headlineMedium),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(cur.artist, style: t.textTheme.titleMedium?.copyWith(color: t.colorScheme.onSurfaceVariant)),
          ),
          const SizedBox(height: Sp.lg),
          Slider(
            min: 0,
            max: (d ?? 1).toDouble(),
            value: d == null ? 0 : posMs.clamp(0, d).toDouble(),
            onChanged: d == null ? null : (v) => ctrl.seek(Duration(milliseconds: v.round())),
          ),
          Row(children: [
            Text(fmtDuration(posMs), style: t.textTheme.bodySmall),
            const Spacer(),
            Text(d == null ? '—' : fmtDuration(d), style: t.textTheme.bodySmall),
          ]),
          const SizedBox(height: Sp.lg),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            IconButton(iconSize: 32, tooltip: 'Назад', icon: const Icon(Icons.skip_previous), onPressed: ctrl.previous),
            const SizedBox(width: Sp.lg),
            IconButton.filled(
              iconSize: 36,
              tooltip: s.playing ? 'Пауза' : 'Играть',
              icon: Icon(s.playing ? Icons.pause : Icons.play_arrow),
              onPressed: () {
                Haptics.light();
                ctrl.toggle();
              },
            ),
            const SizedBox(width: Sp.lg),
            IconButton(iconSize: 32, tooltip: 'Вперёд', icon: const Icon(Icons.skip_next), onPressed: ctrl.next),
          ]),
          const SizedBox(height: Sp.lg),
          if (!s.hasAudio)
            Text(
              'К этому треку не прикреплён аудиофайл: идёт беззвучный таймлайн. Прикрепить свой файл можно на странице альбома.',
              textAlign: TextAlign.center,
              style: t.textTheme.bodySmall,
            ),
        ]),
      ),
    );
  }
}

class _QueueSheet extends ConsumerWidget {
  const _QueueSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final s = ref.watch(playerProvider);
    return SizedBox(
      height: MediaQuery.of(context).size.height * .6,
      child: ListView(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Sp.page, 0, Sp.page, Sp.sm),
          child: Text('Очередь', style: t.textTheme.headlineSmall),
        ),
        for (var i = 0; i < s.queue.length; i++)
          ListTile(
            leading: SizedBox(
              width: 24,
              child: i == s.index
                  ? Icon(Icons.graphic_eq, size: 20, color: t.colorScheme.primary)
                  : Text('${i + 1}', style: t.textTheme.bodySmall),
            ),
            title: Text(
              s.queue[i].title,
              style: t.textTheme.bodyLarge?.copyWith(color: i == s.index ? t.colorScheme.primary : null),
            ),
            trailing: s.queue[i].durationMs == null
                ? null
                : Text(fmtDuration(s.queue[i].durationMs!), style: t.textTheme.bodySmall),
            onTap: () => ref.read(playerProvider.notifier).jumpTo(i),
          ),
      ]),
    );
  }
}
