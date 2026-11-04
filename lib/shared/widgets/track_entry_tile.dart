import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/haptics/haptics.dart';
import '../../core/router/routes.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/format.dart';
import '../../data/db/providers.dart';
import '../../domain/entities/track_entry.dart';
import '../../presentation/collections/pickers.dart';
import '../../data/media/image_store.dart';
import 'confirm_dialog.dart';
import 'name_dialog.dart';
import 'cover_art.dart';

class TrackEntryTile extends ConsumerWidget {
  const TrackEntryTile({super.key, required this.entry, required this.onPlay, this.onRemove});
  final TrackEntry entry;
  final VoidCallback onPlay;
  final VoidCallback? onRemove;

  Future<void> _rename(BuildContext context, WidgetRef ref) async {
    final name = await promptName(context, title: 'Название трека', initial: entry.title);
    if (name != null) await ref.read(extrasRepoProvider).renameTrack(entry.trackId, name);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final ok = await confirm(context,
        title: 'Удалить трек?',
        message: 'Трек и его копия внутри SONORA будут удалены. Исходный файл на телефоне останется. Альбом останется в библиотеке.',
        action: 'Удалить');
    if (!ok) return;
    final file = await ref.read(extrasRepoProvider).deleteTrack(entry.trackId);
    await ImageStore.remove(file);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    return InkWell(
      onTap: onPlay,
      child: Padding(
        padding: const EdgeInsets.only(left: Sp.page, right: Sp.xs, top: Sp.xs, bottom: Sp.xs),
        child: Row(children: [
          CoverArt(seed: entry.coverSeed, path: entry.coverPath, size: 44),
          const SizedBox(width: Sp.md),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(entry.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.textTheme.titleSmall),
              Text('${entry.artist} · ${entry.albumTitle}',
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: t.textTheme.bodySmall),
            ]),
          ),
          if (entry.durationMs != null) Text(fmtDuration(entry.durationMs!), style: t.textTheme.bodySmall),
          IconButton(
            tooltip: 'Избранное',
            iconSize: 20,
            icon: Icon(entry.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: entry.isFavorite ? t.colorScheme.primary : null),
            onPressed: () {
              Haptics.light();
              ref.read(extrasRepoProvider).toggleFavoriteTrack(entry.trackId);
            },
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'play') onPlay();
              if (v == 'playlist') showPlaylistPicker(context, entry.trackId);
              if (v == 'album') context.push(Routes.album(entry.albumId));
              if (v == 'remove') onRemove?.call();
              if (v == 'delete') _delete(context, ref);
              if (v == 'rename') _rename(context, ref);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'play', child: Text('Играть')),
              const PopupMenuItem(value: 'rename', child: Text('Переименовать')),
              const PopupMenuItem(value: 'playlist', child: Text('В плейлист')),
              const PopupMenuItem(value: 'album', child: Text('Открыть альбом')),
              if (onRemove != null) const PopupMenuItem(value: 'remove', child: Text('Убрать из плейлиста')),
              const PopupMenuItem(value: 'delete', child: Text('Удалить трек')),
            ],
          ),
        ]),
      ),
    );
  }
}
