import 'package:sonora/domain/entities/track.dart';
import 'package:sonora/data/models/local_track_model.dart';
import 'package:sonora/data/datasources/local_datasource.dart';
import 'package:sonora/data/hive/hive_service.dart';

abstract class LocalTrackRepository {
  Future<List<Track>> getLocalTracks();
  Future<void> addLocalTrack(LocalTrackModel track);
  Future<void> removeLocalTrack(String trackId);
  Future<void> importAudioFiles();
  Future<List<PlatformFile>> pickAudioFiles({bool allowMultiple = true});
  Future<void> refreshAvailability();
  Future<void> updateTrackMetadata(String trackId, {
    String? title,
    String? artist,
    String? album,
  });
}

class LocalTrackRepositoryImpl implements LocalTrackRepository {
  final LocalDataSource _dataSource;
  final HiveService _hiveService;

  LocalTrackRepositoryImpl({
    required LocalDataSource dataSource,
    required HiveService hiveService,
  })  : _dataSource = dataSource,
        _hiveService = hiveService;

  @override
  Future<List<Track>> getLocalTracks() async {
    final localTracks = await _hiveService.getLocalTracks();
    return localTracks
        .where((t) => t.isAvailable)
        .map((t) => _localToTrack(t))
        .toList();
  }

  @override
  Future<void> addLocalTrack(LocalTrackModel track) async {
    await _hiveService.addLocalTrack(track);
  }

  @override
  Future<void> removeLocalTrack(String trackId) async {
    await _hiveService.removeLocalTrack(trackId);
  }

  @override
  Future<void> importAudioFiles() async {
    final files = await _dataSource.pickAudioFiles(allowMultiple: true);
    for (final file in files) {
      final track = await _dataSource.createTrackFromFile(file);
      final copiedPath = await _dataSource.copyToAppStorage(file);
      if (copiedPath != null) {
        final updatedTrack = track.copyWith(copiedPath: copiedPath);
        await _hiveService.addLocalTrack(updatedTrack);
      } else {
        await _hiveService.addLocalTrack(track);
      }
    }
  }

  @override
  Future<List<PlatformFile>> pickAudioFiles({bool allowMultiple = true}) async {
    return await _dataSource.pickAudioFiles(allowMultiple: allowMultiple);
  }

  @override
  Future<void> refreshAvailability() async {
    final tracks = await _hiveService.getLocalTracks();
    for (final track in tracks) {
      final exists = await _dataSource._checkFileExists(track.playbackPath);
      if (track.isAvailable != exists) {
        await _hiveService.addLocalTrack(track.copyWith(isAvailable: exists));
      }
    }
  }

  @override
  Future<void> updateTrackMetadata(String trackId, {
    String? title,
    String? artist,
    String? album,
  }) async {
    final tracks = await _hiveService.getLocalTracks();
    final track = tracks.firstWhere((t) => t.id == trackId);
    final updated = track.copyWith(
      title: title ?? track.title,
      artist: artist ?? track.artist,
      album: album ?? track.album,
    );
    await _hiveService.addLocalTrack(updated);
  }

  Track _localToTrack(LocalTrackModel local) {
    return Track(
      id: local.id,
      sourceId: local.id,
      title: local.title,
      artist: local.artist,
      album: local.album,
      coverUrl: local.artworkPath,
      duration: local.duration,
      streamUrl: local.playbackPath,
      sourceName: 'Local',
      availabilityType: local.isAvailable ? 'full' : 'unavailable',
      licenseInfo: {'local': true, 'format': local.extension},
    );
  }
}