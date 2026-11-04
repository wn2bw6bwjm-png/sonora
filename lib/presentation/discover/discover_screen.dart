import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/theme/tokens.dart';
import '../../data/db/providers.dart';
import '../../data/prefs/prefs_providers.dart';
import '../../domain/entities/album_view.dart';
import '../../domain/usecases/recommend.dart';
import '../../shared/widgets/album_card.dart';
import '../../shared/widgets/album_tile.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/section_header.dart';

/// Подборки строятся только из вашей библиотеки, встроенной музыки нет.
class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});
  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  String? _genre;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final albums = ref.watch(albumsProvider).valueOrNull ?? const <AlbumView>[];
    final genreMap = ref.watch(albumGenresProvider).valueOrNull ?? const <int, List<String>>{};
    final playedIds = (ref.watch(recentlyPlayedProvider).valueOrNull ?? const <int>[]).toSet();
    final preferredGenres = ref.watch(preferredGenresProvider);
    final preferredArtists = ref.watch(preferredArtistsProvider);

    Widget title() => Padding(
          padding: const EdgeInsets.fromLTRB(Sp.page, Sp.xl, Sp.page, 0),
          child: Text('Discover', style: t.textTheme.displaySmall),
        );

    if (albums.isEmpty) {
      return SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          title(),
          Expanded(
            child: EmptyState(
              icon: Icons.explore_outlined,
              title: 'Пока нечего открывать',
              message: 'Добавьте альбомы в библиотеку, и здесь появятся подборки на основе ваших оценок и жанров.',
              actionLabel: 'Открыть библиотеку',
              onAction: () => context.go(Routes.library),
            ),
          ),
        ]),
      );
    }

    final recs = recommendFromLibrary(albums, genreMap,
        preferredGenres: preferredGenres, preferredArtists: preferredArtists, limit: 8);
    final unrated = albums.where((a) => a.rating == null).take(8).toList();
    final forgotten = albums.where((a) => !playedIds.contains(a.id)).toList().reversed.take(8).toList();
    final counts = <String, int>{};
    for (final l in genreMap.values) {
      for (final g in l) {
        counts[g] = (counts[g] ?? 0) + 1;
      }
    }
    final genres = counts.keys.toList()..sort();
    final byGenre = _genre == null ? const <AlbumView>[] : albums.where((a) => (genreMap[a.id] ?? const []).contains(_genre)).toList();

    Widget row(List<AlbumView> list, String prefix) => SizedBox(
          height: 210,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: Sp.page),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(width: Sp.lg),
            itemBuilder: (_, i) {
              final tag = '$prefix-${list[i].id}';
              return AlbumCard(
                album: list[i],
                heroTag: tag,
                onTap: () => context.push(Routes.album(list[i].id), extra: tag),
              );
            },
          ),
        );

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.only(bottom: Sp.huge),
        children: [
          title(),
          Padding(
            padding: const EdgeInsets.fromLTRB(Sp.page, Sp.sm, Sp.page, 0),
            child: Text('Подборки из вашей библиотеки.', style: t.textTheme.bodySmall),
          ),
          if (recs.isNotEmpty) ...[const SectionHeader('Рекомендации на основе оценок'), row(recs, 'dr')],
          if (unrated.isNotEmpty) ...[const SectionHeader('Ещё не оценены'), row(unrated, 'du')],
          if (forgotten.isNotEmpty) ...[const SectionHeader('Давно не слушали'), row(forgotten, 'df')],
          if (genres.isNotEmpty) ...[
            const SectionHeader('Жанры'),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: Sp.page),
                children: [
                  for (final g in genres)
                    Padding(
                      padding: const EdgeInsets.only(right: Sp.sm),
                      child: ChoiceChip(
                        label: Text('$g · ${counts[g]}'),
                        selected: _genre == g,
                        showCheckmark: false,
                        onSelected: (v) => setState(() => _genre = v ? g : null),
                      ),
                    ),
                ],
              ),
            ),
            if (_genre != null) ...[
              const SizedBox(height: Sp.md),
              for (final a in byGenre)
                AlbumTile(
                  album: a,
                  heroTag: 'dg-${a.id}',
                  onTap: () => context.push(Routes.album(a.id), extra: 'dg-${a.id}'),
                ),
            ],
          ],
          if (genres.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(Sp.page, Sp.xl, Sp.page, 0),
              child: Text('Укажите жанры в альбомах, и здесь появятся подборки по жанрам и рекомендации.',
                  style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant)),
            ),
        ],
      ),
    );
  }
}
