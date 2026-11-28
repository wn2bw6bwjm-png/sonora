import 'package:test/test.dart';
import 'package:sonora/domain/entities/track.dart';
import 'package:sonora/data/models/track_model.dart';

void main() {
  group('Track Entity', () {
    test('should create Track with all fields', () {
      final track = Track(
        id: 'test-id',
        sourceId: 'source-123',
        title: 'Test Song',
        artist: 'Test Artist',
        album: 'Test Album',
        coverUrl: 'https://example.com/cover.jpg',
        duration: const Duration(minutes: 3, seconds: 30),
        streamUrl: 'https://example.com/stream.mp3',
        sourceName: 'audius',
        availabilityType: 'full',
        licenseInfo: {'genre': 'electronic'},
      );

      expect(track.id, 'test-id');
      expect(track.sourceId, 'source-123');
      expect(track.title, 'Test Song');
      expect(track.artist, 'Test Artist');
      expect(track.album, 'Test Album');
      expect(track.coverUrl, 'https://example.com/cover.jpg');
      expect(track.duration, const Duration(minutes: 3, seconds: 30));
      expect(track.streamUrl, 'https://example.com/stream.mp3');
      expect(track.sourceName, 'audius');
      expect(track.availabilityType, 'full');
      expect(track.licenseInfo?['genre'], 'electronic');
    });

    test('should create Track with minimal fields', () {
      final track = Track(
        id: 'minimal',
        sourceId: 'src',
        title: 'Minimal',
        artist: 'Artist',
        duration: Duration.zero,
        sourceName: 'local',
        availabilityType: 'full',
      );

      expect(track.id, 'minimal');
      expect(track.album, isNull);
      expect(track.coverUrl, isNull);
      expect(track.streamUrl, isNull);
      expect(track.licenseInfo, isNull);
    });

    test('toJson should serialize correctly', () {
      final track = Track(
        id: 'json-test',
        sourceId: 'src',
        title: 'JSON Track',
        artist: 'JSON Artist',
        duration: const Duration(seconds: 120),
        sourceName: 'itunes',
        availabilityType: 'preview',
      );

      final json = track.toJson();
      expect(json['id'], 'json-test');
      expect(json['source_id'], 'src');
      expect(json['title'], 'JSON Track');
      expect(json['artist'], 'JSON Artist');
      expect(json['duration'], 120);
      expect(json['source_name'], 'itunes');
      expect(json['availability_type'], 'preview');
    });

    test('fromJson should deserialize correctly', () {
      final json = {
        'id': 'from-json',
        'source_id': 'src-456',
        'title': 'From JSON',
        'artist': 'JSON Artist',
        'album': 'JSON Album',
        'cover_url': 'https://example.com/cover.jpg',
        'duration': 180,
        'stream_url': 'https://example.com/stream.mp3',
        'source_name': 'internet_archive',
        'availability_type': 'full',
        'license_info': {'license': 'CC-BY'},
      };

      final track = Track.fromJson(json);
      expect(track.id, 'from-json');
      expect(track.sourceId, 'src-456');
      expect(track.title, 'From JSON');
      expect(track.artist, 'JSON Artist');
      expect(track.album, 'JSON Album');
      expect(track.coverUrl, 'https://example.com/cover.jpg');
      expect(track.duration, const Duration(seconds: 180));
      expect(track.streamUrl, 'https://example.com/stream.mp3');
      expect(track.sourceName, 'internet_archive');
      expect(track.availabilityType, 'full');
      expect(track.licenseInfo?['license'], 'CC-BY');
    });

    test('fromJson should handle missing optional fields', () {
      final json = {
        'id': 'minimal-json',
        'source_id': 'src',
        'title': 'Minimal',
        'artist': 'Artist',
        'duration': 0,
        'source_name': 'local',
        'availability_type': 'full',
      };

      final track = Track.fromJson(json);
      expect(track.album, isNull);
      expect(track.coverUrl, isNull);
      expect(track.streamUrl, isNull);
      expect(track.licenseInfo, isNull);
    });
  });

  group('TrackModel', () {
    test('should convert to/from entity', () {
      final model = TrackModel(
        id: 'model-1',
        sourceId: 'src-1',
        title: 'Model Track',
        artist: 'Model Artist',
        album: 'Model Album',
        coverUrl: 'https://example.com/model.jpg',
        duration: const Duration(minutes: 4),
        streamUrl: 'https://example.com/model.mp3',
        sourceName: 'audius',
        availabilityType: 'full',
        licenseInfo: {'explicit': 'false'},
      );

      final entity = model.toEntity();
      expect(entity.id, model.id);
      expect(entity.title, model.title);
      expect(entity.artist, model.artist);

      final backToModel = TrackModel.fromEntity(entity);
      expect(backToModel.id, model.id);
      expect(backToModel.title, model.title);
      expect(backToModel.artist, model.artist);
    });

    test('toJson and fromJson should be symmetric', () {
      final model = TrackModel(
        id: 'symmetric',
        sourceId: 'src',
        title: 'Symmetric',
        artist: 'Artist',
        duration: const Duration(seconds: 240),
        sourceName: 'itunes',
        availabilityType: 'preview',
      );

      final json = model.toJson();
      final restored = TrackModel.fromJson(json);

      expect(restored.id, model.id);
      expect(restored.title, model.title);
      expect(restored.duration, model.duration);
    });
  });
}