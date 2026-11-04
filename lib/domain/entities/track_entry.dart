import 'queue_item.dart';

class TrackEntry {
  const TrackEntry({
    required this.trackId,
    required this.number,
    required this.title,
    required this.albumId,
    required this.albumTitle,
    required this.artist,
    required this.coverSeed,
    this.durationMs,
    this.coverPath,
    this.filePath,
    this.isFavorite = false,
  });
  final int trackId, number, albumId;
  final String title, albumTitle, artist, coverSeed;
  final int? durationMs;
  final String? coverPath;
  final String? filePath;
  final bool isFavorite;

  QueueItem toQueueItem() => QueueItem(
        trackId: trackId,
        albumId: albumId,
        title: title,
        artist: artist,
        albumTitle: albumTitle,
        coverSeed: coverSeed,
        coverPath: coverPath,
        filePath: filePath,
        durationMs: durationMs,
      );
}
