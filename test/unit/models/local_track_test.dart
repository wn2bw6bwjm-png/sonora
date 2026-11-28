import 'package:test/test.dart';
import 'package:sonora/data/models/local_track_model.dart';

void main() {
  group('LocalTrackModel', () {
    test('should create LocalTrackModel with all fields', () {
      final track = LocalTrackModel(
        id: 'local-1',
        originalPath: '/storage/emulated/0/Music/song.mp3',
        fileName: 'song.mp3',
        extension: 'mp3',
        title: 'Local Song',
        artist: 'Local Artist',
        album: 'Local Album',
        artworkPath: '/storage/emulated/0/Music/art.jpg',
        duration: const Duration(minutes: 3, seconds: 45),
        dateAdded: DateTime(2024, 1, 15),
        isAvailable: true,
        copiedPath: '/data/user/0/com.sonora/app_flutter/sonora_music/abc123.mp3',
      );

      expect(track.id, 'local-1');
      expect(track.originalPath, '/storage/emulated/0/Music/song.mp3');
      expect(track.fileName, 'song.mp3');
      expect(track.extension, 'mp3');
      expect(track.title, 'Local Song');
      expect(track.artist, 'Local Artist');
      expect(track.album, 'Local Album');
      expect(track.artworkPath, '/storage/emulated/0/Music/art.jpg');
      expect(track.duration, const Duration(minutes: 3, seconds: 45));
      expect(track.isAvailable, true);
      expect(track.copiedPath, '/data/user/0/com.sonora/app_flutter/sonora_music/abc123.mp3');
    });

    test('playbackPath should return copiedPath when available', () {
      final track = LocalTrackModel(
        id: 'local-2',
        originalPath: '/original/path.mp3',
        fileName: 'song.mp3',
        extension: 'mp3',
        title: 'Test',
        artist: 'Artist',
        duration: Duration.zero,
        dateAdded: DateTime.now(),
        isAvailable: true,
        copiedPath: '/copied/path.mp3',
      );

      expect(track.playbackPath, '/copied/path.mp3');
    });

    test('playbackPath should return originalPath when copiedPath is null', () {
      final track = LocalTrackModel(
        id: 'local-3',
        originalPath: '/original/path.mp3',
        fileName: 'song.mp3',
        extension: 'mp3',
        title: 'Test',
        artist: 'Artist',
        duration: Duration.zero,
        dateAdded: DateTime.now(),
        isAvailable: true,
      );

      expect(track.playbackPath, '/original/path.mp3');
    });

    test('copyWith should create new instance with updated fields', () {
      final original = LocalTrackModel(
        id: 'copy-test',
        originalPath: '/orig.mp3',
        fileName: 'orig.mp3',
        extension: 'mp3',
        title: 'Original',
        artist: 'Artist',
        duration: Duration.zero,
        dateAdded: DateTime.now(),
        isAvailable: true,
      );

      final updated = original.copyWith(
        title: 'Updated',
        isAvailable: false,
        copiedPath: '/new/path.mp3',
      );

      expect(updated.id, 'copy-test');
      expect(updated.title, 'Updated');
      expect(updated.isAvailable, false);
      expect(updated.copiedPath, '/new/path.mp3');
      expect(updated.artist, 'Artist'); // unchanged
      expect(updated.originalPath, '/orig.mp3'); // unchanged
    });

    test('toJson and fromJson should be symmetric', () {
      final track = LocalTrackModel(
        id: 'json-test',
        originalPath: '/test.mp3',
        fileName: 'test.mp3',
        extension: 'mp3',
        title: 'JSON Track',
        artist: 'JSON Artist',
        album: 'JSON Album',
        artworkPath: '/art.jpg',
        duration: const Duration(seconds: 200),
        dateAdded: DateTime(2024, 6, 1),
        isAvailable: true,
        copiedPath: '/copied/test.mp3',
      );

      final json = track.toJson();
      final restored = LocalTrackModel.fromJson(json);

      expect(restored.id, track.id);
      expect(restored.originalPath, track.originalPath);
      expect(restored.fileName, track.fileName);
      expect(restored.extension, track.extension);
      expect(restored.title, track.title);
      expect(restored.artist, track.artist);
      expect(restored.album, track.album);
      expect(restored.artworkPath, track.artworkPath);
      expect(restored.duration, track.duration);
      expect(restored.dateAdded, track.dateAdded);
      expect(restored.isAvailable, track.isAvailable);
      expect(restored.copiedPath, track.copiedPath);
    });

    test('fromJson should handle missing optional fields', () {
      final json = {
        'id': 'minimal',
        'originalPath': '/min.mp3',
        'fileName': 'min.mp3',
        'extension': 'mp3',
        'title': 'Minimal',
        'artist': 'Artist',
        'duration': 0,
        'dateAdded': '2024-01-01T00:00:00.000Z',
        'isAvailable': true,
      };

      final track = LocalTrackModel.fromJson(json);
      expect(track.album, isNull);
      expect(track.artworkPath, isNull);
      expect(track.copiedPath, isNull);
    });

    test('equatable props should include all fields', () {
      final track1 = LocalTrackModel(
        id: 'eq-1',
        originalPath: '/a.mp3',
        fileName: 'a.mp3',
        extension: 'mp3',
        title: 'A',
        artist: 'Artist',
        duration: Duration.zero,
        dateAdded: DateTime.now(),
        isAvailable: true,
      );

      final track2 = LocalTrackModel(
        id: 'eq-1',
        originalPath: '/a.mp3',
        fileName: 'a.mp3',
        extension: 'mp3',
        title: 'A',
        artist: 'Artist',
        duration: Duration.zero,
        dateAdded: DateTime.now(),
        isAvailable: true,
      );

      final track3 = LocalTrackModel(
        id: 'eq-2',
        originalPath: '/b.mp3',
        fileName: 'b.mp3',
        extension: 'mp3',
        title: 'B',
        artist: 'Artist',
        duration: Duration.zero,
        dateAdded: DateTime.now(),
        isAvailable: true,
      );

      expect(track1 == track2, isTrue);
      expect(track1 == track3, isFalse);
      expect(track1.hashCode, track2.hashCode);
    });
  });
}