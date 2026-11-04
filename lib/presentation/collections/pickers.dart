import 'package:flutter/material.dart';
import '../../core/haptics/haptics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../core/utils/format.dart';
import '../../data/db/providers.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/name_dialog.dart';

/// Выбор коллекций для одного альбома.
Future<void> showCollectionPicker(BuildContext context, int albumId) => showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _CollectionPicker(albumId: albumId),
    );

/// Выбор альбомов для одной коллекции.
Future<void> showAlbumPicker(BuildContext context, int collectionId) => showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _AlbumPicker(collectionId: collectionId),
    );

class _CollectionPicker extends ConsumerWidget {
  const _CollectionPicker({required this.albumId});
  final int albumId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(collectionRepoProvider);
    final cols = ref.watch(collectionsProvider).valueOrNull ?? const [];
    final member = ref.watch(collectionIdsForProvider(albumId)).valueOrNull ?? const <int>{};
    return SizedBox(
      height: MediaQuery.of(context).size.height * .6,
      child: Column(children: [
        ListTile(
          leading: const Icon(Icons.add),
          title: const Text('Новая коллекция'),
          onTap: () async {
            final name = await promptName(context, title: 'Новая коллекция');
            if (name == null) return;
            final id = await repo.create(name);
            await repo.addAlbum(id, albumId);
          },
        ),
        const Divider(),
        Expanded(
          child: cols.isEmpty
              ? const EmptyState(
                  icon: Icons.folder_outlined,
                  title: 'Нет коллекций',
                  message: 'Создайте первую, чтобы добавить в неё альбом.')
              : ListView(children: [
                  for (final c in cols)
                    CheckboxListTile(
                      value: member.contains(c.id),
                      title: Text(c.name),
                      subtitle: Text(albumsWord(c.count)),
                      onChanged: (v) {
                        Haptics.selection();
                        v == true ? repo.addAlbum(c.id, albumId) : repo.removeAlbum(c.id, albumId);
                      },
                    ),
                ]),
        ),
      ]),
    );
  }
}

class _AlbumPicker extends ConsumerWidget {
  const _AlbumPicker({required this.collectionId});
  final int collectionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(collectionRepoProvider);
    final albums = ref.watch(albumsProvider).valueOrNull ?? const [];
    final member = ref.watch(albumIdsInProvider(collectionId)).valueOrNull ?? const <int>{};
    return SizedBox(
      height: MediaQuery.of(context).size.height * .7,
      child: albums.isEmpty
          ? const EmptyState(
              icon: Icons.album_outlined,
              title: 'Библиотека пуста',
              message: 'Сначала добавьте альбомы в библиотеку.')
          : ListView(padding: const EdgeInsets.only(bottom: Sp.xl), children: [
              for (final a in albums)
                CheckboxListTile(
                  value: member.contains(a.id),
                  title: Text(a.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(a.artist),
                  onChanged: (v) {
                    Haptics.selection();
                    v == true ? repo.addAlbum(collectionId, a.id) : repo.removeAlbum(collectionId, a.id);
                  },
                ),
            ]),
    );
  }
}

/// Выбор плейлистов для одного трека.
Future<void> showPlaylistPicker(BuildContext context, int trackId) => showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _PlaylistPicker(trackId: trackId),
    );

class _PlaylistPicker extends ConsumerWidget {
  const _PlaylistPicker({required this.trackId});
  final int trackId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(extrasRepoProvider);
    final lists = ref.watch(playlistsProvider).valueOrNull ?? const [];
    final member = ref.watch(playlistIdsForTrackProvider(trackId)).valueOrNull ?? const <int>{};
    return SizedBox(
      height: MediaQuery.of(context).size.height * .6,
      child: Column(children: [
        ListTile(
          leading: const Icon(Icons.add),
          title: const Text('Новый плейлист'),
          onTap: () async {
            final name = await promptName(context, title: 'Новый плейлист');
            if (name == null) return;
            final id = await repo.createPlaylist(name);
            await repo.addToPlaylist(id, trackId);
          },
        ),
        const Divider(),
        Expanded(
          child: lists.isEmpty
              ? const EmptyState(
                  icon: Icons.queue_music, title: 'Нет плейлистов', message: 'Создайте первый плейлист для треков.')
              : ListView(children: [
                  for (final p in lists)
                    CheckboxListTile(
                      value: member.contains(p.id),
                      title: Text(p.name),
                      subtitle: Text('${p.count} тр.'),
                      onChanged: (v) {
                        Haptics.selection();
                        v == true ? repo.addToPlaylist(p.id, trackId) : repo.removeFromPlaylist(p.id, trackId);
                      },
                    ),
                ]),
        ),
      ]),
    );
  }
}
