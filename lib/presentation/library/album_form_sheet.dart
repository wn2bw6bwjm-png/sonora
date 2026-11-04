import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../data/db/providers.dart';
import '../../data/media/image_store.dart';
import '../../shared/widgets/cover_art.dart';
import '../../shared/widgets/name_dialog.dart';
import '../../domain/entities/album_view.dart';
import '../../domain/entities/track.dart';

Future<void> showAlbumForm(BuildContext context, {AlbumView? album}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _AlbumForm(album: album),
    );

class _AlbumForm extends ConsumerStatefulWidget {
  const _AlbumForm({this.album});
  final AlbumView? album;
  @override
  ConsumerState<_AlbumForm> createState() => _AlbumFormState();
}

class _AlbumFormState extends ConsumerState<_AlbumForm> {
  final _key = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.album?.title);
  late final _artist = TextEditingController(text: widget.album?.artist);
  late final _year = TextEditingController(text: widget.album?.year?.toString() ?? '');
  final _genres = TextEditingController();
  final _tracks = TextEditingController();
  bool _busy = false;
  String? _coverPath;
  late bool _loaded = widget.album == null;

  @override
  void initState() {
    super.initState();
    _coverPath = widget.album?.coverPath;
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final a = widget.album;
    if (a == null) return;
    final repo = ref.read(libraryRepoProvider);
    try {
      final g = await repo.genresOf(a.id);
      final tr = await repo.tracksOf(a.id);
      _genres.text = g.join(', ');
      _tracks.text = formatTracklist(tr);
    } catch (_) {}
    if (mounted) setState(() => _loaded = true);
  }

  @override
  void dispose() {
    _title.dispose();
    _artist.dispose();
    _year.dispose();
    _genres.dispose();
    _tracks.dispose();
    super.dispose();
  }

  Future<void> _pickCover() async {
    final p = await ImageStore.pick('album');
    if (p != null && mounted) setState(() => _coverPath = p);
  }

  Future<void> _coverUrl() async {
    final url = await promptName(context, title: 'Ссылка на обложку', hint: 'https://…', url: true);
    if (url == null || !mounted) return;
    if (!ImageStore.isUrl(url)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Нужна ссылка вида https://…')));
      return;
    }
    setState(() => _coverPath = url.trim());
  }

  Future<void> _save() async {
    if (!_key.currentState!.validate()) return;
    setState(() => _busy = true);
    final repo = ref.read(libraryRepoProvider);
    final year = int.tryParse(_year.text.trim());
    final genres = parseGenres(_genres.text);
    final tracks = parseTracklist(_tracks.text);
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (widget.album == null) {
        await repo.addAlbum(
            title: _title.text, artist: _artist.text, year: year, genres: genres, tracks: tracks, coverPath: _coverPath);
      } else {
        await repo.updateAlbum(widget.album!.id,
            title: _title.text, artist: _artist.text, year: year, genres: genres, tracks: tracks, coverPath: _coverPath);
      }
      if (mounted) context.pop();
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('Не удалось сохранить альбом')));
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _required(String? v) => (v == null || v.trim().isEmpty) ? 'Обязательное поле' : null;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(Sp.page, 0, Sp.page, Sp.xl),
        child: Form(
          key: _key,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.album == null ? 'Новый альбом' : 'Редактировать', style: t.textTheme.headlineSmall),
              const SizedBox(height: Sp.lg),
              Row(children: [
                CoverArt(seed: '${_artist.text}|${_title.text}', path: _coverPath, size: 64),
                const SizedBox(width: Sp.lg),
                Expanded(
                  child: Wrap(spacing: Sp.sm, children: [
                    OutlinedButton(onPressed: _pickCover, child: const Text('Файл')),
                    OutlinedButton(onPressed: _coverUrl, child: const Text('Ссылка')),
                    if (_coverPath != null)
                      TextButton(onPressed: () => setState(() => _coverPath = null), child: const Text('Убрать')),
                  ]),
                ),
              ]),
              const SizedBox(height: Sp.lg),
              TextFormField(
                controller: _title,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Название'),
                validator: _required,
              ),
              const SizedBox(height: Sp.md),
              TextFormField(
                controller: _artist,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Исполнитель'),
                validator: _required,
              ),
              const SizedBox(height: Sp.md),
              TextFormField(
                controller: _year,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Год (необязательно)'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final n = int.tryParse(v.trim());
                  return (n == null || n < 1900 || n > 2100) ? 'Введите год от 1900 до 2100' : null;
                },
              ),
              const SizedBox(height: Sp.md),
              TextFormField(
                controller: _genres,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Жанры через запятую'),
              ),
              const SizedBox(height: Sp.md),
              TextFormField(
                controller: _tracks,
                minLines: 3,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: 'Треклист',
                  helperText: 'Один трек в строке. Длительность по желанию: «Название 3:45»',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: Sp.xl),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: (_busy || !_loaded) ? null : _save,
                  child: const Text('Сохранить'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
