import 'package:flutter_test/flutter_test.dart';
import 'package:sonora/domain/entities/album_view.dart';
import 'package:sonora/domain/usecases/recommend.dart';

AlbumView _a(int id, String title, double? rating, {String artist = 'A', int day = 1}) => AlbumView(
    id: id, artistId: 1, title: title, artist: artist, coverSeed: 's', addedAt: DateTime(2024, 1, day), rating: rating);

void main() {
  test('recommends unrated albums by genres of highly rated ones', () {
    final lib = [_a(1, 'Loved', 9), _a(2, 'Disliked', 4), _a(3, 'SameGenre', null), _a(4, 'OtherGenre', null)];
    final genres = {1: ['Jazz'], 2: ['Metal'], 3: ['Jazz'], 4: ['Metal']};
    expect(recommendFromLibrary(lib, genres).map((e) => e.title), ['SameGenre']);
  });

  test('uses onboarding preferences when there are no ratings', () {
    final lib = [_a(1, 'X', null, artist: 'Fav'), _a(2, 'Y', null), _a(3, 'Z', null)];
    final genres = {2: ['Folk'], 3: ['Rock']};
    final res = recommendFromLibrary(lib, genres, preferredGenres: ['Folk'], preferredArtists: ['fav']);
    expect(res.map((e) => e.title), ['X', 'Y']);
  });
}
