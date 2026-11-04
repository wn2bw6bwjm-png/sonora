import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../db/app_database.dart';
import '../media/image_store.dart';

class BackupException implements Exception {
  const BackupException(this.message);
  final String message;
  @override
  String toString() => message;
}

class BackupInfo {
  const BackupInfo(this.file, this.modified, this.bytes);
  final File file;
  final DateTime modified;
  final int bytes;
}

class BackupService {
  BackupService(this._db);
  final AppDatabase _db;

  static const _format = 1;

  Future<String> exportJson() async {
    Future<List<Map<String, dynamic>>> rows<T>(Future<List<dynamic>> q) async =>
        [for (final r in await q) (r as dynamic).toJson() as Map<String, dynamic>];
    final data = <String, dynamic>{
      'app': 'sonora',
      'format': _format,
      'schemaVersion': _db.schemaVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'artists': await rows(_db.select(_db.artists).get()),
      'albums': await rows(_db.select(_db.albums).get()),
      'genres': await rows(_db.select(_db.genres).get()),
      'albumGenres': await rows(_db.select(_db.albumGenres).get()),
      'tracks': await rows(_db.select(_db.tracks).get()),
      'ratings': await rows(_db.select(_db.ratings).get()),
      'reviews': await rows(_db.select(_db.reviews).get()),
      'favorites': await rows(_db.select(_db.favorites).get()),
      'collections': await rows(_db.select(_db.collections).get()),
      'collectionAlbums': await rows(_db.select(_db.collectionAlbums).get()),
      'ratingHistory': await rows(_db.select(_db.ratingHistory).get()),
      'listeningHistory': await rows(_db.select(_db.listeningHistory).get()),
      'playlists': await rows(_db.select(_db.playlists).get()),
      'playlistTracks': await rows(_db.select(_db.playlistTracks).get()),
      'favoriteArtists': await rows(_db.select(_db.favoriteArtists).get()),
      'favoriteTracks': await rows(_db.select(_db.favoriteTracks).get()),
    };
    final images = <String, String>{};
    for (final entry in const {'artists': 'imagePath', 'albums': 'coverPath', 'collections': 'coverPath'}.entries) {
      for (final row in data[entry.key] as List) {
        final rel = (row as Map)[entry.value] as String?;
        final path = ImageStore.resolve(rel);
        if (rel != null && path != null && !images.containsKey(rel)) {
          images[rel] = base64Encode(await File(path).readAsBytes());
        }
      }
    }
    data['images'] = images;
    return jsonEncode(data);
  }

  Future<void> restoreFromJson(String text, {bool safetyCopy = true}) async {
    final Map<String, dynamic> data;
    try {
      data = jsonDecode(text) as Map<String, dynamic>;
    } catch (_) {
      throw const BackupException('Файл не является резервной копией SONORA.');
    }
    if (data['app'] != 'sonora' || data['schemaVersion'] is! int) {
      throw const BackupException('Файл не является резервной копией SONORA.');
    }
    if ((data['schemaVersion'] as int) > _db.schemaVersion) {
      throw const BackupException('Копия создана в более новой версии приложения.');
    }
    List<Map<String, dynamic>> rows(String k) => [
          for (final r in (data[k] as List? ?? const [])) Map<String, dynamic>.from(r as Map),
        ];

    if (safetyCopy) await createBackup(prefix: 'before_restore');
    await _restoreImages(data['images']);

    try {
      await _db.transaction(() async {
        await _wipe();
        for (final r in rows('artists')) {
          r.putIfAbsent('bio', () => '');
          await _db.into(_db.artists).insert(Artist.fromJson(r));
        }
        for (final r in rows('albums')) {
          await _db.into(_db.albums).insert(Album.fromJson(r));
        }
        for (final r in rows('genres')) {
          await _db.into(_db.genres).insert(Genre.fromJson(r));
        }
        for (final r in rows('albumGenres')) {
          await _db.into(_db.albumGenres).insert(AlbumGenre.fromJson(r));
        }
        for (final r in rows('tracks')) {
          await _db.into(_db.tracks).insert(Track.fromJson(r));
        }
        for (final r in rows('playlists')) {
          await _db.into(_db.playlists).insert(Playlist.fromJson(r));
        }
        for (final r in rows('playlistTracks')) {
          await _db.into(_db.playlistTracks).insert(PlaylistTrack.fromJson(r));
        }
        for (final r in rows('favoriteArtists')) {
          await _db.into(_db.favoriteArtists).insert(FavoriteArtist.fromJson(r));
        }
        for (final r in rows('favoriteTracks')) {
          await _db.into(_db.favoriteTracks).insert(FavoriteTrack.fromJson(r));
        }
        for (final r in rows('ratings')) {
          await _db.into(_db.ratings).insert(Rating.fromJson(r));
        }
        for (final r in rows('reviews')) {
          await _db.into(_db.reviews).insert(Review.fromJson(r));
        }
        for (final r in rows('favorites')) {
          await _db.into(_db.favorites).insert(Favorite.fromJson(r));
        }
        for (final r in rows('collections')) {
          await _db.into(_db.collections).insert(CollectionRow.fromJson(r));
        }
        for (final r in rows('collectionAlbums')) {
          await _db.into(_db.collectionAlbums).insert(CollectionAlbum.fromJson(r));
        }
        for (final r in rows('ratingHistory')) {
          await _db.into(_db.ratingHistory).insert(RatingHistoryRow.fromJson(r));
        }
        for (final r in rows('listeningHistory')) {
          await _db.into(_db.listeningHistory).insert(ListeningHistoryData.fromJson(r));
        }
      });
    } catch (_) {
      throw const BackupException('Не удалось восстановить данные: файл повреждён или несовместим. Текущие данные не изменены.');
    }
  }

  Future<void> _restoreImages(dynamic raw) async {
    final base = ImageStore.baseDir;
    if (base == null || raw is! Map) return;
    for (final e in raw.entries) {
      final rel = e.key as String;
      if (!rel.startsWith('images/') || rel.contains('..')) continue;
      final f = File('$base/$rel');
      await f.parent.create(recursive: true);
      await f.writeAsBytes(base64Decode(e.value as String), flush: true);
    }
  }

  Future<void> _wipe() async {
    await _db.delete(_db.playlistTracks).go();
    await _db.delete(_db.playlists).go();
    await _db.delete(_db.favoriteTracks).go();
    await _db.delete(_db.favoriteArtists).go();
    await _db.delete(_db.listeningHistory).go();
    await _db.delete(_db.collectionAlbums).go();
    await _db.delete(_db.collections).go();
    await _db.delete(_db.ratingHistory).go();
    await _db.delete(_db.favorites).go();
    await _db.delete(_db.reviews).go();
    await _db.delete(_db.ratings).go();
    await _db.delete(_db.tracks).go();
    await _db.delete(_db.albumGenres).go();
    await _db.delete(_db.genres).go();
    await _db.delete(_db.albums).go();
    await _db.delete(_db.artists).go();
  }

  Future<void> clearLibrary() async {
    await _db.transaction(() async {
      await _wipe();
      await _db.delete(_db.searchHistory).go();
    });
    await ImageStore.clearAll();
  }

  Future<Directory> _dir() async {
    final base = await getApplicationDocumentsDirectory();
    final d = Directory('${base.path}/backups');
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  Future<File> createBackup({String prefix = 'sonora'}) async {
    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    final name = '${prefix}_${now.year}${two(now.month)}${two(now.day)}_${two(now.hour)}${two(now.minute)}${two(now.second)}.json';
    final file = File('${(await _dir()).path}/$name');
    return file.writeAsString(await exportJson(), flush: true);
  }

  Future<List<BackupInfo>> listBackups() async {
    final out = <BackupInfo>[];
    await for (final e in (await _dir()).list()) {
      if (e is File && e.path.endsWith('.json')) {
        final st = await e.stat();
        out.add(BackupInfo(e, st.modified, st.size));
      }
    }
    out.sort((a, b) => b.modified.compareTo(a.modified));
    return out;
  }

  Future<void> restoreFromFile(File f) async => restoreFromJson(await f.readAsString());

  Future<void> deleteBackup(File f) async {
    if (await f.exists()) await f.delete();
  }
}
