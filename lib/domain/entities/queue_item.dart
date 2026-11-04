class QueueItem {
  const QueueItem({
    required this.trackId,
    required this.albumId,
    required this.title,
    required this.artist,
    required this.albumTitle,
    required this.coverSeed,
    this.durationMs,
    this.coverPath,
    this.filePath,
  });
  final int trackId, albumId;
  final String title, artist, albumTitle, coverSeed;
  final int? durationMs;
  final String? coverPath;
  final String? filePath;
}
