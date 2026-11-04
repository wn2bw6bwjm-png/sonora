import '../entities/album_view.dart';

/// Рекомендует ещё не оценённые альбомы вашей библиотеки.
/// Жанры альбомов с оценкой 8+ получают вес (оценка - 7), выбранные при
/// знакомстве жанры по 1, любимые исполнители дают +1.5.
List<AlbumView> recommendFromLibrary(
  List<AlbumView> library,
  Map<int, List<String>> genresByAlbum, {
  List<String> preferredGenres = const [],
  List<String> preferredArtists = const [],
  int limit = 10,
}) {
  final weights = <String, double>{for (final g in preferredGenres) g: 1};
  for (final a in library) {
    final r = a.rating;
    if (r == null || r < 8) continue;
    for (final g in genresByAlbum[a.id] ?? const <String>[]) {
      weights[g] = (weights[g] ?? 0) + (r - 7);
    }
  }
  final artists = {for (final a in preferredArtists) a.toLowerCase()};
  final scored = <(AlbumView, double)>[];
  for (final a in library) {
    if (a.rating != null) continue;
    var s = (genresByAlbum[a.id] ?? const <String>[]).fold<double>(0, (sum, g) => sum + (weights[g] ?? 0));
    if (artists.contains(a.artist.toLowerCase())) s += 1.5;
    if (s > 0) scored.add((a, s));
  }
  scored.sort((a, b) {
    final c = b.$2.compareTo(a.$2);
    return c != 0 ? c : b.$1.addedAt.compareTo(a.$1.addedAt);
  });
  return scored.take(limit).map((e) => e.$1).toList();
}
