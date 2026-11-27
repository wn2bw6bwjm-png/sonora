import '../hive/hive_service.dart';
import '../models/track_model.dart';
import '../datasources/remote_datasource.dart';

abstract class TrackRepository {
  Future<List<dynamic>> getTrendingTracks();
  Future<List<dynamic>> searchTracks(String query);
  Future<dynamic> getTrackById(String trackId);
  Future<List<dynamic>> getTracksByArtist(String artistId, String artistName);
  Future<List<dynamic>> getAlbumTracks(String albumId, String albumName);
  Future<List<dynamic>> getNewReleases();
  Future<dynamic> getTrackById2(String trackId);
  Future<void> toggleFavorite(dynamic track);
  Future<bool> isFavorite(String trackId);
  Future<List<dynamic>> getFavoriteTracks();
  Future<List<dynamic>> getRecentlyPlayed();
  Future<List<dynamic>> getPlaylists();
  Future<void> createPlaylist(String name, List<dynamic> tracks);
  Future<void> addTrackToPlaylist(String playlistId, dynamic track);
  Future<void> removeTrackFromPlaylist(String playlistId, String trackId);
  Future<void> deletePlaylist(String playlistId);
  Future<Map<String, dynamic>?> getPlaylist(String playlistId);
  Future<List<Map<String, dynamic>>> searchArtists(String query);
  Future<Map<String, dynamic>> getArtistDetails(String artistId);
  Future<List<dynamic>> getArtistTopTracks(String artistId);
  Future<List<dynamic>> searchAlbums(String query);
  Future<Map<String, dynamic>> getAlbumDetails(String albumId);
  Future<List<String>> getAvailableGenres();
  Future<List<String>> getAvailableSources();
}

class TrackRepositoryImpl implements TrackRepository {
  final RemoteDataSource _remoteDataSource;
  final HiveService _hiveService;

  TrackRepositoryImpl(
      {RemoteDataSource? remoteDataSource,
      HiveService? hiveService})
      : _remoteDataSource = remoteDataSource ?? _initDataSources(),
        _hiveService = hiveService ?? HiveService._instance;

  /// Lazy init - ensure Hive is initialized
  Future<void> _ensureInit() async {
    if (!_hiveService.isInitialized) {
      await _hiveService.init();
    }
  }

  RemoteDataSource _initDataSources() {
    return _AudiusDataSource();
  }

  @override
  Future<List<dynamic>> getTrendingTracks() async {
    try {
      await _ensureInit();
      final tracks = await _remoteDataSource.getTrendingTracks();
      return _consolidateAndDeduplicate(tracks);
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<dynamic>> searchTracks(String query, {String? source}) async {
    try {
      final tracks = await _remoteDataSource.searchTracks(query);
      return _consolidateAndDeduplicate(tracks);
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<dynamic>> getTracksByArtist(String artistId, String artistName) async {
    try {
      final allTracks = <dynamic>[];
      final sources = ['audius', 'itunes', 'jamendo', 'internet-archive'];

      for (final src in sources) {
        try {
          final RemoteDataSource sourceSource = _getSource(src);
          final tracks = await sourceSource.searchTracks(artistName);
          allTracks.addAll(tracks);
        } catch (_) {
          continue;
        }
      }
      return _deduplicateTracks(allTracks);
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<dynamic>> getAlbumTracks(String albumId, String albumName) async {
    try {
      return [];
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<dynamic>> getNewReleases() async {
    try {
      final tracks = await _remoteDataSource.getTrendingTracks();
      return _consolidateAndDeduplicate(tracks);
    } catch (e) {
      return [];
    }
  }

  @override
  Future<dynamic> getTrackById(String trackId) async {
    try {
      final sources = ['audius', 'itunes', 'jamendo', 'internet-archive'];

      for (final source in sources) {
        try {
          final RemoteDataSource sourceSource = _getSource(source);
          final track = await sourceSource.getTrackById(trackId);
          if (track != null) return track;
        } catch (_) {
          continue;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> toggleFavorite(dynamic track) async {
    final trackModel = TrackModel.fromJson(track as Map<String, dynamic>);
    await _hiveService.addFavorite(trackModel);
  }

  @override
  Future<bool> isFavorite(String trackId) async {
    await _ensureInit();
    return _hiveService.isFavorite(trackId);
  }

  @override
  Future<List<dynamic>> getFavoriteTracks() async {
    await _ensureInit();
    return _hiveService.getFavoriteTracks();
  }

  @override
  Future<List<dynamic>> getRecentlyPlayed() async {
    await _ensureInit();
    return _hiveService.getRecentlyPlayed();
  }

  @override
  Future<List<dynamic>> getPlaylists() async {
    await _ensureInit();
    return _hiveService.getPlaylists();
  }

  @override
  Future<void> createPlaylist(String name, List<dynamic> tracks) async {
    await _ensureInit();
    await _hiveService.createPlaylist(name, tracks.cast<TrackModel>());
  }

  @override
  Future<void> addTrackToPlaylist(String playlistId, dynamic track) async {
    await _ensureInit();
    await _hiveService.addTrackToPlaylist(playlistId, track);
  }

  @override
  Future<void> removeTrackFromPlaylist(String playlistId, String trackId) async {
    await _ensureInit();
    await _hiveService.removeTrackFromPlaylist(playlistId, trackId);
  }

  @override
  Future<void> deletePlaylist(String playlistId) async {
    await _ensureInit();
    // TODO: Implement delete
  }

  @override
  Future<Map<String, dynamic>?> getPlaylist(String playlistId) async {
    await _ensureInit();
    return _hiveService.getPlaylist(playlistId);
  }

  @override
  Future<List<Map<String, dynamic>>> searchArtists(String query) async {
    return [];
  }

  @override
  Future<Map<String, dynamic>> getArtistDetails(String artistId) async {
    return {};
  }

  @override
  Future<List<dynamic>> getArtistTopTracks(String artistId) async {
    return [];
  }

  @override
  Future<List<dynamic>> searchAlbums(String query) async {
    return [];
  }

  @override
  Future<Map<String, dynamic>> getAlbumDetails(String albumId) async {
    return {};
  }

  @override
  Future<List<String>> getAvailableGenres() async {
    return [];
  }

  @override
  Future<List<String>> getAvailableSources() async {
    return ['audius', 'itunes', 'jamendo', 'internet-archive'];
  }

  RemoteDataSource _getSource(String sourceName) {
    switch (sourceName) {
      case 'audius':
        return _AudiusDataSource();
      case 'itunes':
        return _ITunesDataSource();
      case 'jamendo':
        return _JamendoDataSource();
      case 'internet-archive':
        return _InternetArchiveDataSource();
      default:
        return _AudiusDataSource();
    }
  }

  List<dynamic> _consolidateAndDeduplicate(List<dynamic> tracks) {
    final seen = <String>{};
    final result = <dynamic>[];

    for (final track in tracks) {
      if (track is Map<String, dynamic>) {
        final key = '${track['id']}|${track['title']}|${track['artist']}';
        if (!seen.contains(key)) {
          seen.add(key);
          result.add(track);
        }
      }
    }

    return result;
  }

  List<dynamic> _deduplicateTracks(List<dynamic> tracks) {
    final seen = <String>{};
    final result = <dynamic>[];

    for (final track in tracks) {
      final key = '${track['id']}|${track['title']}|${track['artist']}';
      if (!seen.contains(key)) {
        seen.add(key);
        result.add(track);
      }
    }

    return result;
  }
}

class _AudiusDataSource implements RemoteDataSource {
  @override
  Future<List<dynamic>> getTrendingTracks() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return [];
  }

  @override
  Future<List<dynamic>> searchTracks(String query) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return [];
  }

  @override
  Future<dynamic> getTrackById(String trackId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return null;
  }
}

class _ITunesDataSource implements RemoteDataSource {
  @override
  Future<List<dynamic>> getTrendingTracks() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return [];
  }

  @override
  Future<List<dynamic>> searchTracks(String query) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return [];
  }

  @override
  Future<dynamic> getTrackById(String trackId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return null;
  }
}

class _JamendoDataSource implements RemoteDataSource {
  @override
  Future<List<dynamic>> getTrendingTracks() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return [];
  }

  @override
  Future<List<dynamic>> searchTracks(String query) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return [];
  }

  @override
  Future<dynamic> getTrackById(String trackId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return null;
  }
}

class _InternetArchiveDataSource implements RemoteDataSource {
  @override
Future<List<dynamic>> getTrendingTracks() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return [];
  }

  @override
  Future<List<dynamic>> searchTracks(String query) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return [];
  }

  @override
  Future<dynamic> getTrackById(String trackId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return null;
  }
}