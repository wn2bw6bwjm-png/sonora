import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../data/db/providers.dart';
import '../../player/player_controller.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/name_dialog.dart';
import '../../shared/widgets/track_entry_tile.dart';

Future<void> createPlaylistDialog(BuildContext context, WidgetRef ref) async {
  final name = await promptName(context, title: 'Новый плейлист');
  if (name != null) await ref.read(extrasRepoProvider).createPlaylist(name);
}

class PlaylistScreen extends ConsumerWidget {
  const PlaylistScreen({super.key, required this.id});
  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final repo = ref.read(extrasRepoProvider);
    final playlist = (ref.watch(playlistsProvider).valueOrNull ?? const []).where((p) => p.id == id).firstOrNull;
    final tracks = ref.watch(playlistTracksProvider(id)).valueOrNull ?? const [];
    final back = IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop());
    if (playlist == null) {
      return Scaffold(
        appBar: AppBar(leading: back),
        body: const EmptyState(icon: Icons.queue_music, title: 'Плейлист не найден', message: 'Возможно, он был удалён.'),
      );
    }
    return Scaffold(
      appBar: AppBar(
        leading: back,
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'rename') {
                final n = await promptName(context, title: 'Название плейлиста', initial: playlist.name);
                if (n != null) await repo.renamePlaylist(id, n);
              } else if (v == 'delete') {
                final ok = await confirm(context,
                    title: 'Удалить плейлист?', message: 'Сами треки останутся в библиотеке.', action: 'Удалить');
                if (ok && context.mounted) {
                  context.pop();
                  await repo.deletePlaylist(id);
                }
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'rename', child: Text('Переименовать')),
              PopupMenuItem(value: 'delete', child: Text('Удалить')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: Sp.huge),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Sp.page),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(playlist.name, style: t.textTheme.displaySmall),
              const SizedBox(height: Sp.sm),
              Text('${playlist.count} тр.', style: t.textTheme.bodySmall),
              const SizedBox(height: Sp.lg),
              FilledButton.icon(
                onPressed: tracks.isEmpty
                    ? null
                    : () => ref.read(playerProvider.notifier).playQueue([for (final e in tracks) e.toQueueItem()], 0),
                icon: const Icon(Icons.play_arrow, size: 20),
                label: const Text('Слушать'),
              ),
            ]),
          ),
          const SizedBox(height: Sp.md),
          if (tracks.isEmpty)
            const SizedBox(
              height: 260,
              child: EmptyState(
                  icon: Icons.queue_music,
                  title: 'Плейлист пуст',
                  message: 'Добавляйте треки через меню трека в разделе Tracks.'),
            )
          else
            for (var i = 0; i < tracks.length; i++)
              TrackEntryTile(
                entry: tracks[i],
                onPlay: () => ref.read(playerProvider.notifier).playQueue([for (final e in tracks) e.toQueueItem()], i),
                onRemove: () => repo.removeFromPlaylist(id, tracks[i].trackId),
              ),
        ],
      ),
    );
  }
}
