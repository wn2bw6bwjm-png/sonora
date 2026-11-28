import 'package:test/test.dart';
import 'package:sonora/data/hive/hive_service.dart';
import 'package:sonora/data/models/track_model.dart';
import 'package:sonora/data/models/local_track_model.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  setUpAll(() async {
    await Hive.initFlutter();
    Hive.registerAdapter(TrackModelAdapter());
    Hive.registerAdapter(LocalTrackModelAdapter());
  });

  tearDownAll(() async {
    await Hive.close();
  });

  group('HiveService', () {
    late HiveService hiveService;

    setUp(() async {
      hiveService = HiveService();
      await hiveService.init();
      // Clear all boxes
      await hiveService._favoriteBox.clear();
      await hiveService._playlistsBox.clear();
      await hiveService._recentlyPlayedBox.clear();
      await hiveService._searchHistoryBox.clear();
      await hiveService._localTracksBox.clear();
    });

    tearDown(() async {
      await hiveService.close();
    });

    group('Favorites', () {
      test('should add and retrieve favorite track', () async {
        final track = TrackModel(
          id: 'fav-1',
          sourceId: 'src',
          title: 'Favorite Song',
          artist: 'Favorite Artist',
          duration: const Duration(minutes: 3),
          sourceName: 'audius',
          availabilityType: 'full',
        );

        await hiveService.addFavorite(track);
        final favorites = hiveService.getFavoriteTracks();

        expect(favorites.length, 1);
        expect(favorites.first.id, 'fav-1');
        expect(favorites.first.title, 'Favorite Song');
      });

      test('should not add duplicate favorites', () async {
        final track = TrackModel(
          id: 'fav-dup',
          sourceId: 'src',
          title: 'Duplicate Song',
          artist: 'Artist',
          duration: Duration.zero,
          sourceName: 'audius',
          availabilityType: 'full',
        );

        await hiveService.addFavorite(track);
        await hiveService.addFavorite(track);
        final favorites = hiveService.getFavoriteTracks();

        expect(favorites.length, 1);
      });

      test('should remove favorite track', () async {
        final track = TrackModel(
          id: 'fav-remove',
          sourceId: 'src',
          title: 'To Remove',
          artist: 'Artist',
          duration: Duration.zero,
          sourceName: 'audius',
          availabilityType: 'full',
        );

        await hiveService.addFavorite(track);
        await hiveService.removeFavorite('fav-remove');
        final favorites = hiveService.getFavoriteTracks();

        expect(favorites.length, 0);
      });

      test('should check if track is favorite', () async {
        final track = TrackModel(
          id: 'fav-check',
          sourceId: 'src',
          title: 'Check Favorite',
          artist: 'Artist',
          duration: Duration.zero,
          sourceName: 'audius',
          availabilityType: 'full',
        );

        expect(hiveService.isFavorite('fav-check'), false);

        await hiveService.addFavorite(track);
        expect(hiveService.isFavorite('fav-check'), true);

        await hiveService.removeFavorite('fav-check');
        expect(hiveService.isFavorite('fav-check'), false);
      });

      test('should toggle favorite', () async {
        final track = TrackModel(
          id: 'fav-toggle',
          sourceId: 'src',
          title: 'Toggle Favorite',
          artist: 'Artist',
          duration: Duration.zero,
          sourceName: 'audius',
          availabilityType: 'full',
        );

        await hiveService.toggleFavorite(track);
        expect(hiveService.isFavorite('fav-toggle'), true);

        await hiveService.toggleFavorite(track);
        expect(hiveService.isFavorite('fav-toggle'), false);
      });
    });

    group('Playlists', () {
      test('should create playlist with tracks', () async {
        final tracks = [
          TrackModel(
            id: 'pl-track-1',
            sourceId: 'src',
            title: 'Track 1',
            artist: 'Artist 1',
            duration: Duration.zero,
            sourceName: 'audius',
            availabilityType: 'full',
          ),
          TrackModel(
            id: 'pl-track-2',
            sourceId: 'src',
            title: 'Track 2',
            artist: 'Artist 2',
            duration: Duration.zero,
            sourceName: 'itunes',
            availabilityType: 'preview',
          ),
        ];

        await hiveService.createPlaylist('Test Playlist', tracks);
        final playlists = hiveService.playlists;

        expect(playlists.length, 1);
        expect(playlists.first['name'], 'Test Playlist');
        expect((playlists.first['tracks'] as List).length, 2);
      });

      test('should add track to playlist', () async {
        await hiveService.createPlaylist('Add Track Playlist', []);
        final playlists = hiveService.playlists;
        final playlistId = playlists.first['id'] as String;

        final track = TrackModel(
          id: 'add-to-pl',
          sourceId: 'src',
          title: 'Added Track',
          artist: 'Artist',
          duration: Duration.zero,
          sourceName: 'local',
          availabilityType: 'full',
        );

        await hiveService.addTrackToPlaylist(playlistId, track);
        final updatedPlaylists = hiveService.playlists;
        final updatedPlaylist = updatedPlaylists.firstWhere((p) => p['id'] == playlistId);

        expect((updatedPlaylist['tracks'] as List).length, 1);
      });

      test('should remove track from playlist', () async {
        final track = TrackModel(
          id: 'remove-from-pl',
          sourceId: 'src',
          title: 'Remove Me',
          artist: 'Artist',
          duration: Duration.zero,
          sourceName: 'audius',
          availabilityType: 'full',
        );

        await hiveService.createPlaylist('Remove Track Playlist', [track]);
        final playlists = hiveService.playlists;
        final playlistId = playlists.first['id'] as String;

        await hiveService.removeTrackFromPlaylist(playlistId, 'remove-from-pl');
        final updatedPlaylist = hiveService.getPlaylist(playlistId);

        expect((updatedPlaylist?['tracks'] as List?)?.isEmpty ?? true, true);
      });

      test('should update playlist name', () async {
        await hiveService.createPlaylist('Old Name', []);
        final playlists = hiveService.playlists;
        final playlistId = playlists.first['id'] as String;

        await hiveService.updatePlaylist(playlistId, 'New Name');
        final updated = hiveService.getPlaylist(playlistId);

        expect(updated?['name'], 'New Name');
      });

      test('should delete playlist', () async {
        await hiveService.createPlaylist('To Delete', []);
        final playlists = hiveService.playlists;
        final playlistId = playlists.first['id'] as String;

        await hiveService.deletePlaylist(playlistId);
        final afterDelete = hiveService.playlists;

        expect(afterDelete.length, 0);
      });

      test('should reorder playlist tracks', () async {
        final tracks = [
          TrackModel(id: 't1', sourceId: 's', title: '1', artist: 'A', duration: Duration.zero, sourceName: 'x', availabilityType: 'f'),
          TrackModel(id: 't2', sourceId: 's', title: '2', artist: 'A', duration: Duration.zero, sourceName: 'x', availabilityType: 'f'),
          TrackModel(id: 't3', sourceId: 's', title: '3', artist: 'A', duration: Duration.zero, sourceName: 'x', availabilityType: 'f'),
        ];

        await hiveService.createPlaylist('Reorder Playlist', tracks);
        final playlists = hiveService.playlists;
        final playlistId = playlists.first['id'] as String;

        // Move first to last (oldIndex=0, newIndex=3 -> adjusted to 2)
        await hiveService.reorderPlaylistTracks(playlistId, 0, 2);
        final updated = hiveService.getPlaylist(playlistId);
        final updatedTracks = updated?['tracks'] as List;

        expect(updatedTracks[0]['id'], 't2');
        expect(updatedTracks[1]['id'], 't3');
        expect(updatedTracks[2]['id'], 't1');
      });
    });

    group('Recently Played', () {
      test('should add recently played track', () async {
        final track = TrackModel(
          id: 'recent-1',
          sourceId: 'src',
          title: 'Recent Track',
          artist: 'Recent Artist',
          duration: Duration.zero,
          sourceName: 'audius',
          availabilityType: 'full',
        );

        await hiveService.addRecentlyPlayed(track);
        final recent = hiveService.getRecentlyPlayed();

        expect(recent.length, 1);
        expect(recent.first.id, 'recent-1');
      });

      test('should not duplicate recently played', () async {
        final track = TrackModel(
          id: 'recent-dup',
          sourceId: 'src',
          title: 'Duplicate Recent',
          artist: 'Artist',
          duration: Duration.zero,
          sourceName: 'audius',
          availabilityType: 'full',
        );

        await hiveService.addRecentlyPlayed(track);
        await hiveService.addRecentlyPlayed(track);
        final recent = hiveService.getRecentlyPlayed();

        expect(recent.length, 1);
      });

      test('should maintain order (newest first)', () async {
        final track1 = TrackModel(id: 'r1', sourceId: 's', title: '1', artist: 'A', duration: Duration.zero, sourceName: 'x', availabilityType: 'f');
        final track2 = TrackModel(id: 'r2', sourceId: 's', title: '2', artist: 'A', duration: Duration.zero, sourceName: 'x', availabilityType: 'f');
        final track3 = TrackModel(id: 'r3', sourceId: 's', title: '3', artist: 'A', duration: Duration.zero, sourceName: 'x', availabilityType: 'f');

        await hiveService.addRecentlyPlayed(track1);
        await hiveService.addRecentlyPlayed(track2);
        await hiveService.addRecentlyPlayed(track3);

        final recent = hiveService.getRecentlyPlayed();
        expect(recent[0].id, 'r3'); // newest first
        expect(recent[1].id, 'r2');
        expect(recent[2].id, 'r1');
      });

      test('should limit to 100 entries', () async {
        for (int i = 0; i < 105; i++) {
          final track = TrackModel(
            id: 'recent-$i',
            sourceId: 'src',
            title: 'Track $i',
            artist: 'Artist',
            duration: Duration.zero,
            sourceName: 'audius',
            availabilityType: 'full',
          );
          await hiveService.addRecentlyPlayed(track);
        }

        final recent = hiveService.getRecentlyPlayed();
        expect(recent.length, 100);
      });

      test('should clear recently played', () async {
        final track = TrackModel(id: 'clear', sourceId: 's', title: 'Clear', artist: 'A', duration: Duration.zero, sourceName: 'x', availabilityType: 'f');
        await hiveService.addRecentlyPlayed(track);
        await hiveService.clearRecentlyPlayed();

        final recent = hiveService.getRecentlyPlayed();
        expect(recent.length, 0);
      });
    });

    group('Search History', () {
      test('should add search query', () async {
        await hiveService.addSearchQuery('test query');
        final history = hiveService.getSearchHistory();

        expect(history.length, 1);
        expect(history.first, 'test query');
      });

      test('should not add duplicate queries', () async {
        await hiveService.addSearchQuery('duplicate');
        await hiveService.addSearchQuery('duplicate');
        final history = hiveService.getSearchHistory();

        expect(history.length, 1);
      });

      test('should limit to 50 entries', () async {
        for (int i = 0; i < 55; i++) {
          await hiveService.addSearchQuery('query $i');
        }

        final history = hiveService.getSearchHistory();
        expect(history.length, 50);
      });

      test('should clear search history', () async {
        await hiveService.addSearchQuery('to clear');
        await hiveService.clearSearchHistory();

        final history = hiveService.getSearchHistory();
        expect(history.length, 0);
      });
    });

    group('Local Tracks', () {
      test('should add local track', () async {
        final track = LocalTrackModel(
          id: 'local-test',
          originalPath: '/music/song.mp3',
          fileName: 'song.mp3',
          extension: 'mp3',
          title: 'Local Song',
          artist: 'Local Artist',
          duration: const Duration(minutes: 3),
          dateAdded: DateTime.now(),
          isAvailable: true,
        );

        await hiveService.addLocalTrack(track);
        final tracks = hiveService.getLocalTracks();

        expect(tracks.length, 1);
        expect(tracks.first.id, 'local-test');
      });

      test('should remove local track', () async {
        final track = LocalTrackModel(
          id: 'local-remove',
          originalPath: '/remove.mp3',
          fileName: 'remove.mp3',
          extension: 'mp3',
          title: 'Remove Me',
          artist: 'Artist',
          duration: Duration.zero,
          dateAdded: DateTime.now(),
          isAvailable: true,
        );

        await hiveService.addLocalTrack(track);
        await hiveService.removeLocalTrack('local-remove');
        final tracks = hiveService.getLocalTracks();

        expect(tracks.length, 0);
      });
    });
  });
}

// Adapters need to be defined for TrackModel and LocalTrackModel
// These would be generated by build_runner in real project
class TrackModelAdapter extends TypeAdapter<TrackModel> {
  @override
  final int typeId = 0;

  @override
  TrackModel read(BinaryReader reader) {
    return TrackModel(
      id: reader.readString(),
      sourceId: reader.readString(),
      title: reader.readString(),
      artist: reader.readString(),
      album: reader.readString(),
      coverUrl: reader.readString(),
      duration: Duration(milliseconds: reader.readInt()),
      streamUrl: reader.readString(),
      sourceName: reader.readString(),
      availabilityType: reader.readString(),
      licenseInfo: reader.readMap(),
    );
  }

  @override
  void write(BinaryWriter writer, TrackModel obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.sourceId);
    writer.writeString(obj.title);
    writer.writeString(obj.artist);
    writer.writeString(obj.album ?? '');
    writer.writeString(obj.coverUrl ?? '');
    writer.writeInt(obj.duration.inMilliseconds);
    writer.writeString(obj.streamUrl ?? '');
    writer.writeString(obj.sourceName);
    writer.writeString(obj.availabilityType);
    writer.writeMap(obj.licenseInfo ?? {});
  }
}

class LocalTrackModelAdapter extends TypeAdapter<LocalTrackModel> {
  @override
  final int typeId = 1;

  @override
  LocalTrackModel read(BinaryReader reader) {
    return LocalTrackModel(
      id: reader.readString(),
      originalPath: reader.readString(),
      fileName: reader.readString(),
      extension: reader.readString(),
      title: reader.readString(),
      artist: reader.readString(),
      album: reader.readString(),
      artworkPath: reader.readString(),
      duration: Duration(milliseconds: reader.readInt()),
      dateAdded: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      isAvailable: reader.readBool(),
      copiedPath: reader.readString(),
    );
  }

  @override
  void write(BinaryWriter writer, LocalTrackModel obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.originalPath);
    writer.writeString(obj.fileName);
    writer.writeString(obj.extension);
    writer.writeString(obj.title);
    writer.writeString(obj.artist);
    writer.writeString(obj.album ?? '');
    writer.writeString(obj.artworkPath ?? '');
    writer.writeInt(obj.duration.inMilliseconds);
    writer.writeInt(obj.dateAdded.millisecondsSinceEpoch);
    writer.writeBool(obj.isAvailable);
    writer.writeString(obj.copiedPath ?? '');
  }
}