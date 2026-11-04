import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/theme/tokens.dart';
import '../../data/db/providers.dart';
import '../../domain/usecases/statistics.dart';
import '../../shared/widgets/album_tile.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/section_header.dart';
import 'charts.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final albums = ref.watch(albumsProvider).valueOrNull ?? const [];
    final genreMap = ref.watch(albumGenresProvider).valueOrNull ?? const <int, List<String>>{};
    final dates = ref.watch(ratingDatesProvider).valueOrNull ?? const <DateTime>[];

    Widget title() => Padding(
          padding: const EdgeInsets.fromLTRB(Sp.page, Sp.xl, Sp.page, 0),
          child: Text('Stats', style: t.textTheme.displaySmall),
        );

    if (albums.isEmpty) {
      return SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          title(),
          const Expanded(
            child: EmptyState(
              icon: Icons.insights_outlined,
              title: 'Недостаточно данных',
              message: 'Статистика появится, когда в библиотеке будут альбомы и оценки.',
            ),
          ),
        ]),
      );
    }

    final s = buildStatistics(albums: albums, genresByAlbum: genreMap, ratingDates: dates, now: DateTime.now());
    Widget stat(String label, String value) => Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: t.textTheme.headlineMedium),
            Text(label, style: t.textTheme.bodySmall),
          ]),
        );
    Widget pad(Widget w) => Padding(padding: const EdgeInsets.symmetric(horizontal: Sp.page), child: w);
    final maxGenre = s.topGenres.isEmpty ? 1 : s.topGenres.first.value;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.only(bottom: Sp.huge),
        children: [
          title(),
          Padding(
            padding: const EdgeInsets.fromLTRB(Sp.page, Sp.xl, Sp.page, 0),
            child: Row(children: [
              stat('альбомов', '${s.albumCount}'),
              stat('исполнителей', '${s.artistCount}'),
              stat('оценено', '${s.ratedCount}'),
              stat('средняя', s.avgRating == null ? '—' : s.avgRating!.toStringAsFixed(1)),
            ]),
          ),
          const SectionHeader('Распределение оценок'),
          if (s.ratedCount == 0)
            pad(Text('Оцените хотя бы один альбом, чтобы увидеть распределение.', style: t.textTheme.bodyMedium))
          else
            pad(RatingDistributionChart(distribution: s.distribution)),
          const SectionHeader('Активность по месяцам'),
          pad(ActivityChart(months: s.months)),
          const SectionHeader('Любимые жанры'),
          if (s.topGenres.isEmpty)
            pad(Text('Укажите жанры в альбомах, чтобы увидеть их здесь.', style: t.textTheme.bodyMedium))
          else
            pad(Column(children: [
              for (final g in s.topGenres)
                Padding(
                  padding: const EdgeInsets.only(bottom: Sp.md),
                  child: Row(children: [
                    SizedBox(width: 110, child: Text(g.key, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.textTheme.bodyMedium)),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: Rad.smAll,
                        child: LinearProgressIndicator(
                          value: g.value / maxGenre,
                          minHeight: 8,
                          color: t.colorScheme.primary,
                          backgroundColor: t.colorScheme.outline,
                        ),
                      ),
                    ),
                    SizedBox(width: 32, child: Text('${g.value}', textAlign: TextAlign.right, style: t.textTheme.bodySmall)),
                  ]),
                ),
            ])),
          if (s.topAlbums.isNotEmpty) ...[
            const SectionHeader('Самые высокие оценки'),
            for (final a in s.topAlbums)
              AlbumTile(album: a, onTap: () => context.push(Routes.album(a.id))),
          ],
        ],
      ),
    );
  }
}
