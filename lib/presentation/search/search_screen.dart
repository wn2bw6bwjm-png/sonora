import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/format.dart';
import '../../data/db/providers.dart';
import '../../domain/entities/album_view.dart';
import '../../player/player_controller.dart';
import '../../shared/widgets/album_tile.dart';
import '../../shared/widgets/artist_avatar.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/track_entry_tile.dart';

enum _Scope { all, albums, artists, tracks, genres, collections }

enum _Sort { recent, title, rating, year }

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});
  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _c = TextEditingController();
  _Scope _scope = _Scope.all;
  _Sort _sort = _Sort.recent;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _go(String route, {Object? extra}) {
    ref.read(searchRepoProvider).add(_c.text);
    context.push(route, extra: extra);
  }

  List<AlbumView> _sorted(List<AlbumView> l) {
    final s = [...l];
    switch (_sort) {
      case _Sort.recent:
        break;
      case _Sort.title:
        s.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      case _Sort.rating:
        s.sort((a, b) => (b.rating ?? -1).compareTo(a.rating ?? -1));
      case _Sort.year:
        s.sort((a, b) => (b.year ?? 0).compareTo(a.year ?? 0));
    }
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final q = _c.text.trim().toLowerCase();
    final albums = ref.watch(albumsProvider).valueOrNull ?? const [];
    final artists = ref.watch(artistsProvider).valueOrNull ?? const [];
    final tracks = ref.watch(allTracksProvider).valueOrNull ?? const [];
    final cols = ref.watch(collectionsProvider).valueOrNull ?? const [];
    final genreMap = ref.watch(albumGenresProvider).valueOrNull ?? const <int, List<String>>{};
    final history = ref.watch(searchHistoryProvider).valueOrNull ?? const <String>[];

    final fa = _sorted(albums
        .where((a) =>
            a.title.toLowerCase().contains(q) ||
            a.artist.toLowerCase().contains(q) ||
            (genreMap[a.id] ?? const []).any((g) => g.toLowerCase().contains(q)))
        .toList());
    final fr = artists.where((a) => a.name.toLowerCase().contains(q)).toList();
    final ft = tracks
        .where((e) => e.title.toLowerCase().contains(q) || e.artist.toLowerCase().contains(q))
        .take(30)
        .toList();
    final genreCounts = <String, int>{};
    for (final l in genreMap.values) {
      for (final g in l) {
        if (g.toLowerCase().contains(q)) genreCounts[g] = (genreCounts[g] ?? 0) + 1;
      }
    }
    final fg = genreCounts.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    final fc = cols.where((c) => c.name.toLowerCase().contains(q)).toList();

    bool show(_Scope s) => _scope == _Scope.all || _scope == s;
    final nothing = (!show(_Scope.albums) || fa.isEmpty) &&
        (!show(_Scope.artists) || fr.isEmpty) &&
        (!show(_Scope.tracks) || ft.isEmpty) &&
        (!show(_Scope.genres) || fg.isEmpty) &&
        (!show(_Scope.collections) || fc.isEmpty);

    Widget body;
    if (q.isEmpty) {
      body = history.isEmpty
          ? const EmptyState(
              icon: Icons.search,
              title: 'Начните вводить',
              message: 'Поиск по альбомам, исполнителям, трекам, жанрам и коллекциям.')
          : ListView(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(Sp.page, Sp.lg, Sp.sm, 0),
                child: Row(children: [
                  Expanded(child: Text('НЕДАВНИЕ ЗАПРОСЫ', style: t.textTheme.labelSmall)),
                  TextButton(onPressed: () => ref.read(searchRepoProvider).clear(), child: const Text('Очистить')),
                ]),
              ),
              for (final h in history)
                ListTile(leading: const Icon(Icons.history), title: Text(h), onTap: () => setState(() => _c.text = h)),
            ]);
    } else if (nothing) {
      body = const EmptyState(
          icon: Icons.search_off, title: 'Ничего не найдено', message: 'Попробуйте другой запрос или фильтр.');
    } else {
      body = ListView(padding: const EdgeInsets.only(bottom: Sp.xl), children: [
        if (show(_Scope.albums) && fa.isNotEmpty) ...[
          const SectionHeader('Альбомы'),
          for (final a in fa)
            AlbumTile(
              album: a,
              heroTag: 'sa-${a.id}',
              onTap: () => _go(Routes.album(a.id), extra: 'sa-${a.id}'),
            ),
        ],
        if (show(_Scope.artists) && fr.isNotEmpty) ...[
          const SectionHeader('Исполнители'),
          for (final a in fr)
            ListTile(
              leading: ArtistAvatar(name: a.name, imagePath: a.imagePath, size: 44),
              title: Text(a.name),
              onTap: () => _go(Routes.artist(a.id)),
            ),
        ],
        if (show(_Scope.tracks) && ft.isNotEmpty) ...[
          const SectionHeader('Треки'),
          for (var i = 0; i < ft.length; i++)
            TrackEntryTile(
              entry: ft[i],
              onPlay: () {
                ref.read(searchRepoProvider).add(_c.text);
                ref.read(playerProvider.notifier).playQueue([for (final e in ft) e.toQueueItem()], i);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Играет: ${ft[i].title}')));
              },
            ),
        ],
        if (show(_Scope.genres) && fg.isNotEmpty) ...[
          const SectionHeader('Жанры'),
          for (final g in fg)
            ListTile(
              leading: const Icon(Icons.label_outline),
              title: Text(g.key),
              subtitle: Text(albumsWord(g.value)),
              onTap: () => setState(() {
                _c.text = g.key;
                _scope = _Scope.albums;
              }),
            ),
        ],
        if (show(_Scope.collections) && fc.isNotEmpty) ...[
          const SectionHeader('Коллекции'),
          for (final c in fc)
            ListTile(
              leading: const Icon(Icons.folder_outlined),
              title: Text(c.name),
              subtitle: Text(albumsWord(c.count)),
              onTap: () => _go(Routes.collection(c.id)),
            ),
        ],
      ]);
    }

    const labels = {
      _Scope.all: 'Все',
      _Scope.albums: 'Альбомы',
      _Scope.artists: 'Исполнители',
      _Scope.tracks: 'Треки',
      _Scope.genres: 'Жанры',
      _Scope.collections: 'Коллекции',
    };
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        titleSpacing: 0,
        title: TextField(
          controller: _c,
          autofocus: true,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(hintText: 'Альбомы, исполнители, треки', border: InputBorder.none),
        ),
        actions: [
          if (q.isNotEmpty) IconButton(icon: const Icon(Icons.close), onPressed: () => setState(_c.clear)),
          PopupMenuButton<_Sort>(
            tooltip: 'Сортировка альбомов',
            icon: const Icon(Icons.sort),
            initialValue: _sort,
            onSelected: (s) => setState(() => _sort = s),
            itemBuilder: (_) => const [
              PopupMenuItem(value: _Sort.recent, child: Text('Недавно добавленные')),
              PopupMenuItem(value: _Sort.title, child: Text('По названию')),
              PopupMenuItem(value: _Sort.rating, child: Text('По оценке')),
              PopupMenuItem(value: _Sort.year, child: Text('По году')),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: Sp.page, vertical: Sp.xs),
              children: [
                for (final e in labels.entries)
                  Padding(
                    padding: const EdgeInsets.only(right: Sp.sm),
                    child: ChoiceChip(
                      label: Text(e.value),
                      selected: _scope == e.key,
                      showCheckmark: false,
                      onSelected: (_) => setState(() => _scope = e.key),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      body: body,
    );
  }
}
