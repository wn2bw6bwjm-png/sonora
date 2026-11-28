import 'package:sonora/domain/entities/track.dart';
import 'package:sonora/data/models/track_model.dart';
import 'package:sonora/data/datasources/audius_datasource.dart';
import 'package:sonora/data/datasources/itunes_datasource.dart';
import 'package:sonora/data/datasources/internet_archive_datasource.dart';

abstract class TrackRepository {
  Future<List<Track>> getTrendingTracks();
  Future<List<Track>> searchTracks(String query);
  Future<List<Track>> searchTracksAcrossSources(String query);
  Future<Track?> getTrackById(String trackId);
  Future<List<Track>> getTracksByArtist(String artistId, String artistName);
  Future<List<Track>> getAlbumTracks(String albumId, String albumName);
  Future<List<Track>> getNewReleases();
  Future<void> toggleFavorite(Track track);
  Future<bool> isFavorite(String trackId);
  Future<List<Track>> getFavoriteTracks();
  Future<List<Track>> getRecentlyPlayed();
  Future<List<Track>> getPlaylists();
  Future<void> createPlaylist(String name, List<Track> tracks);
  Future<void> addTrackToPlaylist(String playlistId, Track track);
  Future<void> removeTrackFromPlaylist(String playlistId, String trackId);
  Future<void> deletePlaylist(String playlistId);
  Future<Map<String, dynamic>?> getPlaylist(String playlistId);
  Future<List<Map<String, dynamic>>> searchArtists(String query);
  Future<Map<String, dynamic>> getArtistDetails(String artistId);
  Future<List<Track>> getArtistTopTracks(String artistId);
  Future<List<Map<String, dynamic>>> searchAlbums(String query);
  Future<Map<String, dynamic>> getAlbumDetails(String albumId);
  Future<List<String>> getAvailableGenres();
  Future<List<String>> getAvailableSources();
}

class TrackRepositoryImpl implements TrackRepository {
  final AudiusDataSource _audiusDataSource;
  final ITunesDataSource _itunesDataSource;
  final InternetArchiveDataSource _internetArchiveDataSource;

  TrackRepositoryImpl({
    AudiusDataSource? audiusDataSource,
    ITunesDataSource? itunesDataSource,
    InternetArchiveDataSource? internetArchiveDataSource,
  })  : _audiusDataSource = audiusDataSource ?? AudiusDataSource(),
        _itunesDataSource = itunesDataSource ?? ITunesDataSource(),
        _internetArchiveDataSource =
            internetArchiveDataSource ?? InternetArchiveDataSource();

  @override
  Future<List<Track>> getTrendingTracks() async {
    try {
      final tracks = await _audiusDataSource.getTrendingTracks();
      return tracks.map((json) => TrackModel.fromJson(json).toEntity()).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<Track>> searchTracks(String query) async {
    try {
      final tracks = await _audiusDataSource.searchTracks(query: query);
      return tracks.map((json) => TrackModel.fromJson(json).toEntity()).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<Track>> searchTracksAcrossSources(String query) async {
    final allTracks = <Track>[];
    final seenIds = <String>{};

    // Search Audius
    try {
      final audiusTracks = await _audiusDataSource.searchTracks(query: query);
      for (final track in audiusTracks) {
        final model = TrackModel.fromJson(track);
        final entity = model.toEntity();
        if (seenIds.add(entity.id)) {
          allTracks.add(entity);
        }
      }
    } catch (e) {
      // Continue with other sources
    }

    // Search iTunes
    try {
      final itunesTracks = await _itunesDataSource.searchTracks(query);
      for (final track in itunesTracks) {
        final model = TrackModel.fromJson(track);
        final entity = model.toEntity();
        if (seenIds.add(entity.id)) {
          allTracks.add(entity);
        }
      }
    } catch (e) {
      // Continue
    }

    // Search Internet Archive
    try {
      final archiveTracks = await _internetArchiveDataSource.searchTracks(query);
      for (final track in archiveTracks) {
        final model = TrackModel.fromJson(track);
        final entity = model.toEntity();
        if (seenIds.add(entity.id)) {
          allTracks.add(entity);
        }
      }
    } catch (e) {
      // Continue
    }

    return allTracks;
  }

  @override
  Future<Track?> getTrackById(String trackId) async {
    try {
      final track = await _audiusDataSource.getTrackById(trackId);
      if (track == null) return null;
      return TrackModel.fromJson(track).toEntity();
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<Track>> getTracksByArtist(String artistId, String artistName) async {
    try {
      final tracks = await _audiusDataSource.searchTracks(query: artistName);
      return tracks.map((json) => TrackModel.fromJson(json).toEntity()).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<Track>> getAlbumTracks(String albumId, String albumName) async {
    return [];
  }

  @override
  Future<List<Track>> getNewReleases() async {
    try {
      final tracks = await _audiusDataSource.getTrendingTracks();
      return tracks.map((json) => TrackModel.fromJson(json).toEntity()).toList();
    } catch (e) {
      return [];
    }
  }

  // Placeholders for features not yet implemented
  Future<void> toggleFavorite(Track track) async {}
  Future<bool> isFavorite(String trackId) async => false;
  Future<List<Track>> getFavoriteTracks() async => [];
  Future<List<Track>> getRecentlyPlayed() async => [];
  Future<List<Track>> getPlaylists() async => [];
  Future<void> createPlaylist(String name, List<Track> tracks) async {}
  Future<void> addTrackToPlaylist(String playlistId, Track track) async {}
  Future<void> removeTrackFromPlaylist(String playlistId, String trackId) async {}
  Future<void> deletePlaylist(String playlistId) async {}
  Future<Map<String, dynamic>?> getPlaylist(String playlistId) async => null;
  Future<List<Map<String, dynamic>>> searchArtists(String query) async => [];
  Future<Map<String, dynamic>> getArtistDetails(String artistId) async => {};
  Future<List<Track>> getArtistTopTracks(String artistId) async => [];
  Future<List<Map<String, dynamic>>> searchAlbums(String query) async => [];
  Future<Map<String, dynamic>> getAlbumDetails(String albumId) async => {};
  Future<List<String>> getAvailableGenres() async => [];

  @override
  Future<List<String>> getAvailableSources() async {
    return ['audius', 'itunes', 'internet_archive'];
  }
}