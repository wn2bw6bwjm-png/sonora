import 'package:drift/drift.dart';

import '../../domain/entities/album_view.dart';
import '../../domain/entities/collection_view.dart';
import '../db/app_database.dart';
import 'library_repository.dart';

class CollectionRepository {
  CollectionRepository(this._db, this._library);
  final AppDatabase _db;
  final LibraryRepository _library;

  static const _sql = '''
SELECT c.id, c.name, c.is_favorite, c.cover_path,
  (SELECT COUNT(*) FROM collection_albums ca WHERE ca.collection_id = c.id) AS cnt,
  (SELECT AVG(r.value) FROM collection_albums ca JOIN ratings r ON r.album_id = ca.album_id
     WHERE ca.collection_id = c.id) AS avg_rating,
  (SELECT group_concat(cover_seed, '§') FROM (
     SELECT a.cover_seed FROM collection_albums ca JOIN albums a ON a.id = ca.album_id
     WHERE ca.collection_id = c.id ORDER BY ca.added_at LIMIT 4)) AS seeds
FROM collections c ORDER BY c.is_favorite DESC, c.created_at DESC, c.id DESC
''';

  Stream<List<CollectionView>> watchCollections() => _db
      .customSelect(_sql, readsFrom: {
        _db.collections,
        _db.collectionAlbums,
        _db.albums,
        _db.ratings,
      })
      .watch()
      .map((rows) => rows.map((r) {
            final seeds = r.readNullable<String>('seeds');
            return CollectionView(
              id: r.read<int>('id'),
              name: r.read<String>('name'),
              isFavorite: r.read<bool>('is_favorite'),
              count: r.read<int>('cnt'),
              avgRating: r.readNullable<double>('avg_rating'),
              coverPath: r.readNullable<String>('cover_path'),
              seeds: seeds == null ? const [] : seeds.split('§'),
            );
          }).toList());

  Stream<CollectionView?> watchCollection(int id) =>
      watchCollections().map((l) => l.where((c) => c.id == id).firstOrNull);

  Stream<Set<int>> watchAlbumIdsIn(int collectionId) =>
      (_db.select(_db.collectionAlbums)..where((t) => t.collectionId.equals(collectionId)))
          .watch()
          .map((l) => l.map((e) => e.albumId).toSet());

  Stream<Set<int>> watchCollectionIdsFor(int albumId) =>
      (_db.select(_db.collectionAlbums)..where((t) => t.albumId.equals(albumId)))
          .watch()
          .map((l) => l.map((e) => e.collectionId).toSet());

  Stream<List<AlbumView>> watchAlbums(int collectionId) {
    final sub = _db.selectOnly(_db.collectionAlbums)
      ..addColumns([_db.collectionAlbums.albumId])
      ..where(_db.collectionAlbums.collectionId.equals(collectionId));
    return _library.watchWhere(_db.albums.id.isInQuery(sub));
  }

  Future<int> create(String name) =>
      _db.into(_db.collections).insert(CollectionsCompanion.insert(name: name.trim()));

  Future<void> rename(int id, String name) => (_db.update(_db.collections)
        ..where((t) => t.id.equals(id)))
      .write(CollectionsCompanion(name: Value(name.trim())));

  Future<void> setCover(int id, String? path) => (_db.update(_db.collections)
        ..where((t) => t.id.equals(id)))
      .write(CollectionsCompanion(coverPath: Value(path)));

  Future<void> delete(int id) =>
      (_db.delete(_db.collections)..where((t) => t.id.equals(id))).go();

  Future<void> toggleFavorite(int id, bool current) => (_db.update(_db.collections)
        ..where((t) => t.id.equals(id)))
      .write(CollectionsCompanion(isFavorite: Value(!current)));

  Future<void> addAlbum(int collectionId, int albumId) => _db.into(_db.collectionAlbums).insert(
      CollectionAlbumsCompanion.insert(collectionId: collectionId, albumId: albumId),
      mode: InsertMode.insertOrIgnore);

  Future<void> removeAlbum(int collectionId, int albumId) => (_db.delete(_db.collectionAlbums)
        ..where((t) => t.collectionId.equals(collectionId) & t.albumId.equals(albumId)))
      .go();
}
