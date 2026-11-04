import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/format.dart';
import '../../data/db/providers.dart';
import '../../shared/widgets/collection_cover.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/name_dialog.dart';

class CollectionsScreen extends ConsumerWidget {
  const CollectionsScreen({super.key});

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final name = await promptName(context, title: 'Новая коллекция');
    if (name != null) await ref.read(collectionRepoProvider).create(name);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final cols = ref.watch(collectionsProvider);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: const Text('Коллекции'),
        actions: [
          IconButton(
              tooltip: 'Создать коллекцию',
              icon: const Icon(Icons.add),
              onPressed: () => _create(context, ref)),
        ],
      ),
      body: cols.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const EmptyState(
            icon: Icons.error_outline, title: 'Ошибка', message: 'Не удалось загрузить коллекции.'),
        data: (list) => list.isEmpty
            ? EmptyState(
                icon: Icons.folder_outlined,
                title: 'Коллекций пока нет',
                message: 'Например: All Time Favorites или Night Drive.',
                actionLabel: 'Создать коллекцию',
                onAction: () => _create(context, ref),
              )
            : ListView.builder(
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final c = list[i];
                  return InkWell(
                    onTap: () => context.push(Routes.collection(c.id)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Sp.page, vertical: Sp.sm),
                      child: Row(children: [
                        CollectionCover(seeds: c.seeds, path: c.coverPath),
                        const SizedBox(width: Sp.lg),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(c.name, style: t.textTheme.titleMedium),
                            Text(
                              c.avgRating == null
                                  ? albumsWord(c.count)
                                  : '${albumsWord(c.count)} · ср. ${fmtRating(double.parse(c.avgRating!.toStringAsFixed(1)))}',
                              style: t.textTheme.bodySmall,
                            ),
                          ]),
                        ),
                        if (c.isFavorite) Icon(Icons.favorite, size: 16, color: t.colorScheme.primary),
                      ]),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
