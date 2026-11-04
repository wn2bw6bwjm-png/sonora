import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/format.dart';
import '../../data/db/providers.dart';
import '../../shared/widgets/artist_avatar.dart';
import '../../shared/widgets/empty_state.dart';

/// Список исполнителей. Используется как экран и как вкладка Library.
class ArtistsList extends ConsumerWidget {
  const ArtistsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final artists = ref.watch(artistsProvider).valueOrNull ?? const [];
    final albums = ref.watch(albumsProvider).valueOrNull ?? const [];
    final counts = <int, int>{};
    for (final a in albums) {
      counts[a.artistId] = (counts[a.artistId] ?? 0) + 1;
    }
    if (artists.isEmpty) {
      return const EmptyState(
          icon: Icons.person_outline,
          title: 'Исполнителей пока нет',
          message: 'Они появятся вместе с первыми альбомами.');
    }
    return ListView.builder(
      itemCount: artists.length,
      itemBuilder: (_, i) {
        final a = artists[i];
        return InkWell(
          onTap: () => context.push(Routes.artist(a.id)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Sp.page, vertical: Sp.sm),
            child: Row(children: [
              ArtistAvatar(name: a.name, imagePath: a.imagePath),
              const SizedBox(width: Sp.lg),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(a.name, style: t.textTheme.titleMedium),
                  Text(albumsWord(counts[a.id] ?? 0), style: t.textTheme.bodySmall),
                ]),
              ),
              if (a.isFavorite) Icon(Icons.favorite, size: 16, color: t.colorScheme.primary),
            ]),
          ),
        );
      },
    );
  }
}

class ArtistsScreen extends StatelessWidget {
  const ArtistsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
          title: const Text('Исполнители'),
        ),
        body: const ArtistsList(),
      );
}
