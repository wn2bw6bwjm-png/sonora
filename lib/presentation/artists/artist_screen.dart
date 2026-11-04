import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/haptics/haptics.dart';
import '../../core/router/routes.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/format.dart';
import '../../data/db/providers.dart';
import '../../data/media/image_store.dart';
import '../../domain/entities/artist_info.dart';
import '../../shared/widgets/album_tile.dart';
import '../../shared/widgets/artist_avatar.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/name_dialog.dart';
import '../../shared/widgets/section_header.dart';

class ArtistScreen extends ConsumerWidget {
  const ArtistScreen({super.key, required this.id});
  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final info = ref.watch(artistInfoProvider(id)).valueOrNull;
    final albums = ref.watch(artistAlbumsProvider(id)).valueOrNull ?? const [];
    final back = IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop());
    if (info == null) {
      return Scaffold(
        appBar: AppBar(leading: back),
        body: const EmptyState(icon: Icons.person_outline, title: 'Исполнитель не найден', message: 'Возможно, он был удалён.'),
      );
    }
    final rated = albums.where((a) => a.rating != null).toList()..sort((a, b) => b.rating!.compareTo(a.rating!));
    final avg = rated.isEmpty ? null : rated.fold<double>(0, (s, a) => s + a.rating!) / rated.length;
    final favs = albums.where((a) => a.isFavorite).toList();
    final disco = [...albums]..sort((a, b) => (b.year ?? 0).compareTo(a.year ?? 0));
    Widget stat(String label, String value) => Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: t.textTheme.headlineSmall),
            Text(label, style: t.textTheme.bodySmall),
          ]),
        );
    Widget tiles(List l, String prefix) => Column(children: [
          for (final a in l)
            AlbumTile(
              album: a,
              heroTag: '$prefix-${a.id}',
              onTap: () => context.push(Routes.album(a.id), extra: '$prefix-${a.id}'),
            ),
        ]);
    return Scaffold(
      appBar: AppBar(
        leading: back,
        actions: [
          IconButton(
            tooltip: 'Избранное',
            icon: Icon(info.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: info.isFavorite ? t.colorScheme.primary : null),
            onPressed: () {
              Haptics.light();
              ref.read(extrasRepoProvider).toggleFavoriteArtist(id);
            },
          ),
          IconButton(
            tooltip: 'Редактировать',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              showDragHandle: true,
              builder: (_) => _ArtistEditSheet(info: info),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: Sp.huge),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Sp.page),
            child: Row(children: [
              ArtistAvatar(name: info.name, imagePath: info.imagePath, size: 88),
              const SizedBox(width: Sp.lg),
              Expanded(child: Text(info.name, style: t.textTheme.headlineMedium)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(Sp.page, Sp.lg, Sp.page, 0),
            child: Text(
              info.bio.isEmpty ? 'Биография не добавлена. Нажмите на карандаш, чтобы написать её.' : info.bio,
              style: info.bio.isEmpty
                  ? t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant)
                  : t.textTheme.bodyLarge,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(Sp.page, Sp.xl, Sp.page, 0),
            child: Row(children: [
              stat('в библиотеке', '${albums.length}'),
              stat('оценено', '${rated.length}'),
              stat('средняя оценка', avg == null ? '—' : avg.toStringAsFixed(1)),
            ]),
          ),
          if (rated.isNotEmpty) ...[const SectionHeader('Лучшие альбомы'), tiles(rated.take(3).toList(), 'ab')],
          if (favs.isNotEmpty) ...[const SectionHeader('Любимые релизы'), tiles(favs, 'af')],
          SectionHeader('Дискография · ${albumsWord(disco.length)}'),
          tiles(disco, 'ad'),
        ],
      ),
    );
  }
}

class _ArtistEditSheet extends ConsumerStatefulWidget {
  const _ArtistEditSheet({required this.info});
  final ArtistInfo info;
  @override
  ConsumerState<_ArtistEditSheet> createState() => _ArtistEditSheetState();
}

class _ArtistEditSheetState extends ConsumerState<_ArtistEditSheet> {
  late final _bio = TextEditingController(text: widget.info.bio);
  late String? _image = widget.info.imagePath;

  @override
  void dispose() {
    _bio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(Sp.page, 0, Sp.page, Sp.xl),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.info.name, style: t.textTheme.headlineSmall),
          const SizedBox(height: Sp.lg),
          Row(children: [
            ArtistAvatar(name: widget.info.name, imagePath: _image, size: 64),
            const SizedBox(width: Sp.lg),
            Expanded(
              child: Wrap(spacing: Sp.sm, children: [
                OutlinedButton(
                  onPressed: () async {
                    final p = await ImageStore.pick('artist');
                    if (p != null && mounted) setState(() => _image = p);
                  },
                  child: const Text('Файл'),
                ),
                OutlinedButton(
                  onPressed: () async {
                    final url = await promptName(context, title: 'Ссылка на фото', hint: 'https://…', url: true);
                    if (url == null || !mounted) return;
                    if (ImageStore.isUrl(url)) {
                      setState(() => _image = url.trim());
                    } else {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(const SnackBar(content: Text('Нужна ссылка вида https://…')));
                    }
                  },
                  child: const Text('Ссылка'),
                ),
                if (_image != null)
                  TextButton(onPressed: () => setState(() => _image = null), child: const Text('Убрать')),
              ]),
            ),
          ]),
          const SizedBox(height: Sp.lg),
          TextField(
            controller: _bio,
            minLines: 4,
            maxLines: 10,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Биография', alignLabelWithHint: true),
          ),
          const SizedBox(height: Sp.xl),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () async {
                await ref.read(extrasRepoProvider).updateArtist(widget.info.id, bio: _bio.text, imagePath: _image);
                if (mounted) context.pop();
              },
              child: const Text('Сохранить'),
            ),
          ),
        ]),
      ),
    );
  }
}
