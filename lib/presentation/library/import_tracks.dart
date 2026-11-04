import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/providers.dart';
import '../../data/media/image_store.dart';
import '../../domain/entities/track.dart';

/// Выбор одного или нескольких аудиофайлов и добавление их как отдельных треков.
Future<void> importTracksFlow(BuildContext context, WidgetRef ref) async {
  final m = ScaffoldMessenger.of(context);
  final List<PickedAudio> picked;
  try {
    picked = await ImageStore.pickAudioFiles();
  } catch (_) {
    m.showSnackBar(const SnackBar(content: Text('Не удалось открыть выбор файлов')));
    return;
  }
  if (picked.isEmpty || !context.mounted) return;
  final target = await showDialog<(String, String)>(
    context: context,
    builder: (_) => _TargetDialog(count: picked.length),
  );
  if (target == null) return;
  final copied = <ImportedAudio>[];
  try {
    for (final p in picked) {
      copied.add(ImportedAudio(titleFromFilename(p.name), await ImageStore.copyAudio(p)));
    }
    await ref.read(libraryRepoProvider).importTracks(artist: target.$1, albumTitle: target.$2, files: copied);
    m.showSnackBar(SnackBar(content: Text('Добавлено треков: ${copied.length}')));
  } catch (_) {
    for (final c in copied) {
      await ImageStore.remove(c.path);
    }
    m.showSnackBar(const SnackBar(content: Text('Не удалось добавить треки')));
  }
}

class _TargetDialog extends StatefulWidget {
  const _TargetDialog({required this.count});
  final int count;
  @override
  State<_TargetDialog> createState() => _TargetDialogState();
}

class _TargetDialogState extends State<_TargetDialog> {
  final _artist = TextEditingController(text: 'Неизвестный исполнитель');
  final _album = TextEditingController(text: 'Синглы');

  @override
  void dispose() {
    _artist.dispose();
    _album.dispose();
    super.dispose();
  }

  void _submit() {
    final a = _artist.text.trim(), b = _album.text.trim();
    if (a.isNotEmpty && b.isNotEmpty) Navigator.pop(context, (a, b));
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text('Добавить треков: ${widget.count}'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: _artist,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Исполнитель'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _album,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Альбом', helperText: 'Треки попадут в этот альбом'),
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          TextButton(onPressed: _submit, child: const Text('Добавить')),
        ],
      );
}
