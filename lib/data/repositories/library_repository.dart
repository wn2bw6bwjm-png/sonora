import 'package:drift/drift.dart';

import '../../domain/entities/album_view.dart';
import '../media/image_store.dart';
import '../../domain/entities/rating_entry.dart';
import '../../domain/entities/track.dart';
import '../db/app_database.dart';

class LibraryRepository {
  LibraryRepository(this._db);
  final AppDatabase _db;

  Selectable<AlbumView> _query({Expression<bool>? where}) {
    final q = _db.select(_db.albums).join([
      innerJoin(_db.artists, _db.artists.id.equalsExp(_db.albums.artistId)),
      leftOuterJoin(_db.ratings, _db.ratings.albumId.equalsExp(_db.albums.id)),
      leftOuterJoin(_db.reviews, _db.reviews.albumId.equalsExp(_db.albums.id)),
      leftOuterJoin(_db.favorites, _db.favorites.albumId.equalsExp(_db.albums.id)),
    ]);
    if (where != null) q.where(where);
    q.orderBy([OrderingTerm.desc(_db.albums.addedAt), OrderingTerm.desc(_db.albums.id)]);
    return q.map((r) {
      final a = r.readTable(_db.albums);
      return AlbumView(
        id: a.id,
        artistId: a.artistId,
        title: a.title,
        artist: r.readTable(_db.artists).name,
        year: a.year,
        coverSeed: a.coverSeed,
        coverPath: a.coverPath,
        addedAt: a.addedAt,
        rating: r.readTableOrNull(_db.ratings)?.value,
        review: r.readTableOrNull(_db.reviews)?.body ?? '',
        isFavorite: r.readTableOrNull(_db.favorites) != null,
      );
    });
  }

  Stream<List<AlbumView>> watchAlbums() => _query().watch();

  Stream<List<AlbumView>> watchWhere(Expression<bool> where) => _query(where: where).watch();

  Stream<AlbumView?> watchAlbum(int id) =>
      _query(where: _db.albums.id.equals(id)).watchSingleOrNull();

  Future<int> _artistId(String name) async {
    final n = name.trim();
    final existing = await (_db.select(_db.artists)..where((t) => t.name.equals(n))).getSingleOrNull();
    if (existing != null) return existing.id;
    return _db.into(_db.artists).insert(ArtistsCompanion.insert(name: n));
  }

  Future<void> _pruneArtists() => _db.customStatement(
      'DELETE FROM artists WHERE id NOT IN (SELECT artist_id FROM albums)');

  Future<int> addAlbum({
    required String title,
    required String artist,
    int? year,
    List<String> genres = const [],
    List<TrackInput> tracks = const [],
    String? coverPath,
  }) =>
      _db.transaction(() async {
        final artistId = await _artistId(artist);
        final id = await _db.into(_db.albums).insert(AlbumsCompanion.insert(
              artistId: artistId,
              title: title.trim(),
              year: Value(year),
              coverPath: Value(coverPath),
              coverSeed: '${artist.trim()}|${title.trim()}',
            ));
        await _setGenres(id, genres);
        await _setTracks(id, tracks);
        return id;
      });

  Future<void> updateAlbum(
    int id, {
    required String title,
    required String artist,
    int? year,
    List<String> genres = const [],
    List<TrackInput> tracks = const [],
    String? coverPath,
  }) =>
      _db.transaction(() async {
        final artistId = await _artistId(artist);
        await (_db.update(_db.albums)..where((t) => t.id.equals(id))).write(
          AlbumsCompanion(artistId: Value(artistId), title: Value(title.trim()), year: Value(year), coverPath: Value(coverPath)),
        );
        await _setGenres(id, genres);
        await _setTracks(id, tracks);
        await _pruneArtists();
      });

  /// Добавляет отдельные треки в альбом исполнителя (создаёт его при необходимости).
  Future<int> importTracks({
    required String artist,
    required String albumTitle,
    required List<ImportedAudio> files,
  }) =>
      _db.transaction(() async {
        final artistId = await _artistId(artist);
        final title = albumTitle.trim();
        final found = (await (_db.select(_db.albums)
                  ..where((t) => t.artistId.equals(artistId) & t.title.equals(title)))
                .get())
            .firstOrNull;
        final albumId = found?.id ??
            await _db.into(_db.albums).insert(AlbumsCompanion.insert(
                artistId: artistId, title: title, coverSeed: '${artist.trim()}|$title'));
        final last = (await (_db.select(_db.tracks)
                  ..where((t) => t.albumId.equals(albumId))
                  ..orderBy([(t) => OrderingTerm.desc(t.number)])
                  ..limit(1))
                .get())
            .firstOrNull;
        var n = last?.number ?? 0;
        for (final f in files) {
          n++;
          await _db.into(_db.tracks).insert(TracksCompanion.insert(
              albumId: albumId, number: n, title: f.title, filePath: Value(f.path)));
        }
        return albumId;
      });

  Future<void> _pruneGenres() => _db.customStatement(
      'DELETE FROM genres WHERE id NOT IN (SELECT genre_id FROM album_genres)');

  Future<void> _setGenres(int albumId, List<String> names) async {
    await (_db.delete(_db.albumGenres)..where((t) => t.albumId.equals(albumId))).go();
    for (final n in names.map((e) => e.trim()).where((e) => e.isNotEmpty).toSet()) {
      await _db.into(_db.genres).insert(GenresCompanion.insert(name: n), mode: InsertMode.insertOrIgnore);
      final g = await (_db.select(_db.genres)..where((t) => t.name.equals(n))).getSingle();
      await _db.into(_db.albumGenres).insert(
          AlbumGenresCompanion.insert(albumId: albumId, genreId: g.id),
          mode: InsertMode.insertOrIgnore);
    }
    await _pruneGenres();
  }

  /// Обновляет треки на месте по номеру, чтобы id (избранное, плейлисты) сохранялись.
  Future<void> _setTracks(int albumId, List<TrackInput> tracks) async {
    final existing = await (_db.select(_db.tracks)
          ..where((t) => t.albumId.equals(albumId))
          ..orderBy([(t) => OrderingTerm.asc(t.number)]))
        .get();
    for (var i = 0; i < tracks.length; i++) {
      if (i < existing.length) {
        await (_db.update(_db.tracks)..where((t) => t.id.equals(existing[i].id))).write(TracksCompanion(
            number: Value(i + 1), title: Value(tracks[i].title), durationMs: Value(tracks[i].durationMs)));
      } else {
        await _db.into(_db.tracks).insert(TracksCompanion.insert(
            albumId: albumId, number: i + 1, title: tracks[i].title, durationMs: Value(tracks[i].durationMs)));
      }
    }
    for (var i = tracks.length; i < existing.length; i++) {
      await (_db.delete(_db.tracks)..where((t) => t.id.equals(existing[i].id))).go();
    }
  }

  Stream<Map<int, List<String>>> watchGenreMap() {
    final q = _db.select(_db.albumGenres).join([
      innerJoin(_db.genres, _db.genres.id.equalsExp(_db.albumGenres.genreId)),
    ]);
    return q.watch().map((rows) {
      final m = <int, List<String>>{};
      for (final r in rows) {
        m.putIfAbsent(r.readTable(_db.albumGenres).albumId, () => []).add(r.readTable(_db.genres).name);
      }
      for (final l in m.values) {
        l.sort();
      }
      return m;
    });
  }

  Future<List<String>> genresOf(int albumId) async {
    final q = _db.select(_db.genres).join([
      innerJoin(_db.albumGenres, _db.albumGenres.genreId.equalsExp(_db.genres.id)),
    ])
      ..where(_db.albumGenres.albumId.equals(albumId));
    return (await q.get()).map((r) => r.readTable(_db.genres).name).toList()..sort();
  }

  TrackView _track(Track t) => TrackView(id: t.id, number: t.number, title: t.title, durationMs: t.durationMs, filePath: t.filePath);

  Selectable<Track> _tracksQuery(int albumId) => _db.select(_db.tracks)
    ..where((t) => t.albumId.equals(albumId))
    ..orderBy([(t) => OrderingTerm.asc(t.number)]);

  Future<void> setTrackFile(int trackId, String? path) => (_db.update(_db.tracks)
        ..where((t) => t.id.equals(trackId)))
      .write(TracksCompanion(filePath: Value(path)));

  Stream<List<TrackView>> watchTracks(int albumId) =>
      _tracksQuery(albumId).watch().map((l) => l.map(_track).toList());

  Future<List<TrackView>> tracksOf(int albumId) async =>
      (await _tracksQuery(albumId).get()).map(_track).toList();

  Future<void> deleteAlbum(int id) async {
    final tracks = await (_db.select(_db.tracks)..where((t) => t.albumId.equals(id))).get();
    final album = await (_db.select(_db.albums)..where((t) => t.id.equals(id))).getSingleOrNull();
    await _db.transaction(() async {
      await (_db.delete(_db.albums)..where((t) => t.id.equals(id))).go();
      await _pruneArtists();
      await _pruneGenres();
    });
    // Удаляем только копии внутри приложения, оригиналы на телефоне не трогаем.
    for (final t in tracks) {
      await ImageStore.remove(t.filePath);
    }
    await ImageStore.remove(album?.coverPath);
  }

  Future<void> setRating(int albumId, double? value) async {
    if (value == null) {
      await (_db.delete(_db.ratings)..where((t) => t.albumId.equals(albumId))).go();
      return;
    }
    final v = value.clamp(0, 10).toDouble();
    await _db.transaction(() async {
      final prev = await (_db.select(_db.ratings)..where((t) => t.albumId.equals(albumId))).getSingleOrNull();
      final now = DateTime.now();
      await _db.into(_db.ratings).insertOnConflictUpdate(
          RatingsCompanion.insert(albumId: Value(albumId), value: v, updatedAt: now));
      if (prev == null || prev.value != v) {
        await _db.into(_db.ratingHistory).insert(
            RatingHistoryCompanion.insert(albumId: albumId, value: v, ratedAt: now));
      }
    });
  }

  Stream<List<RatingEntry>> watchRatingHistory(int albumId) => (_db.select(_db.ratingHistory)
        ..where((t) => t.albumId.equals(albumId))
        ..orderBy([(t) => OrderingTerm.desc(t.ratedAt), (t) => OrderingTerm.desc(t.id)]))
      .watch()
      .map((l) => l.map((e) => RatingEntry(e.value, e.ratedAt)).toList());

  Future<void> logPlay(int albumId, int? trackId) => _db.into(_db.listeningHistory).insert(
      ListeningHistoryCompanion.insert(albumId: albumId, trackId: Value(trackId), playedAt: DateTime.now()));

  Stream<List<int>> watchRecentlyPlayedIds() => (_db.select(_db.listeningHistory)
        ..orderBy([(t) => OrderingTerm.desc(t.playedAt), (t) => OrderingTerm.desc(t.id)])
        ..limit(60))
      .watch()
      .map((rows) {
    final seen = <int>{};
    final out = <int>[];
    for (final r in rows) {
      if (seen.add(r.albumId)) out.add(r.albumId);
      if (out.length >= 10) break;
    }
    return out;
  });

  Stream<List<DateTime>> watchRatingDates() =>
      _db.select(_db.ratingHistory).watch().map((l) => l.map((e) => e.ratedAt).toList());

  Future<void> saveReview(int albumId, String body) async {
    final text = body.trim();
    if (text.isEmpty) {
      await (_db.delete(_db.reviews)..where((t) => t.albumId.equals(albumId))).go();
      return;
    }
    await _db.into(_db.reviews).insertOnConflictUpdate(
        ReviewsCompanion.insert(albumId: Value(albumId), body: text, updatedAt: DateTime.now()));
  }

  Future<void> toggleFavorite(int albumId) => _db.transaction(() async {
        final removed =
            await (_db.delete(_db.favorites)..where((t) => t.albumId.equals(albumId))).go();
        if (removed == 0) {
          await _db.into(_db.favorites).insert(FavoritesCompanion.insert(albumId: Value(albumId)));
        }
      });
}
