import 'package:flutter/material.dart';
import '../../core/haptics/haptics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../core/utils/format.dart';
import '../../data/db/providers.dart';
import '../../shared/widgets/cover_art.dart';
import '../../shared/widgets/empty_state.dart';
import '../../core/router/routes.dart';
import '../../shared/widgets/name_dialog.dart';
import '../../data/media/image_store.dart';
import '../../domain/entities/track.dart';
import '../../domain/entities/queue_item.dart';
import '../../player/player_controller.dart';
import '../collections/pickers.dart';
import '../library/album_form_sheet.dart';

class AlbumScreen extends ConsumerStatefulWidget {
  const AlbumScreen({super.key, required this.id, this.heroTag});
  final int id;
  final String? heroTag;
  @override
  ConsumerState<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends ConsumerState<AlbumScreen> {
  final _review = TextEditingController();
  bool _inited = false;
  double? _draft;
  bool _pressed = false;

  @override
  void dispose() {
    _review.dispose();
    super.dispose();
  }

  Widget _scaffold(Widget body, {List<Widget>? actions}) => Scaffold(
        appBar: AppBar(
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
          actions: actions,
        ),
        body: body,
      );

  void _openCover(String seed, String? path) {
    showDialog<void>(
      context: context,
      builder: (c) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(children: [
          Center(
            child: InteractiveViewer(
              maxScale: 4,
              child: CoverArt(seed: seed, path: path, radius: BorderRadius.zero),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(c),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Future<void> _trackAction(String v, TrackView tr) async {
    final repo = ref.read(libraryRepoProvider);
    final m = ScaffoldMessenger.of(context);
    try {
      if (v == 'attach') {
        final p = await ImageStore.pickAudio();
        if (p == null) return;
        await ImageStore.remove(tr.filePath);
        await repo.setTrackFile(tr.id, p);
        m.showSnackBar(const SnackBar(content: Text('Аудиофайл прикреплён')));
      } else if (v == 'detach') {
        await ImageStore.remove(tr.filePath);
        await repo.setTrackFile(tr.id, null);
      } else if (v == 'rename') {
        final n = await promptName(context, title: 'Название трека', initial: tr.title);
        if (n != null) await ref.read(extrasRepoProvider).renameTrack(tr.id, n);
      }
    } catch (_) {
      m.showSnackBar(const SnackBar(content: Text('Не удалось прикрепить файл')));
    }
  }

  Future<void> _confirmDelete() async {
    final repo = ref.read(libraryRepoProvider);
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Удалить альбом?'),
        content: const Text('Оценка и рецензия тоже будут удалены.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Отмена')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Удалить')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    context.pop();
    await repo.deleteAlbum(widget.id);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final repo = ref.read(libraryRepoProvider);
    final async = ref.watch(albumProvider(widget.id));
    return async.when(
      loading: () => _scaffold(const Center(child: CircularProgressIndicator())),
      error: (_, __) => _scaffold(const EmptyState(
          icon: Icons.error_outline, title: 'Ошибка', message: 'Не удалось открыть альбом.')),
      data: (a) {
        if (a == null) {
          return _scaffold(const EmptyState(
              icon: Icons.album_outlined, title: 'Альбом не найден', message: 'Возможно, он был удалён.'));
        }
        if (!_inited) {
          _review.text = a.review;
          _inited = true;
        }
        final genres = ref.watch(albumGenresProvider).valueOrNull?[a.id] ?? const <String>[];
        final tracks = ref.watch(tracksProvider(a.id)).valueOrNull ?? const [];
        final total = tracks.fold<int>(0, (s, e) => s + (e.durationMs ?? 0));
        final queue = [
          for (final tr in tracks)
            QueueItem(
              trackId: tr.id,
              albumId: a.id,
              title: tr.title,
              artist: a.artist,
              albumTitle: a.title,
              coverSeed: a.coverSeed,
              coverPath: a.coverPath,
              filePath: tr.filePath,
              durationMs: tr.durationMs,
            ),
        ];
        final history = ref.watch(ratingHistoryProvider(a.id)).valueOrNull ?? const [];
        final value = _draft ?? a.rating;
        return _scaffold(
          actions: [
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'edit') showAlbumForm(context, album: a);
                if (v == 'delete') _confirmDelete();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Редактировать')),
                PopupMenuItem(value: 'delete', child: Text('Удалить')),
              ],
            ),
          ],
          ListView(
            padding: const EdgeInsets.fromLTRB(Sp.page, 0, Sp.page, Sp.huge),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: GestureDetector(
                    onTapDown: (_) => setState(() => _pressed = true),
                    onTapUp: (_) => setState(() => _pressed = false),
                    onTapCancel: () => setState(() => _pressed = false),
                    onTap: () => _openCover(a.coverSeed, a.coverPath),
                    child: AnimatedScale(
                      scale: _pressed ? .98 : 1,
                      duration: Dur.fast,
                      curve: Dur.curve,
                      child: Hero(
                        tag: widget.heroTag ?? 'cover-${a.id}',
                        child: CoverArt(seed: a.coverSeed, path: a.coverPath),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: Sp.xl),
              Row(children: [
                Expanded(child: Text(a.title, style: t.textTheme.headlineMedium)),
                IconButton(
                  tooltip: 'Избранное',
                  onPressed: () {
                    Haptics.light();
                    repo.toggleFavorite(a.id);
                  },
                  icon: AnimatedScale(
                    scale: a.isFavorite ? 1.15 : 1,
                    duration: Dur.fast,
                    curve: Dur.curve,
                    child: Icon(a.isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: a.isFavorite ? t.colorScheme.primary : null),
                  ),
                ),
              ]),
              const SizedBox(height: Sp.xs),
              GestureDetector(
                onTap: () => context.push(Routes.artist(a.artistId)),
                child: Text(a.artist, style: t.textTheme.titleMedium?.copyWith(color: t.colorScheme.primary)),
              ),
              if (a.year != null) Text('${a.year}', style: t.textTheme.bodySmall),
              if (genres.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: Sp.md),
                  child: Wrap(spacing: Sp.sm, runSpacing: Sp.sm, children: [
                    for (final g in genres)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: Sp.xs),
                        decoration: BoxDecoration(
                            border: Border.all(color: t.colorScheme.outline), borderRadius: Rad.smAll),
                        child: Text(g, style: t.textTheme.labelMedium),
                      ),
                  ]),
                ),
              const SizedBox(height: Sp.lg),
              Wrap(spacing: Sp.sm, runSpacing: Sp.sm, children: [
                FilledButton.icon(
                  onPressed: queue.isEmpty ? null : () => ref.read(playerProvider.notifier).playQueue(queue, 0),
                  icon: const Icon(Icons.play_arrow, size: 20),
                  label: const Text('Слушать'),
                ),
                OutlinedButton.icon(
                  onPressed: () => showCollectionPicker(context, a.id),
                  icon: const Icon(Icons.folder_outlined, size: 18),
                  label: const Text('В коллекцию'),
                ),
              ]),
              const SizedBox(height: Sp.xxl),
              Text('ОЦЕНКА', style: t.textTheme.labelSmall),
              const SizedBox(height: Sp.sm),
              Row(children: [
                Text(value == null ? '—' : fmtRating(value), style: t.textTheme.displaySmall),
                Text(' / 10', style: t.textTheme.bodySmall),
                const Spacer(),
                if (a.rating != null)
                  TextButton(
                    onPressed: () {
                      setState(() => _draft = null);
                      repo.setRating(a.id, null);
                    },
                    child: const Text('Сбросить'),
                  ),
              ]),
              Slider(
                min: 0,
                max: 10,
                divisions: 20,
                value: (value ?? 0).clamp(0, 10).toDouble(),
                onChanged: (v) => setState(() => _draft = v),
                onChangeEnd: (v) async {
                  Haptics.selection();
                  await repo.setRating(a.id, v);
                  if (mounted) setState(() => _draft = null);
                },
              ),
              if (history.isNotEmpty) ...[
                const SizedBox(height: Sp.md),
                Text('ИСТОРИЯ ОЦЕНОК', style: t.textTheme.labelSmall),
                const SizedBox(height: Sp.xs),
                for (final h in history.take(5))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: Sp.xs),
                    child: Row(children: [
                      Expanded(child: Text(fmtDate(h.at), style: t.textTheme.bodySmall)),
                      Text(fmtRating(h.value), style: t.textTheme.bodyMedium),
                    ]),
                  ),
              ],
              const SizedBox(height: Sp.xl),
              Text('РЕЦЕНЗИЯ', style: t.textTheme.labelSmall),
              const SizedBox(height: Sp.sm),
              TextField(
                controller: _review,
                minLines: 3,
                maxLines: 8,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(hintText: 'Что вы думаете об этом альбоме?'),
              ),
              const SizedBox(height: Sp.md),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton(
                  onPressed: () async {
                    final m = ScaffoldMessenger.of(context);
                    await repo.saveReview(a.id, _review.text);
                    m.showSnackBar(const SnackBar(content: Text('Рецензия сохранена')));
                  },
                  child: const Text('Сохранить рецензию'),
                ),
              ),
              if (tracks.isNotEmpty) ...[
                const SizedBox(height: Sp.xxl),
                Text('ТРЕКЛИСТ · ${tracks.length}${total > 0 ? ' · ${fmtDuration(total)}' : ''}',
                    style: t.textTheme.labelSmall),
                const SizedBox(height: Sp.sm),
                for (final tr in tracks)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => ref.read(playerProvider.notifier).playQueue(queue, tr.number - 1),
                    child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: Sp.sm),
                    child: Row(children: [
                      SizedBox(width: 28, child: Text('${tr.number}', style: t.textTheme.bodySmall)),
                      Expanded(child: Text(tr.title, style: t.textTheme.bodyMedium)),
                      if (tr.durationMs != null) Text(fmtDuration(tr.durationMs!), style: t.textTheme.bodySmall),
                      if (tr.filePath != null)
                        Padding(
                          padding: const EdgeInsets.only(left: Sp.xs),
                          child: Icon(Icons.volume_up_outlined, size: 16, color: t.colorScheme.primary),
                        ),
                      PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.more_vert, size: 18),
                        onSelected: (v) => _trackAction(v, tr),
                        itemBuilder: (_) => [
                          const PopupMenuItem(value: 'rename', child: Text('Переименовать')),
                          PopupMenuItem(
                              value: 'attach',
                              child: Text(tr.filePath == null ? 'Прикрепить аудиофайл' : 'Заменить аудиофайл')),
                          if (tr.filePath != null) const PopupMenuItem(value: 'detach', child: Text('Открепить аудиофайл')),
                        ],
                      ),
                    ]),
                  )),
              ],
            ],
          ),
        );
      },
    );
  }
}
