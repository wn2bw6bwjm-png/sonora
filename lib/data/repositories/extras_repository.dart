import 'package:drift/drift.dart';

import '../../domain/entities/artist_info.dart';
import '../../domain/entities/playlist_view.dart';
import '../../domain/entities/track_entry.dart';
import '../db/app_database.dart';

/// Исполнители, треки, плейлисты и избранное для них.
class ExtrasRepository {
  ExtrasRepository(this._db);
  final AppDatabase _db;

  // ---- треки
  TrackEntry _entry(TypedResult r) {
    final t = r.readTable(_db.tracks);
    final a = r.readTable(_db.albums);
    return TrackEntry(
      trackId: t.id,
      number: t.number,
      title: t.title,
      durationMs: t.durationMs,
      albumId: a.id,
      albumTitle: a.title,
      artist: r.readTable(_db.artists).name,
      coverSeed: a.coverSeed,
      coverPath: a.coverPath,
      filePath: t.filePath,
      isFavorite: r.readTableOrNull(_db.favoriteTracks) != null,
    );
  }

  Selectable<TrackEntry> _tracksQ({Expression<bool>? where}) {
    final q = _db.select(_db.tracks).join([
      innerJoin(_db.albums, _db.albums.id.equalsExp(_db.tracks.albumId)),
      innerJoin(_db.artists, _db.artists.id.equalsExp(_db.albums.artistId)),
      leftOuterJoin(_db.favoriteTracks, _db.favoriteTracks.trackId.equalsExp(_db.tracks.id)),
    ]);
    if (where != null) q.where(where);
    q.orderBy([
      OrderingTerm.asc(_db.artists.name),
      OrderingTerm.asc(_db.albums.title),
      OrderingTerm.asc(_db.tracks.number),
    ]);
    return q.map(_entry);
  }

  Stream<List<TrackEntry>> watchAllTracks() => _tracksQ().watch();

  Stream<List<TrackEntry>> watchFavoriteTracks() =>
      _tracksQ(where: _db.favoriteTracks.trackId.isNotNull()).watch();

  Future<void> toggleFavoriteTrack(int trackId) => _db.transaction(() async {
        final n = await (_db.delete(_db.favoriteTracks)..where((t) => t.trackId.equals(trackId))).go();
        if (n == 0) await _db.into(_db.favoriteTracks).insert(FavoriteTracksCompanion.insert(trackId: Value(trackId)));
      });

  Future<void> renameTrack(int trackId, String title) => (_db.update(_db.tracks)
        ..where((t) => t.id.equals(trackId)))
      .write(TracksCompanion(title: Value(title.trim())));

  /// Удаляет трек и возвращает относительный путь его аудиофайла (для очистки).
  Future<String?> deleteTrack(int trackId) async {
    final row = await (_db.select(_db.tracks)..where((t) => t.id.equals(trackId))).getSingleOrNull();
    await (_db.delete(_db.tracks)..where((t) => t.id.equals(trackId))).go();
    return row?.filePath;
  }

  // ---- исполнители
  ArtistInfo _artist(TypedResult r) {
    final a = r.readTable(_db.artists);
    return ArtistInfo(
      id: a.id,
      name: a.name,
      bio: a.bio,
      imagePath: a.imagePath,
      isFavorite: r.readTableOrNull(_db.favoriteArtists) != null,
    );
  }

  Selectable<ArtistInfo> _artistsQ({Expression<bool>? where}) {
    final q = _db.select(_db.artists).join([
      leftOuterJoin(_db.favoriteArtists, _db.favoriteArtists.artistId.equalsExp(_db.artists.id)),
    ]);
    if (where != null) q.where(where);
    q.orderBy([OrderingTerm.asc(_db.artists.name)]);
    return q.map(_artist);
  }

  Stream<List<ArtistInfo>> watchArtists() => _artistsQ().watch();

  Stream<List<ArtistInfo>> watchFavoriteArtists() =>
      _artistsQ(where: _db.favoriteArtists.artistId.isNotNull()).watch();

  Stream<ArtistInfo?> watchArtist(int id) =>
      _artistsQ(where: _db.artists.id.equals(id)).watchSingleOrNull();

  Future<void> updateArtist(int id, {required String bio, String? imagePath}) =>
      (_db.update(_db.artists)..where((t) => t.id.equals(id)))
          .write(ArtistsCompanion(bio: Value(bio.trim()), imagePath: Value(imagePath)));

  Future<void> toggleFavoriteArtist(int id) => _db.transaction(() async {
        final n = await (_db.delete(_db.favoriteArtists)..where((t) => t.artistId.equals(id))).go();
        if (n == 0) await _db.into(_db.favoriteArtists).insert(FavoriteArtistsCompanion.insert(artistId: Value(id)));
      });

  // ---- плейлисты
  Stream<List<PlaylistView>> watchPlaylists() => _db
      .customSelect(
        'SELECT p.id, p.name, '
        '(SELECT COUNT(*) FROM playlist_tracks pt WHERE pt.playlist_id = p.id) AS cnt '
        'FROM playlists p ORDER BY p.created_at DESC, p.id DESC',
        readsFrom: {_db.playlists, _db.playlistTracks},
      )
      .watch()
      .map((rows) => [
            for (final r in rows)
              PlaylistView(id: r.read<int>('id'), name: r.read<String>('name'), count: r.read<int>('cnt')),
          ]);

  Stream<List<TrackEntry>> watchPlaylistTracks(int playlistId) {
    final q = _db.select(_db.playlistTracks).join([
      innerJoin(_db.tracks, _db.tracks.id.equalsExp(_db.playlistTracks.trackId)),
      innerJoin(_db.albums, _db.albums.id.equalsExp(_db.tracks.albumId)),
      innerJoin(_db.artists, _db.artists.id.equalsExp(_db.albums.artistId)),
      leftOuterJoin(_db.favoriteTracks, _db.favoriteTracks.trackId.equalsExp(_db.tracks.id)),
    ])
      ..where(_db.playlistTracks.playlistId.equals(playlistId))
      ..orderBy([OrderingTerm.asc(_db.playlistTracks.position)]);
    return q.map(_entry).watch();
  }

  Stream<Set<int>> watchPlaylistIdsFor(int trackId) =>
      (_db.select(_db.playlistTracks)..where((t) => t.trackId.equals(trackId)))
          .watch()
          .map((l) => l.map((e) => e.playlistId).toSet());

  Future<int> createPlaylist(String name) =>
      _db.into(_db.playlists).insert(PlaylistsCompanion.insert(name: name.trim()));

  Future<void> renamePlaylist(int id, String name) => (_db.update(_db.playlists)
        ..where((t) => t.id.equals(id)))
      .write(PlaylistsCompanion(name: Value(name.trim())));

  Future<void> deletePlaylist(int id) =>
      (_db.delete(_db.playlists)..where((t) => t.id.equals(id))).go();

  Future<void> addToPlaylist(int playlistId, int trackId) => _db.transaction(() async {
        final count =
            (await (_db.select(_db.playlistTracks)..where((t) => t.playlistId.equals(playlistId))).get()).length;
        await _db.into(_db.playlistTracks).insert(
            PlaylistTracksCompanion.insert(playlistId: playlistId, trackId: trackId, position: count),
            mode: InsertMode.insertOrIgnore);
      });

  Future<void> removeFromPlaylist(int playlistId, int trackId) => (_db.delete(_db.playlistTracks)
        ..where((t) => t.playlistId.equals(playlistId) & t.trackId.equals(trackId)))
      .go();
}
