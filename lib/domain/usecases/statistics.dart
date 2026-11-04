import '../entities/album_view.dart';

class MonthPoint {
  const MonthPoint(this.label, this.added, this.rated);
  final String label;
  final int added, rated;
}

class Statistics {
  const Statistics({
    required this.albumCount,
    required this.artistCount,
    required this.ratedCount,
    required this.avgRating,
    required this.topGenres,
    required this.topAlbums,
    required this.distribution,
    required this.months,
  });
  final int albumCount, artistCount, ratedCount;
  final double? avgRating;
  final List<MapEntry<String, int>> topGenres;
  final List<AlbumView> topAlbums;

  /// Количество оценённых альбомов по целым корзинам 0..10 (floor).
  final List<int> distribution;
  final List<MonthPoint> months;
}

const _monthNames = ['янв', 'фев', 'мар', 'апр', 'май', 'июн', 'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'];

Statistics buildStatistics({
  required List<AlbumView> albums,
  required Map<int, List<String>> genresByAlbum,
  required List<DateTime> ratingDates,
  required DateTime now,
  int monthCount = 6,
}) {
  final rated = albums.where((a) => a.rating != null).toList();
  final dist = List<int>.filled(11, 0);
  for (final a in rated) {
    dist[a.rating!.floor().clamp(0, 10)]++;
  }
  final gc = <String, int>{};
  for (final a in albums) {
    for (final g in genresByAlbum[a.id] ?? const <String>[]) {
      gc[g] = (gc[g] ?? 0) + 1;
    }
  }
  final genres = gc.entries.toList()
    ..sort((a, b) {
      final c = b.value.compareTo(a.value);
      return c != 0 ? c : a.key.compareTo(b.key);
    });
  final months = <MonthPoint>[];
  for (var i = monthCount - 1; i >= 0; i--) {
    final d = DateTime(now.year, now.month - i);
    bool same(DateTime x) => x.year == d.year && x.month == d.month;
    months.add(MonthPoint(
      _monthNames[d.month - 1],
      albums.where((a) => same(a.addedAt)).length,
      ratingDates.where(same).length,
    ));
  }
  final top = [...rated]..sort((a, b) => b.rating!.compareTo(a.rating!));
  return Statistics(
    albumCount: albums.length,
    artistCount: {for (final a in albums) a.artistId}.length,
    ratedCount: rated.length,
    avgRating: rated.isEmpty ? null : rated.fold<double>(0, (s, a) => s + a.rating!) / rated.length,
    topGenres: genres.take(6).toList(),
    topAlbums: top.take(5).toList(),
    distribution: dist,
    months: months,
  );
}
