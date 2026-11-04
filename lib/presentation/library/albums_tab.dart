import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/theme/tokens.dart';
import '../../data/db/providers.dart';
import '../../domain/entities/album_view.dart';
import '../../shared/widgets/album_card.dart';
import '../../shared/widgets/album_tile.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/skeleton_box.dart';
import 'album_form_sheet.dart';

enum LibSort { recent, title, rating, year }

class AlbumsTab extends ConsumerStatefulWidget {
  const AlbumsTab({super.key});
  @override
  ConsumerState<AlbumsTab> createState() => _AlbumsTabState();
}

class _AlbumsTabState extends ConsumerState<AlbumsTab> {
  String _query = '';
  LibSort _sort = LibSort.recent;
  bool _favOnly = false;
  String? _genre;

  List<AlbumView> _apply(List<AlbumView> all, Map<int, List<String>> genres) {
    final q = _query.trim().toLowerCase();
    final list = all.where((a) {
      if (_favOnly && !a.isFavorite) return false;
      if (_genre != null && !(genres[a.id] ?? const []).contains(_genre)) return false;
      return q.isEmpty || a.title.toLowerCase().contains(q) || a.artist.toLowerCase().contains(q);
    }).toList();
    switch (_sort) {
      case LibSort.recent:
        break;
      case LibSort.title:
        list.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      case LibSort.rating:
        list.sort((a, b) => (b.rating ?? -1).compareTo(a.rating ?? -1));
      case LibSort.year:
        list.sort((a, b) => (b.year ?? 0).compareTo(a.year ?? 0));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final albums = ref.watch(albumsProvider);
    final genreMap = ref.watch(albumGenresProvider).valueOrNull ?? const <int, List<String>>{};
    final allGenres = ({for (final l in genreMap.values) ...l}.toList()..sort());
    void open(AlbumView a, String tag) => context.push(Routes.album(a.id), extra: tag);

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(Sp.page, Sp.sm, Sp.sm, Sp.sm),
        child: Row(children: [
          Expanded(
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                  hintText: 'Поиск по библиотеке', prefixIcon: Icon(Icons.search), isDense: true),
            ),
          ),
          IconButton(
            tooltip: 'Только избранное',
            isSelected: _favOnly,
            icon: const Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite, color: t.colorScheme.primary),
            onPressed: () => setState(() => _favOnly = !_favOnly),
          ),
          if (allGenres.isNotEmpty)
            PopupMenuButton<String>(
              tooltip: 'Фильтр по жанру',
              icon: Icon(Icons.filter_list, color: _genre == null ? null : t.colorScheme.primary),
              onSelected: (g) => setState(() => _genre = g.isEmpty ? null : g),
              itemBuilder: (_) => [
                const PopupMenuItem<String>(value: '', child: Text('Все жанры')),
                for (final g in allGenres) PopupMenuItem<String>(value: g, child: Text(g)),
              ],
            ),
          PopupMenuButton<LibSort>(
            tooltip: 'Сортировка',
            icon: const Icon(Icons.sort),
            initialValue: _sort,
            onSelected: (s) => setState(() => _sort = s),
            itemBuilder: (_) => const [
              PopupMenuItem(value: LibSort.recent, child: Text('Недавно добавленные')),
              PopupMenuItem(value: LibSort.title, child: Text('По названию')),
              PopupMenuItem(value: LibSort.rating, child: Text('По оценке')),
              PopupMenuItem(value: LibSort.year, child: Text('По году')),
            ],
          ),
        ]),
      ),
      const Divider(),
      Expanded(
        child: albums.when(
          loading: () => ListView(
            padding: const EdgeInsets.all(Sp.page),
            children: [
              for (var i = 0; i < 6; i++)
                const Padding(padding: EdgeInsets.only(bottom: Sp.lg), child: SkeletonBox(height: 56)),
            ],
          ),
          error: (e, _) => const EmptyState(
              icon: Icons.error_outline, title: 'Не удалось загрузить', message: 'Попробуйте перезапустить приложение.'),
          data: (all) {
            if (all.isEmpty) {
              return EmptyState(
                icon: Icons.library_music_outlined,
                title: 'Библиотека пуста',
                message: 'Добавьте первый альбом, чтобы начать.',
                actionLabel: 'Добавить альбом',
                onAction: () => showAlbumForm(context),
              );
            }
            final shown = _apply(all, genreMap);
            if (shown.isEmpty) {
              return const EmptyState(
                  icon: Icons.search_off, title: 'Ничего не найдено', message: 'Измените запрос или фильтры.');
            }
            return LayoutBuilder(builder: (context, box) {
              if (box.maxWidth >= 700) {
                return GridView.builder(
                  padding: const EdgeInsets.all(Sp.page),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200,
                    mainAxisSpacing: Sp.xl,
                    crossAxisSpacing: Sp.lg,
                    childAspectRatio: .72,
                  ),
                  itemCount: shown.length,
                  itemBuilder: (_, i) => AlbumCard(
                    album: shown[i],
                    width: null,
                    heroTag: 'lib-${shown[i].id}',
                    onTap: () => open(shown[i], 'lib-${shown[i].id}'),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.only(top: Sp.sm, bottom: Sp.xl),
                itemCount: shown.length,
                itemBuilder: (_, i) => AlbumTile(
                  album: shown[i],
                  heroTag: 'lib-${shown[i].id}',
                  onTap: () => open(shown[i], 'lib-${shown[i].id}'),
                ),
              );
            });
          },
        ),
      ),
    ]);
  }
}
