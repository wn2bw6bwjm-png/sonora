import 'package:flutter_test/flutter_test.dart';
import 'package:sonora/domain/entities/album_view.dart';
import 'package:sonora/domain/usecases/statistics.dart';

AlbumView _a(int id, int artist, double? r, DateTime added) => AlbumView(
    id: id, artistId: artist, title: 'T$id', artist: 'A$artist', coverSeed: 's', addedAt: added, rating: r);

void main() {
  test('computes counts, distribution, genres and months from real data', () {
    final now = DateTime(2026, 11, 15);
    final albums = [
      _a(1, 1, 9.5, DateTime(2026, 11, 1)),
      _a(2, 1, 9.0, DateTime(2026, 10, 3)),
      _a(3, 2, null, DateTime(2026, 10, 9)),
    ];
    final s = buildStatistics(
      albums: albums,
      genresByAlbum: {1: ['Jazz'], 2: ['Jazz', 'Folk'], 3: ['Folk']},
      ratingDates: [DateTime(2026, 11, 2), DateTime(2026, 10, 4)],
      now: now,
    );
    expect(s.albumCount, 3);
    expect(s.artistCount, 2);
    expect(s.ratedCount, 2);
    expect(s.avgRating, closeTo(9.25, 1e-9));
    expect(s.distribution[9], 2);
    expect(s.topGenres.first.key, 'Folk'); // 2 vs 2, алфавитный порядок
    expect(s.months.length, 6);
    expect(s.months.last.added, 1);
    expect(s.months[4].added, 2);
    expect(s.months.last.rated, 1);
  });
}
