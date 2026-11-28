import 'package:sonora/domain/entities/track.dart';
import 'package:sonora/data/hive/hive_service.dart';
import 'package:sonora/data/repositories/local_track_repository.dart';
import 'package:sonora/data/datasources/local_datasource.dart';
import 'package:sonora/data/repositories/track_repository_impl.dart';

/// Local recommendation engine based on user's listening habits
class RecommendationEngine {
  final HiveService _hiveService = HiveService();
  final TrackRepository _onlineRepository = TrackRepositoryImpl();
  final LocalTrackRepository _localRepository = LocalTrackRepositoryImpl(
    dataSource: LocalDataSource(),
    hiveService: HiveService(),
  );

  /// Get recommended tracks based on user preferences
  Future<List<Track>> getRecommendations({int limit = 20}) async {
    final recommendations = <Track>[];
    final seenIds = <String>{};

    // 1. Get user's favorite genres from favorites
    final favoriteGenres = _getFavoriteGenres();

    // 2. Get favorite artists from favorites
    final favoriteArtists = _getFavoriteArtists();

    // 3. Get recently played artists
    final recentArtists = _getRecentArtists();

    // 4. Combine and weight artists
    final artistWeights = <String, int>{};
    for (final artist in favoriteArtists) {
      artistWeights[artist] = (artistWeights[artist] ?? 0) + 3;
    }
    for (final artist in recentArtists) {
      artistWeights[artist] = (artistWeights[artist] ?? 0) + 2;
    }

    // 5. Get recommendations from online sources
    try {
      // Search by favorite genres
      for (final genre in favoriteGenres.take(3)) {
        final tracks = await _onlineRepository.searchTracks(genre);
        for (final track in tracks) {
          if (seenIds.add(track.id)) {
            recommendations.add(track);
            if (recommendations.length >= limit) break;
          }
        }
        if (recommendations.length >= limit) break;
      }
    } catch (e) {
      // Continue with other sources
    }

    // 6. Search by top artists
    final topArtists = artistWeights.entries
        .toList()
        ..sort((a, b) => b.value.compareTo(a.value));

    for (final entry in topArtists.take(5)) {
      if (recommendations.length >= limit) break;
      try {
        final tracks = await _onlineRepository.searchTracks(entry.key);
        for (final track in tracks) {
          if (seenIds.add(track.id)) {
            recommendations.add(track);
            if (recommendations.length >= limit) break;
          }
        }
      } catch (e) {
        // Continue
      }
    }

    // 7. Add local tracks from similar genres/artists
    try {
      final localTracks = await _localRepository.getLocalTracks();
      for (final track in localTracks) {
        if (seenIds.add(track.id)) {
          // Check if matches favorite genres or artists
          final matchesGenre = favoriteGenres.any((g) =>
            track.album?.toLowerCase().contains(g.toLowerCase()) ?? false);
          final matchesArtist = favoriteArtists.contains(track.artist);

          if (matchesGenre || matchesArtist || recommendations.length < limit ~/ 2) {
            recommendations.add(track);
            if (recommendations.length >= limit) break;
          }
        }
      }
    } catch (e) {
      // Continue
    }

    // 8. If still not enough, get trending
    if (recommendations.length < limit) {
      try {
        final trending = await _onlineRepository.getTrendingTracks();
        for (final track in trending) {
          if (seenIds.add(track.id)) {
            recommendations.add(track);
            if (recommendations.length >= limit) break;
          }
        }
      } catch (e) {
        // Ignore
      }
    }

    return recommendations.take(limit).toList();
  }

  /// Get recommended tracks for "Discover" section
  Future<List<Track>> getDiscoverRecommendations({int limit = 20}) async {
    // For new users or discovery, mix trending + genre variety
    final recommendations = <Track>[];
    final seenIds = <String>{};

    try {
      final trending = await _onlineRepository.getTrendingTracks();
      for (final track in trending) {
        if (seenIds.add(track.id)) {
          recommendations.add(track);
        }
      }
    } catch (e) {}

    // Add variety from popular genres
    const popularGenres = ['pop', 'rock', 'hip hop', 'electronic', 'indie', 'jazz'];
    for (final genre in popularGenres) {
      if (recommendations.length >= limit) break;
      try {
        final tracks = await _onlineRepository.searchTracks(genre);
        for (final track in tracks.take(3)) {
          if (seenIds.add(track.id)) {
            recommendations.add(track);
          }
        }
      } catch (e) {}
    }

    return recommendations.take(limit).toList();
  }

  List<String> _getFavoriteGenres() {
    final favorites = _hiveService.getFavoriteTracks();
    final genres = <String, int>{};

    for (final track in favorites) {
      // Extract genre from license info or album
      final licenseInfo = track.licenseInfo;
      if (licenseInfo != null && licenseInfo['genre'] != null) {
        final genre = licenseInfo['genre'] as String;
        genres[genre] = (genres[genre] ?? 0) + 1;
      }
      // Also check album for genre hints
      if (track.album != null) {
        final albumWords = track.album!.toLowerCase().split(' ');
        for (final word in albumWords) {
          if (word.length > 3) {
            genres[word] = (genres[word] ?? 0) + 1;
          }
        }
      }
    }

    final sorted = genres.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(10).map((e) => e.key).toList();
  }

  List<String> _getFavoriteArtists() {
    final favorites = _hiveService.getFavoriteTracks();
    final artists = <String, int>{};

    for (final track in favorites) {
      artists[track.artist] = (artists[track.artist] ?? 0) + 1;
    }

    final sorted = artists.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(20).map((e) => e.key).toList();
  }

  List<String> _getRecentArtists() {
    final recent = _hiveService.getRecentlyPlayed();
    final artists = <String, int>{};

    for (final track in recent.take(50)) {
      artists[track.artist] = (artists[track.artist] ?? 0) + 1;
    }

    final sorted = artists.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(20).map((e) => e.key).toList();
  }

  /// Get "Because you listened to X" recommendations
  Future<List<Track>> getArtistBasedRecommendations(String artist, {int limit = 10}) async {
    try {
      final tracks = await _onlineRepository.searchTracks(artist);
      return tracks.take(limit).toList();
    } catch (e) {
      return [];
    }
  }
}