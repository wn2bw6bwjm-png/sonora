import 'dart:io';

import 'package:file_picker/file_picker.dart';

class PickedAudio {
  const PickedAudio(this.name, this.path);
  final String name, path;
}

/// Пользовательские файлы (картинки и аудио) хранятся в documents/images и documents/audio.
/// В БД лежит относительный путь, чтобы он переживал обновления приложения.
abstract final class ImageStore {
  static String? baseDir;

  static bool isUrl(String? s) => s != null && s.trim().startsWith('https://');

  static String? resolve(String? relative) {
    if (relative == null || baseDir == null || isUrl(relative)) return null;
    final full = '$baseDir/$relative';
    return File(full).existsSync() ? full : null;
  }

  static Future<Directory?> _dir(String name) async {
    final base = baseDir;
    if (base == null) return null;
    final d = Directory('$base/$name');
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  /// Возвращает относительный путь или null, если выбор отменён.
  static Future<String?> pick(String kind) async {
    final dir = await _dir('images');
    if (dir == null) return null;
    final res = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    final f = res?.files.single;
    if (f == null || f.bytes == null) return null;
    final ext = (f.extension ?? 'jpg').toLowerCase();
    final rel = 'images/${kind}_${DateTime.now().millisecondsSinceEpoch}.$ext';
    await File('$baseDir/$rel').writeAsBytes(f.bytes!, flush: true);
    return rel;
  }

  /// Копирует выбранный аудиофайл пользователя в хранилище приложения.
  static Future<String?> pickAudio() async {
    final dir = await _dir('audio');
    if (dir == null) return null;
    final res = await FilePicker.platform.pickFiles(type: FileType.audio);
    final f = res?.files.single;
    final src = f?.path;
    if (f == null || src == null) return null;
    final ext = (f.extension ?? 'mp3').toLowerCase();
    final rel = 'audio/track_${DateTime.now().millisecondsSinceEpoch}.$ext';
    await File(src).copy('$baseDir/$rel');
    return rel;
  }

  /// Выбор нескольких аудиофайлов без копирования (копирует copyAudio после подтверждения).
  static Future<List<PickedAudio>> pickAudioFiles() async {
    final res = await FilePicker.platform.pickFiles(type: FileType.audio, allowMultiple: true);
    if (res == null) return const [];
    return [for (final f in res.files) if (f.path != null) PickedAudio(f.name, f.path!)];
  }

  static Future<String> copyAudio(PickedAudio a) async {
    final dir = await _dir('audio');
    if (dir == null) throw StateError('Хранилище недоступно');
    final dot = a.name.lastIndexOf('.');
    final ext = dot > 0 ? a.name.substring(dot + 1).toLowerCase() : 'mp3';
    final rel = 'audio/track_${DateTime.now().microsecondsSinceEpoch}.$ext';
    await File(a.path).copy('$baseDir/$rel');
    return rel;
  }

  /// Удаляет все копии файлов приложения (аудио и картинки). Оригиналы вне приложения не затрагиваются.
  static Future<void> clearAll() async {
    final base = baseDir;
    if (base == null) return;
    for (final name in const ['audio', 'images']) {
      final d = Directory('$base/$name');
      if (await d.exists()) await d.delete(recursive: true);
    }
  }

  static Future<void> remove(String? relative) async {
    final path = resolve(relative);
    if (path != null) await File(path).delete();
  }
}
