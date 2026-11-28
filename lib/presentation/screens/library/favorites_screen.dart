import 'package:flutter/material.dart';
import 'package:sonora/core/themes/app_theme.dart';
import 'package:sonora/presentation/widgets/track_tile.dart';
import 'package:sonora/presentation/widgets/mini_player.dart';
import 'package:sonora/data/hive/hive_service.dart';
import 'package:sonora/data/models/track_model.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final HiveService _hiveService = HiveService();
  late Future<List<TrackModel>> _favoritesFuture;
  Track? _currentTrack;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  void _loadFavorites() {
    setState(() {
      _favoritesFuture = Future.value(_hiveService.getFavoriteTracks());
    });
  }

  Future<void> _toggleFavorite(TrackModel track) async {
    await _hiveService.toggleFavorite(track);
    _loadFavorites();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Избранное'),
        backgroundColor: AppTheme.surfaceColor,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Обновить',
            onPressed: _loadFavorites,
          ),
        ],
      ),
      body: FutureBuilder<List<TrackModel>>(
        future: _favoritesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final tracks = snapshot.data ?? [];
          if (tracks.isEmpty) {
            return _buildEmpty();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tracks.length,
            itemBuilder: (context, index) {
              final track = tracks[index];
              return TrackTile(
                track: track.toEntity(),
                isCurrent: _currentTrack?.id == track.id,
                onTap: () => setState(() => _currentTrack = track.toEntity()),
                trailing: IconButton(
                  icon: Icon(
                    _hiveService.isFavorite(track.id) ? Icons.favorite : Icons.favorite_border,
                    color: _hiveService.isFavorite(track.id) ? Colors.red : AppTheme.textSecondary,
                  ),
                  onPressed: () => _toggleFavorite(track),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_currentTrack != null) MiniPlayer(track: _currentTrack),
          const NavigationBar(
            selectedIndex: 0,
            onDestinationSelected: (i) => {},
            destinations: [
              NavigationDestination(
                  icon: Icon(Icons.favorite_outlined),
                  selectedIcon: Icon(Icons.favorite),
                  label: 'Избранное'),
              NavigationDestination(
                  icon: Icon(Icons.music_note_outlined),
                  selectedIcon: Icon(Icons.music_note),
                  label: 'Плейлисты'),
              NavigationDestination(
                  icon: Icon(Icons.album_outlined),
                  selectedIcon: Icon(Icons.album),
                  label: 'Альбомы'),
              NavigationDestination(
                  icon: Icon(Icons.person_outlined),
                  selectedIcon: Icon(Icons.person),
                  label: 'Исполнители'),
              NavigationDestination(
                  icon: Icon(Icons.folder_outlined),
                  selectedIcon: Icon(Icons.folder),
                  label: 'Моя музыка'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.favorite_border, size: 64, color: AppTheme.textSecondary),
            const SizedBox(height: 16),
            const Text(
              'Избранное пусто',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Добавьте треки в избранное, нажимая на сердечко',
              style: TextStyle(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}