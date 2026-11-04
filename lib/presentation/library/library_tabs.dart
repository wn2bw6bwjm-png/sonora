import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/theme/tokens.dart';
import '../../data/db/providers.dart';
import '../../player/player_controller.dart';
import '../../shared/widgets/album_tile.dart';
import '../../shared/widgets/artist_avatar.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/track_entry_tile.dart';
import 'import_tracks.dart';
import 'playlist_screen.dart';

class TracksTab extends ConsumerStatefulWidget {
  const TracksTab({super.key});
  @override
  ConsumerState<TracksTab> createState() => _TracksTabState();
}

class _TracksTabState extends ConsumerState<TracksTab> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(allTracksProvider).valueOrNull ?? const [];
    if (all.isEmpty) {
      return EmptyState(
        icon: Icons.music_note_outlined,
        title: 'Треков пока нет',
        message: 'Добавьте свои аудиофайлы: можно сразу несколько, альбом создавать не нужно.',
        actionLabel: 'Добавить треки',
        onAction: () => importTracksFlow(context, ref),
      );
    }
    final q = _q.trim().toLowerCase();
    final list = q.isEmpty
        ? all
        : all
            .where((e) =>
                e.title.toLowerCase().contains(q) ||
                e.artist.toLowerCase().contains(q) ||
                e.albumTitle.toLowerCase().contains(q))
            .toList();
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(Sp.page, Sp.sm, Sp.page, Sp.sm),
        child: Row(children: [
          Expanded(
            child: TextField(
              onChanged: (v) => setState(() => _q = v),
              decoration: const InputDecoration(hintText: 'Поиск по трекам', prefixIcon: Icon(Icons.search), isDense: true),
            ),
          ),
          IconButton(
            tooltip: 'Добавить треки',
            icon: const Icon(Icons.add),
            onPressed: () => importTracksFlow(context, ref),
          ),
        ]),
      ),
      const Divider(),
      Expanded(
        child: list.isEmpty
            ? const EmptyState(icon: Icons.search_off, title: 'Ничего не найдено', message: 'Измените запрос.')
            : ListView.builder(
                itemCount: list.length,
                itemBuilder: (_, i) => TrackEntryTile(
                  entry: list[i],
                  onPlay: () => ref.read(playerProvider.notifier).playQueue([for (final e in list) e.toQueueItem()], i),
                ),
              ),
      ),
    ]);
  }
}

class PlaylistsTab extends ConsumerWidget {
  const PlaylistsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final lists = ref.watch(playlistsProvider).valueOrNull ?? const [];
    if (lists.isEmpty) {
      return EmptyState(
        icon: Icons.queue_music,
        title: 'Плейлистов пока нет',
        message: 'Соберите свои треки в плейлисты.',
        actionLabel: 'Создать плейлист',
        onAction: () => createPlaylistDialog(context, ref),
      );
    }
    return ListView.builder(
      itemCount: lists.length,
      itemBuilder: (_, i) => ListTile(
        leading: const Icon(Icons.queue_music),
        title: Text(lists[i].name, style: t.textTheme.titleMedium),
        subtitle: Text('${lists[i].count} тр.'),
        onTap: () => context.push(Routes.playlist(lists[i].id)),
      ),
    );
  }
}

class FavoritesTab extends ConsumerWidget {
  const FavoritesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albums = (ref.watch(albumsProvider).valueOrNull ?? const []).where((a) => a.isFavorite).toList();
    final artists = ref.watch(favoriteArtistsProvider).valueOrNull ?? const [];
    final tracks = ref.watch(favoriteTracksProvider).valueOrNull ?? const [];
    if (albums.isEmpty && artists.isEmpty && tracks.isEmpty) {
      return const EmptyState(
          icon: Icons.favorite_border,
          title: 'Избранного пока нет',
          message: 'Отмечайте альбомы, исполнителей и треки сердечком.');
    }
    return ListView(padding: const EdgeInsets.only(bottom: Sp.xl), children: [
      if (albums.isNotEmpty) ...[
        const SectionHeader('Альбомы'),
        for (final a in albums)
          AlbumTile(
            album: a,
            heroTag: 'fv-${a.id}',
            onTap: () => context.push(Routes.album(a.id), extra: 'fv-${a.id}'),
          ),
      ],
      if (artists.isNotEmpty) ...[
        const SectionHeader('Исполнители'),
        for (final a in artists)
          ListTile(
            leading: ArtistAvatar(name: a.name, imagePath: a.imagePath, size: 44),
            title: Text(a.name),
            onTap: () => context.push(Routes.artist(a.id)),
          ),
      ],
      if (tracks.isNotEmpty) ...[
        const SectionHeader('Треки'),
        for (var i = 0; i < tracks.length; i++)
          TrackEntryTile(
            entry: tracks[i],
            onPlay: () => ref.read(playerProvider.notifier).playQueue([for (final e in tracks) e.toQueueItem()], i),
          ),
      ],
    ]);
  }
}

class RecentTab extends ConsumerWidget {
  const RecentTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albums = (ref.watch(albumsProvider).valueOrNull ?? const []).take(30).toList();
    if (albums.isEmpty) {
      return const EmptyState(
          icon: Icons.schedule, title: 'Пока ничего нет', message: 'Здесь будут последние добавленные альбомы.');
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: Sp.sm, bottom: Sp.xl),
      itemCount: albums.length,
      itemBuilder: (_, i) => AlbumTile(
        album: albums[i],
        heroTag: 'lr-${albums[i].id}',
        onTap: () => context.push(Routes.album(albums[i].id), extra: 'lr-${albums[i].id}'),
      ),
    );
  }
}
