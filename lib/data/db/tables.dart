import 'package:drift/drift.dart';

class Artists extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
  TextColumn get bio => text().withDefault(const Constant(''))();
  TextColumn get imagePath => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Albums extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get artistId =>
      integer().references(Artists, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text()();
  IntColumn get year => integer().nullable()();
  TextColumn get coverSeed => text()();
  TextColumn get coverPath => text().nullable()();
  DateTimeColumn get addedAt => dateTime().withDefault(currentDateAndTime)();
}

class Ratings extends Table {
  IntColumn get albumId =>
      integer().references(Albums, #id, onDelete: KeyAction.cascade)();
  RealColumn get value => real()();
  DateTimeColumn get updatedAt => dateTime()();
  @override
  Set<Column> get primaryKey => {albumId};
}

class Reviews extends Table {
  IntColumn get albumId =>
      integer().references(Albums, #id, onDelete: KeyAction.cascade)();
  TextColumn get body => text()();
  DateTimeColumn get updatedAt => dateTime()();
  @override
  Set<Column> get primaryKey => {albumId};
}

class Favorites extends Table {
  IntColumn get albumId =>
      integer().references(Albums, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  @override
  Set<Column> get primaryKey => {albumId};
}

@DataClassName('CollectionRow')
class Collections extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  TextColumn get coverPath => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class CollectionAlbums extends Table {
  IntColumn get collectionId =>
      integer().references(Collections, #id, onDelete: KeyAction.cascade)();
  IntColumn get albumId =>
      integer().references(Albums, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get addedAt => dateTime().withDefault(currentDateAndTime)();
  @override
  Set<Column> get primaryKey => {collectionId, albumId};
}

class SearchHistory extends Table {
  TextColumn get term => text()();
  DateTimeColumn get usedAt => dateTime()();
  @override
  Set<Column> get primaryKey => {term};
}

class Genres extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
}

class AlbumGenres extends Table {
  IntColumn get albumId =>
      integer().references(Albums, #id, onDelete: KeyAction.cascade)();
  IntColumn get genreId =>
      integer().references(Genres, #id, onDelete: KeyAction.cascade)();
  @override
  Set<Column> get primaryKey => {albumId, genreId};
}

class Tracks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get albumId =>
      integer().references(Albums, #id, onDelete: KeyAction.cascade)();
  IntColumn get number => integer()();
  TextColumn get title => text()();
  IntColumn get durationMs => integer().nullable()();
  TextColumn get filePath => text().nullable()();
}

@DataClassName('RatingHistoryRow')
class RatingHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get albumId =>
      integer().references(Albums, #id, onDelete: KeyAction.cascade)();
  RealColumn get value => real()();
  DateTimeColumn get ratedAt => dateTime()();
}

class ListeningHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get albumId =>
      integer().references(Albums, #id, onDelete: KeyAction.cascade)();
  IntColumn get trackId => integer().nullable()();
  DateTimeColumn get playedAt => dateTime()();
}

class Playlists extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class PlaylistTracks extends Table {
  IntColumn get playlistId =>
      integer().references(Playlists, #id, onDelete: KeyAction.cascade)();
  IntColumn get trackId =>
      integer().references(Tracks, #id, onDelete: KeyAction.cascade)();
  IntColumn get position => integer()();
  @override
  Set<Column> get primaryKey => {playlistId, trackId};
}

class FavoriteArtists extends Table {
  IntColumn get artistId =>
      integer().references(Artists, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  @override
  Set<Column> get primaryKey => {artistId};
}

class FavoriteTracks extends Table {
  IntColumn get trackId =>
      integer().references(Tracks, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  @override
  Set<Column> get primaryKey => {trackId};
}
