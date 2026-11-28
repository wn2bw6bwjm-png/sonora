import 'package:flutter/material.dart';
import 'package:sonora/core/themes/app_theme.dart';
import 'package:sonora/presentation/widgets/track_tile.dart';
import 'package:sonora/presentation/widgets/mini_player.dart';
import 'package:sonora/data/repositories/local_track_repository.dart';

class LocalMusicScreen extends StatefulWidget {
  const LocalMusicScreen({super.key});

  @override
  State<LocalMusicScreen> createState() => _LocalMusicScreenState();
}

class _LocalMusicScreenState extends State<LocalMusicScreen> {
  final LocalTrackRepository _repository = LocalTrackRepositoryImpl(
    dataSource: LocalDataSource(),
    hiveService: HiveService(),
  );
  late Future<List<Track>> _tracksFuture;
  Track? _currentTrack;

  @override
  void initState() {
    super.initState();
    _loadTracks();
  }

  void _loadTracks() {
    setState(() {
      _tracksFuture = _repository.getLocalTracks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Моя музыка'),
        backgroundColor: AppTheme.surfaceColor,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Добавить файлы',
            onPressed: _importFiles,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Обновить',
            onPressed: _loadTracks,
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_currentTrack != null) MiniPlayer(track: _currentTrack),
          const NavigationBar(
            selectedIndex: 4,
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

  Widget _buildBody() {
    return FutureBuilder<List<Track>>(
      future: _tracksFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildError(snapshot.error.toString());
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
              track: track,
              isCurrent: _currentTrack?.id == track.id,
              onTap: () => setState(() => _currentTrack = track),
            );
          },
        );
      },
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Ошибка загрузки',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(message, style: const TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadTracks,
              child: const Text('Повторить'),
            ),
          ],
        ),
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
            const Icon(Icons.music_off, size: 64, color: AppTheme.textSecondary),
            const SizedBox(height: 16),
            const Text(
              'Локальная музыка не найдена',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Добавьте аудиофайлы с устройства',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _importFiles,
              icon: const Icon(Icons.upload_file),
              label: const Text('Импортировать'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _importFiles() async {
    try {
      await _repository.importAudioFiles();
      _loadTracks();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Файлы импортированы')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка импорта: $e')),
        );
      }
    }
  }
}