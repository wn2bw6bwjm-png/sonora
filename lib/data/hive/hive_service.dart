import 'package:hive_flutter/hive_flutter.dart';
import '../../models/track_model.dart';
import 'box_keys.dart';

/// Hive service for local storage of favorites, playlists, history, and settings
class HiveService {
  late final Box<TrackModel> _favoriteBox;
  late final Box<List<dynamic>> _playlistsBox;
  late final Box<List<dynamic>> _recentlyPlayedBox;
  late final Box<String> _searchHistoryBox;
  late final Box<String> _playerStateBox;
  late final Box<String> _cacheSettingsBox;

  HiveService._internal();
  static final HiveService _instance = HiveService._instance;
  factory HiveService() => _instance;

  /// Initialize Hive boxes
  Future<void> init() async {
    // Register adapters
    Hive.registerAdapter(TrackModelAdapter());
    Hive.registerAdapter(ListAdapter<dynamic>());
    Hive.registerAdapter(StringAdapter());

    // Open boxes
    _favoriteBox = await Hive.openBox<TrackModel>(BoxKeys.favoriteTracks);
    _playlistsBox = await Hive.openBox<List<dynamic>>(BoxKeys.playlists);
    _recentlyPlayedBox = await Hive.openBox<List<dynamic>>(BoxKeys.recentlyPlayed);
    _searchHistoryBox = await Hive.openBox<String>(BoxKeys.searchHistory);
    _playerStateBox = await Hive.openBox<String>(BoxKeys.playerState);
    _cacheSettingsBox = await Hive.openBox<String>(BoxKeys.cacheSettings);
  }

  /// --- Favorite Tracks ---

  /// Add track to favorites
  Future<void> addFavorite(TrackModel track) async {
    final tracks = _favoriteBox.values.toList();
    // Check if already favorited
    if (!tracks.any((t) => t.id == track.id)) {
      await _favoriteBox.add(track);
    }
  }

  /// Remove track from favorites
  Future<void> removeFavorite(String trackId) async {
    final tracks = _favoriteBox.values.toList();
    await _favoriteBox.deleteAt(tracks.indexWhere((t) => t.id == trackId));
  }

  /// Check if track is favorite
  bool isFavorite(String trackId) {
    return _favoriteBox.values.any((t) => t.id == trackId);
  }

  /// Get all favorite tracks
  List<TrackModel> getFavoriteTracks() {
    return _favoriteBox.values.toList();
  }

  /// Toggle favorite (add if not, remove if already)
  Future<void> toggleFavorite(TrackModel track) async {
    if (isFavorite(track.id)) {
      await removeFavorite(track.id);
    } else {
      await addFavorite(track);
    }
  }

  /// --- Playlists ---

  /// Create a new playlist
  Future<void> createPlaylist(String name, List<TrackModel> tracks) async {
    final playlist = {
      'name': name,
      'tracks': tracks.map((t) => t.toJson()).toList(),
      'createdAt': DateTime.now().toIso8601String(),
    };
    await _playlistsBox.add(playlist);
  }

  /// Get all playlists
  List<Map<String, dynamic>> getPlaylists() {
    return _playlistsBox.values.toList().cast<Map<String, dynamic>>();
  }

  /// Get a specific playlist
  Map<String, dynamic>? getPlaylist(String playlistId) {
    // Note: This needs playlist ID mapping - simplified for now
    final playlists = getPlaylists();
    return playlists.isNotEmpty ? playlists.first : null;
  }

  /// Add track to playlist
  Future<void> addTrackToPlaylist(String playlistId, TrackModel track) async {
    final playlists = _playlistsBox.values.toList();
    final index = playlists.indexWhere((p) => p['id'] == playlistId);
    if (index >= 0) {
      final playlist = playlists[index] as Map<String, dynamic>;
      final List<dynamic> tracks = playlist['tracks'] ?? [];
      tracks.add(track.toJson());
      await _playlistsBox.putAt(index, playlist);
    }
  }

  /// Remove track from playlist
  Future<void> removeTrackFromPlaylist(
      String playlistId, String trackId) async {
    final playlists = _playlistsBox.values.toList();
    final index = playlists.indexWhere((p) => p['id'] == playlistId);
    if (index >= 0) {
      final playlist = playlists[index] as Map<String, dynamic>;
      final List<dynamic> tracks = playlist['tracks'] ?? [];
      tracks.removeWhere((t) => t['id'] == trackId);
      await _playlistsBox.putAt(index, playlist);
    }
  }

  /// --- Recently Played ---

  /// Add track to recently played
  Future<void> addRecentlyPlayed(TrackModel track) async {
    List<dynamic> tracks = _recentlyPlayedBox.values.toList();
    // Add to beginning, remove if already exists
    tracks.removeWhere((t) => t['id'] == track.id);
    tracks.insert(0, track.toJson());
    // Keep only last 50
    if (tracks.length > 50) {
      tracks.removeLast();
    }
    await _recentlyPlayedBox.put('tracks', tracks);
  }

  /// Get recently played tracks
  List<TrackModel> getRecentlyPlayed() {
    final tracks =
        _recentlyPlayedBox.get('tracks', defaultValue: []) as List<dynamic>;
    return tracks.map((t) => TrackModel.fromJson(t as Map<String, dynamic>)).toList();
  }

  /// --- Search History ---

  /// Add search query to history
  Future<void> addSearchQuery(String query) async {
    // Avoid duplicates
    if (_searchHistoryBox.values.contains(query)) return;
    await _searchHistoryBox.add(query);
    // Keep only last 20
    if (_searchHistoryBox.length > 20) {
      await _searchHistoryBox.deleteAt(0);
    }
  }

  /// Get search history
  List<String> getSearchHistory() {
    return _searchHistoryBox.values.toList();
  }

  /// Clear search history
  Future<void> clearSearchHistory() async {
    await _searchHistoryBox.clear();
  }

  /// --- Player State ---

  /// Save player state
  Future<void> savePlayerState(dynamic state) async {
    await _playerStateBox.put('state', state);
  }

  /// Get player state
  dynamic getPlayerState() {
    return _playerStateBox.get('state');
  }

  /// --- Cache Settings ---

  /// Get cache size
  String getCacheSize() {
    return _cacheSettingsBox.get('size', defaultValue: '0 MB');
  }

  /// Set cache size
  Future<void> setCacheSize(String size) async {
    await _cacheSettingsBox.put('size', size);
  }

  /// Dispose/close boxes
  Future<void> close() async {
    await _favoriteBox.close();
    await _playlistsBox.close();
    await _recentlyPlayedBox.close();
    await _searchHistoryBox.close();
    await _playerStateBox.close();
    await _cacheSettingsBox.close();
  }
}

/// Generic list adapter for Hive
class ListAdapter<T> extends TypeAdapter<List<T>> {
  @override
  final int typeId = 0;

  @override
  int get listSize => adapter.listSize;

  @override
  List<T> read(Reader reader) {
    final listSize = reader.readByte();
    final items = <T>[];
    for (int i = 0; i < listSize; i++) {
      items.add(adapter.read(reader) as T);
    }
    return items;
  }

  @override
  void write(Writer writer, List<T> obj) {
    writer.writeByte(obj.length);
    for (final item in obj) {
      adapter.write(writer, item);
    }
  }
}

/// String adapter for Hive
class StringAdapter extends TypeAdapter<String> {
  @override
  final int typeId = 1;

  @override
  String read(Reader reader) => reader.readString();

  @override
  void write(Writer writer, String obj) => writer.writeString(obj);
}