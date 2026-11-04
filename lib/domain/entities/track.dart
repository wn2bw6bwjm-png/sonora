import '../../core/utils/format.dart';

class TrackView {
  const TrackView({required this.id, required this.number, required this.title, this.durationMs, this.filePath});
  final int id, number;
  final String title;
  final int? durationMs;
  final String? filePath;
}

class TrackInput {
  const TrackInput(this.title, [this.durationMs]);
  final String title;
  final int? durationMs;
}

/// Одна строка = один трек. Длительность необязательна: «Название 3:45».
List<TrackInput> parseTracklist(String text) {
  final re = RegExp(r'^(.*?)\s+(\d{1,3}):([0-5]\d)$');
  final out = <TrackInput>[];
  for (final raw in text.split('\n')) {
    final line = raw.trim();
    if (line.isEmpty) continue;
    final m = re.firstMatch(line);
    if (m != null && m.group(1)!.trim().isNotEmpty) {
      out.add(TrackInput(m.group(1)!.trim(), (int.parse(m.group(2)!) * 60 + int.parse(m.group(3)!)) * 1000));
    } else {
      out.add(TrackInput(line));
    }
  }
  return out;
}

String formatTracklist(List<TrackView> tracks) => tracks
    .map((t) => t.durationMs == null ? t.title : '${t.title} ${fmtDuration(t.durationMs!)}')
    .join('\n');

List<String> parseGenres(String text) =>
    text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

class ImportedAudio {
  const ImportedAudio(this.title, this.path);
  final String title, path;
}

/// «01 - Song_Name.mp3» -> «Song Name».
String titleFromFilename(String fileName) {
  var s = fileName;
  final dot = s.lastIndexOf('.');
  if (dot > 0) s = s.substring(0, dot);
  s = s.replaceAll('_', ' ').trim();
  s = s.replaceFirst(RegExp(r'^\d{1,3}\s*[-.)]*\s+'), '').trim();
  return s.isEmpty ? fileName : s;
}
