import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sonora/data/backup/backup_service.dart';
import 'package:sonora/data/db/app_database.dart';
import 'package:sonora/data/repositories/library_repository.dart';
import 'package:sonora/domain/entities/track.dart';

// Требует системную библиотеку sqlite3 на машине разработчика (есть на macOS).
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test('export then restore preserves albums, ratings, reviews, tracks', () async {
    final a = AppDatabase(NativeDatabase.memory());
    final repoA = LibraryRepository(a);
    final id = await repoA.addAlbum(
      title: 'Room Tone',
      artist: 'The Quiet Instruments',
      year: 2020,
      genres: const ['Jazz', 'Ambient'],
      tracks: parseTracklist('One 3:10\nTwo'),
    );
    await repoA.setRating(id, 8.5);
    await repoA.saveReview(id, 'Тихий и точный.');
    await repoA.toggleFavorite(id);
    final json = await BackupService(a).exportJson();
    await a.close();

    final b = AppDatabase(NativeDatabase.memory());
    await BackupService(b).restoreFromJson(json, safetyCopy: false);
    final repoB = LibraryRepository(b);
    final albums = await repoB.watchAlbums().first;
    expect(albums.length, 1);
    expect(albums.single.title, 'Room Tone');
    expect(albums.single.rating, 8.5);
    expect(albums.single.review, 'Тихий и точный.');
    expect(albums.single.isFavorite, true);
    expect((await repoB.tracksOf(albums.single.id)).length, 2);
    expect(await repoB.genresOf(albums.single.id), ['Ambient', 'Jazz']);
    await b.close();
  });

  test('rejects foreign files', () async {
    final db = AppDatabase(NativeDatabase.memory());
    expect(
      () => BackupService(db).restoreFromJson('{"hello":1}', safetyCopy: false),
      throwsA(isA<BackupException>()),
    );
    await db.close();
  });
}
