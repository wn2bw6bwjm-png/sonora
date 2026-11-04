import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/format.dart';
import '../../data/db/providers.dart';
import '../../domain/entities/album_view.dart';
import '../../shared/widgets/album_tile.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/name_dialog.dart';
import '../../data/media/image_store.dart';
import '../../shared/widgets/collection_cover.dart';
import 'pickers.dart';

class CollectionScreen extends ConsumerStatefulWidget {
  const CollectionScreen({super.key, required this.id});
  final int id;
  @override
  ConsumerState<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends ConsumerState<CollectionScreen> {
  int _sort = 0; // 0 добавлено, 1 название, 2 оценка

  List<AlbumView> _sorted(List<AlbumView> l) {
    final s = [...l];
    if (_sort == 1) s.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    if (_sort == 2) s.sort((a, b) => (b.rating ?? -1).compareTo(a.rating ?? -1));
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final repo = ref.read(collectionRepoProvider);
    final col = ref.watch(collectionProvider(widget.id)).valueOrNull;
    final albums = ref.watch(collectionAlbumsProvider(widget.id)).valueOrNull ?? const [];
    if (col == null) {
      return Scaffold(
        appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop())),
        body: const EmptyState(icon: Icons.folder_outlined, title: 'Коллекция не найдена', message: 'Возможно, она была удалена.'),
      );
    }
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        actions: [
          IconButton(
            tooltip: 'Избранное',
            icon: Icon(col.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: col.isFavorite ? t.colorScheme.primary : null),
            onPressed: () => repo.toggleFavorite(col.id, col.isFavorite),
          ),
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'rename') {
                final n = await promptName(context, title: 'Название коллекции', initial: col.name);
                if (n != null) await repo.rename(col.id, n);
              } else if (v == 'cover') {
                final p = await ImageStore.pick('collection');
                if (p != null) await repo.setCover(col.id, p);
              } else if (v == 'uncover') {
                await repo.setCover(col.id, null);
              } else if (v == 'delete') {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: const Text('Удалить коллекцию?'),
                    content: const Text('Альбомы останутся в библиотеке.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Отмена')),
                      TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Удалить')),
                    ],
                  ),
                );
                if (ok == true && context.mounted) {
                  context.pop();
                  await repo.delete(col.id);
                }
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'rename', child: Text('Переименовать')),
              PopupMenuItem(value: 'cover', child: Text('Выбрать обложку')),
              PopupMenuItem(value: 'uncover', child: Text('Убрать обложку')),
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
              CollectionCover(seeds: col.seeds, path: col.coverPath, size: 96),
              const SizedBox(height: Sp.lg),
              Text(col.name, style: t.textTheme.displaySmall),
              const SizedBox(height: Sp.sm),
              Text(
                col.avgRating == null
                    ? albumsWord(col.count)
                    : '${albumsWord(col.count)} · средняя оценка ${col.avgRating!.toStringAsFixed(1)}',
                style: t.textTheme.bodySmall,
              ),
              const SizedBox(height: Sp.lg),
              Row(children: [
                OutlinedButton.icon(
                  onPressed: () => showAlbumPicker(context, col.id),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Альбомы'),
                ),
                const Spacer(),
                PopupMenuButton<int>(
                  tooltip: 'Сортировка',
                  icon: const Icon(Icons.sort),
                  initialValue: _sort,
                  onSelected: (v) => setState(() => _sort = v),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 0, child: Text('По добавлению')),
                    PopupMenuItem(value: 1, child: Text('По названию')),
                    PopupMenuItem(value: 2, child: Text('По оценке')),
                  ],
                ),
              ]),
            ]),
          ),
          const SizedBox(height: Sp.sm),
          if (albums.isEmpty)
            const SizedBox(
              height: 260,
              child: EmptyState(
                  icon: Icons.album_outlined,
                  title: 'Коллекция пуста',
                  message: 'Нажмите «Альбомы», чтобы добавить первые.'),
            )
          else
            for (final a in _sorted(albums))
              AlbumTile(
                album: a,
                onTap: () => context.push(Routes.album(a.id)),
                trailing: IconButton(
                  tooltip: 'Убрать из коллекции',
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => repo.removeAlbum(col.id, a.id),
                ),
              ),
        ],
      ),
    );
  }
}
