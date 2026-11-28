import 'package:hive_flutter/hive_flutter.dart';
import 'package:hive/hive.dart';
import 'package:sonora/data/models/track_model.dart';
import 'package:sonora/data/models/local_track_model.dart';
import 'box_keys.dart';

/// Hive service for local storage of favorites, playlists, history, and settings
class HiveService {
  late final Box<TrackModel> _favoriteBox;
  late final Box<List<dynamic>> _playlistsBox;
  late final Box<List<dynamic>> _recentlyPlayedBox;
  late final Box<String> _searchHistoryBox;
  late final Box<String> _playerStateBox;
  late final Box<String> _cacheSettingsBox;
  late final Box<LocalTrackModel> _localTracksBox;

  HiveService._internal();
  static final HiveService _instance = HiveService._internal();
  factory HiveService() => _instance;

  /// Initialize Hive boxes
  Future<void> init() async {
    _favoriteBox = await Hive.openBox<TrackModel>(BoxKeys.favoriteTracks);
    _playlistsBox = await Hive.openBox<List<dynamic>>(BoxKeys.playlists);
    _recentlyPlayedBox = await Hive.openBox<List<dynamic>>(BoxKeys.recentlyPlayed);
    _searchHistoryBox = await Hive.openBox<String>(BoxKeys.searchHistory);
    _playerStateBox = await Hive.openBox<String>(BoxKeys.playerState);
    _cacheSettingsBox = await Hive.openBox<String>(BoxKeys.cacheSettings);
    _localTracksBox = await Hive.openBox<LocalTrackModel>(BoxKeys.localTracks);
  }

  /// --- Favorite Tracks (unified for online + local) ---

  Future<void> addFavorite(TrackModel track) async {
    final tracks = _favoriteBox.values.toList();
    if (!tracks.any((t) => t.id == track.id)) {
      await _favoriteBox.add(track);
    }
  }

  Future<void> removeFavorite(String trackId) async {
    final tracks = _favoriteBox.values.toList();
    final index = tracks.indexWhere((t) => t.id == trackId);
    if (index >= 0) {
      await _favoriteBox.deleteAt(index);
    }
  }

  bool isFavorite(String trackId) {
    return _favoriteBox.values.any((t) => t.id == trackId);
  }

  List<TrackModel> getFavoriteTracks() {
    return _favoriteBox.values
        .whereType<TrackModel>()
        .toList();
  }

  Future<void> toggleFavorite(TrackModel track) async {
    if (isFavorite(track.id)) {
      await removeFavorite(track.id);
    } else {
      await addFavorite(track);
    }
  }

  /// --- Playlists (mixed sources support) ---

  Future<void> createPlaylist(String name, List<TrackModel> tracks) async {
    final playlist = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'name': name,
      'tracks': tracks.map((t) => t.toJson()).toList(),
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
    await _playlistsBox.add(playlist);
  }

  List<Map<String, dynamic>> get playlists =>
      _playlistsBox.values
          .whereType<Map<String, dynamic>>()
          .toList();

  Map<String, dynamic>? getPlaylist(String playlistId) {
    final playlists = get playlists;
    try {
      return playlists.firstWhere((p) => p['id'] == playlistId);
    } catch (e) {
      return null;
    }
  }

  Future<void> addTrackToPlaylist(String playlistId, TrackModel track) async {
    final playlists = get playlists;
    for (var i = 0; i < playlists.length; i++) {
      if (playlists[i]['id'] == playlistId) {
        final List<dynamic> tracks = playlists[i]['tracks'] ?? [];
        tracks.add(track.toJson());
        playlists[i]['tracks'] = tracks;
        playlists[i]['updatedAt'] = DateTime.now().toIso8601String();
        await _playlistsBox.putAt(i, playlists[i]);
        return;
      }
    }
    // Playlist not found
    await createPlaylist(playlistId, [track]);
  }

  Future<void> removeTrackFromPlaylist(String playlistId, String trackId) async {
    final playlists = get playlists;
    for (var i = 0; i < playlists.length; i++) {
      if (playlists[i]['id'] == playlistId) {
        final List<dynamic> tracks = playlists[i]['tracks'] ?? [];
        tracks.removeWhere((t) => t['id'] == trackId);
        playlists[i]['tracks'] = tracks;
        playlists[i]['updatedAt'] = DateTime.now().toIso8601String();
        await _playlistsBox.putAt(i, playlists[i]);
        return;
      }
    }
  }

  Future<void> updatePlaylist(String playlistId, String newName) async {
    final playlists = get playlists;
    for (var i = 0; i < playlists.length; i++) {
      if (playlists[i]['id'] == playlistId) {
        playlists[i]['name'] = newName;
        playlists[i]['updatedAt'] = DateTime.now().toIso8601String();
        await _playlistsBox.putAt(i, playlists[i]);
        return;
      }
    }
  }

  Future<void> deletePlaylist(String playlistId) async {
    final playlists = get playlists;
    for (var i = 0; i < playlists.length; i++) {
      if (playlists[i]['id'] == playlistId) {
        await _playlistsBox.deleteAt(i);
        return;
      }
    }
  }

  Future<void> reorderPlaylistTracks(String playlistId, int oldIndex, int newIndex) async {
    final playlists = get playlists;
    for (var i = 0; i < playlists.length; i++) {
      if (playlists[i]['id'] == playlistId) {
        final List<dynamic> tracks = playlists[i]['tracks'] ?? [];
        if (oldIndex >= 0 && oldIndex < tracks.length && newIndex >= 0 && newIndex < tracks.length) {
          final item = tracks.removeAt(oldIndex);
          tracks.insert(newIndex, item);
          playlists[i]['tracks'] = tracks;
          playlists[i]['updatedAt'] = DateTime.now().toIso8601String();
          await _playlistsBox.putAt(i, playlists[i]);
        }
        return;
      }
    }
  }

  /// --- Recently Played (unified) ---

  Future<void> addRecentlyPlayed(TrackModel track) async {
    List<dynamic> tracks = _recentlyPlayedBox.values.toList();
    tracks.removeWhere((t) => t['id'] == track.id);
    tracks.insert(0, track.toJson());
    if (tracks.length > 100) {
      tracks = tracks.sublist(0, 100);
    }
    await _recentlyPlayedBox.put('tracks', tracks);
  }

  List<TrackModel> getRecentlyPlayed() {
    final tracks = _recentlyPlayedBox.get('tracks', defaultValue: []) as List<dynamic>;
    return tracks
        .whereType<Map<String, dynamic>>()
        .map((t) => TrackModel.fromJson(t))
        .toList();
  }

  Future<void> clearRecentlyPlayed() async {
    await _recentlyPlayedBox.put('tracks', []);
  }

  /// --- Search History ---

  Future<void> addSearchQuery(String query) async {
    if (_searchHistoryBox.values.contains(query)) return;
    await _searchHistoryBox.add(query);
    if (_searchHistoryBox.length > 50) {
      await _searchHistoryBox.deleteAt(0);
    }
  }

  List<String> getSearchHistory() {
    return _searchHistoryBox.values.toList();
  }

  Future<void> clearSearchHistory() async {
    await _searchHistoryBox.clear();
  }

  /// --- Player State ---

  Future<void> savePlayerState(dynamic state) async {
    await _playerStateBox.put('state', state);
  }

  dynamic getPlayerState() {
    return _playerStateBox.get('state');
  }

  /// --- Cache Settings ---

  String? getCacheSize() {
    return _cacheSettingsBox.get('size', defaultValue: '0 MB');
  }

  Future<void> setCacheSize(String size) async {
    await _cacheSettingsBox.put('size', size);
  }

  /// --- Local Tracks ---

  Future<void> addLocalTrack(LocalTrackModel track) async {
    final tracks = _localTracksBox.values.toList();
    if (!tracks.any((t) => t.id == track.id)) {
      await _localTracksBox.add(track);
    }
  }

  Future<void> removeLocalTrack(String trackId) async {
    final tracks = _localTracksBox.values.toList();
    final index = tracks.indexWhere((t) => t.id == trackId);
    if (index >= 0) {
      await _localTracksBox.deleteAt(index);
    }
  }

  List<LocalTrackModel> getLocalTracks() {
    return _localTracksBox.values
        .whereType<LocalTrackModel>()
        .toList();
  }

  /// Dispose/close boxes
  Future<void> close() async {
    await _favoriteBox.close();
    await _playlistsBox.close();
    await _recentlyPlayedBox.close();
    await _searchHistoryBox.close();
    await _playerStateBox.close();
    await _cacheSettingsBox.close();
    await _localTracksBox.close();
  }
}