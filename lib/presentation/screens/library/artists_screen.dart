import 'package:flutter/material.dart';
import 'package:sonora/core/themes/app_theme.dart';
import 'package:sonora/presentation/widgets/track_tile.dart';
import 'package:sonora/presentation/widgets/mini_player.dart';
import 'package:sonora/data/hive/hive_service.dart';
import 'package:sonora/data/models/track_model.dart';

class ArtistsScreen extends StatefulWidget {
  const ArtistsScreen({super.key});

  @override
  State<ArtistsScreen> createState() => _ArtistsScreenState();
}

class _ArtistsScreenState extends State<ArtistsScreen> {
  final HiveService _hiveService = HiveService();
  late Future<List<TrackModel>> _tracksFuture;
  Map<String, List<TrackModel>> _artistsMap = {};
  Track? _currentTrack;

  @override
  void initState() {
    super.initState();
    _loadArtists();
  }

  void _loadArtists() {
    setState(() {
      _tracksFuture = Future.value(_hiveService.getFavoriteTracks());
    });
  }

  void _groupByArtist(List<TrackModel> tracks) {
    _artistsMap.clear();
    for (final track in tracks) {
      final artist = track.artist;
      _artistsMap.putIfAbsent(artist, () => []).add(track);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Исполнители'),
        backgroundColor: AppTheme.surfaceColor,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Обновить',
            onPressed: _loadArtists,
          ),
        ],
      ),
      body: FutureBuilder<List<TrackModel>>(
        future: _tracksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final tracks = snapshot.data ?? [];
          if (tracks.isEmpty) {
            return _buildEmpty();
          }

          _groupByArtist(tracks);

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.8,
            ),
            itemCount: _artistsMap.length,
            itemBuilder: (context, index) {
              final artistName = _artistsMap.keys.elementAt(index);
              final artistTracks = _artistsMap[artistName]!;
              final coverTrack = artistTracks.first;
              return _buildArtistCard(artistName, artistTracks, coverTrack);
            },
          );
        },
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_currentTrack != null) MiniPlayer(track: _currentTrack),
          const NavigationBar(
            selectedIndex: 3,
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

  Widget _buildArtistCard(String artistName, List<TrackModel> tracks, TrackModel coverTrack) {
    return Card(
      color: AppTheme.cardColor,
      child: InkWell(
        onTap: () => _showArtistTracks(artistName, tracks),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: coverTrack.coverUrl != null && coverTrack.coverUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      child: Image.network(
                        coverTrack.coverUrl!,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _artistPlaceholder(),
                      ),
                    )
                  : _artistPlaceholder(),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    artistName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${tracks.length} треков',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _artistPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
      ),
      child: const Center(
        child: Icon(Icons.person, size: 48, color: AppTheme.textSecondary),
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
            const Icon(Icons.person_outline, size: 64, color: AppTheme.textSecondary),
            const SizedBox(height: 16),
            const Text(
              'Исполнителей пока нет',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Добавьте треки в избранное для группировки по исполнителям',
              style: TextStyle(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showArtistTracks(String artistName, List<TrackModel> tracks) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.onSurfaceVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                artistName,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: tracks.length,
                itemBuilder: (context, index) {
                  final track = tracks[index];
                  return TrackTile(
                    track: track.toEntity(),
                    isCurrent: _currentTrack?.id == track.id,
                    onTap: () => setState(() => _currentTrack = track.toEntity()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}