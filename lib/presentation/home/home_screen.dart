import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/theme/tokens.dart';
import '../../data/db/providers.dart';
import '../../domain/entities/album_view.dart';
import '../../shared/widgets/album_card.dart';
import '../../shared/widgets/artist_avatar.dart';
import '../../shared/widgets/collection_cover.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/skeleton_box.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 5) return 'Доброй ночи';
    if (h < 12) return 'Доброе утро';
    if (h < 18) return 'Добрый день';
    return 'Добрый вечер';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final albumsAsync = ref.watch(albumsProvider);
    final albums = albumsAsync.valueOrNull ?? const <AlbumView>[];
    final recent = albums.take(10).toList();
    final playedIds = ref.watch(recentlyPlayedProvider).valueOrNull ?? const <int>[];
    final byId = {for (final a in albums) a.id: a};
    final played = [for (final id in playedIds) if (byId[id] != null) byId[id]!];
    final top = albums.where((a) => a.rating != null).toList()..sort((a, b) => b.rating!.compareTo(a.rating!));
    final favArtists = ref.watch(favoriteArtistsProvider).valueOrNull ?? const [];
    final cols = ref.watch(collectionsProvider).valueOrNull ?? const [];

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

    Widget quick(IconData icon, String label, VoidCallback onTap) => ActionChip(
          avatar: Icon(icon, size: 18),
          label: Text(label),
          onPressed: onTap,
        );

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(Sp.page, Sp.lg, Sp.sm, 0),
              child: Row(children: [
                Expanded(child: Text('SONORA', style: t.textTheme.labelSmall)),
                IconButton(tooltip: 'Поиск', icon: const Icon(Icons.search), onPressed: () => context.push(Routes.search)),
                IconButton(
                    tooltip: 'Настройки',
                    icon: const Icon(Icons.settings_outlined),
                    onPressed: () => context.push(Routes.settings)),
              ]),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(Sp.page, Sp.lg, Sp.page, 0),
              child: Text(_greeting(), style: t.textTheme.displaySmall),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(Sp.page, Sp.lg, Sp.page, 0),
              child: Wrap(spacing: Sp.sm, runSpacing: Sp.sm, children: [
                quick(Icons.library_music_outlined, 'Библиотека', () => context.go(Routes.library)),
                quick(Icons.folder_outlined, 'Коллекции', () => context.push(Routes.collections)),
                quick(Icons.person_outline, 'Исполнители', () => context.push(Routes.artists)),
                quick(Icons.explore_outlined, 'Discover', () => context.go(Routes.discover)),
              ]),
            ),
          ),
          const SliverToBoxAdapter(child: SectionHeader('Недавно добавленные')),
          SliverToBoxAdapter(
            child: (albums.isEmpty && albumsAsync.isLoading)
                ? const _HomeSkeleton()
                : recent.isEmpty
                    ? SizedBox(
                        height: 240,
                        child: EmptyState(
                          icon: Icons.album_outlined,
                          title: 'Пока пусто',
                          message: 'Добавьте первый альбом, и он появится здесь.',
                          actionLabel: 'Открыть библиотеку',
                          onAction: () => context.go(Routes.library),
                        ),
                      )
                    : row(recent, 'hr'),
          ),
          if (played.isNotEmpty) ...[
            const SliverToBoxAdapter(child: SectionHeader('Недавно прослушанные')),
            SliverToBoxAdapter(child: row(played, 'hp')),
          ],
          if (favArtists.isNotEmpty) ...[
            const SliverToBoxAdapter(child: SectionHeader('Любимые исполнители')),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 104,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: Sp.page),
                  itemCount: favArtists.length,
                  separatorBuilder: (_, __) => const SizedBox(width: Sp.lg),
                  itemBuilder: (_, i) {
                    final a = favArtists[i];
                    return GestureDetector(
                      onTap: () => context.push(Routes.artist(a.id)),
                      child: SizedBox(
                        width: 72,
                        child: Column(children: [
                          ArtistAvatar(name: a.name, imagePath: a.imagePath, size: 64),
                          const SizedBox(height: Sp.xs),
                          Text(a.name, maxLines: 2, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, style: t.textTheme.bodySmall),
                        ]),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
          if (cols.isNotEmpty) ...[
            SliverToBoxAdapter(child: SectionHeader('Музыкальные коллекции', onSeeAll: () => context.push(Routes.collections))),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 160,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: Sp.page),
                  itemCount: cols.length,
                  separatorBuilder: (_, __) => const SizedBox(width: Sp.lg),
                  itemBuilder: (_, i) {
                    final c = cols[i];
                    return GestureDetector(
                      onTap: () => context.push(Routes.collection(c.id)),
                      child: SizedBox(
                        width: 120,
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          CollectionCover(seeds: c.seeds, path: c.coverPath, size: 120),
                          const SizedBox(height: Sp.sm),
                          Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.textTheme.titleSmall),
                        ]),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
          if (top.isNotEmpty) ...[
            const SliverToBoxAdapter(child: SectionHeader('Лучшие оценки')),
            SliverToBoxAdapter(child: row(top.take(10).toList(), 'ht')),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: Sp.xl)),
        ],
      ),
    );
  }
}

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(horizontal: Sp.page),
        child: SizedBox(
          height: 210,
          child: Row(children: [
            SkeletonBox(width: 140, height: 140),
            SizedBox(width: Sp.lg),
            SkeletonBox(width: 140, height: 140),
          ]),
        ),
      );
}
