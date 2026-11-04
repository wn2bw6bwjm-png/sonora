import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Artists, Albums, Ratings, Reviews, Favorites, Collections, CollectionAlbums, SearchHistory, Genres, AlbumGenres, Tracks, RatingHistory, ListeningHistory, Playlists, PlaylistTracks, FavoriteArtists, FavoriteTracks])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'sonora'));

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(collections);
            await m.createTable(collectionAlbums);
            await m.createTable(searchHistory);
          }
          if (from < 3) {
            await m.createTable(genres);
            await m.createTable(albumGenres);
            await m.createTable(tracks);
          }
          if (from < 4) {
            await m.createTable(ratingHistory);
            await customStatement('INSERT INTO rating_history (album_id, value, rated_at) '
                'SELECT album_id, value, updated_at FROM ratings');
          }
          if (from < 5) {
            await m.createTable(listeningHistory);
          }
          if (from < 6) {
            await m.addColumn(artists, artists.bio);
            await m.addColumn(artists, artists.imagePath);
            await m.addColumn(albums, albums.coverPath);
            if (from >= 2) await m.addColumn(collections, collections.coverPath);
            await m.createTable(playlists);
            await m.createTable(playlistTracks);
            await m.createTable(favoriteArtists);
            await m.createTable(favoriteTracks);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
