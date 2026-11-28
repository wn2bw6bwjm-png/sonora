import 'package:flutter/material.dart';
import 'package:sonora/core/themes/app_theme.dart';
import 'package:sonora/presentation/widgets/track_tile.dart';
import 'package:sonora/presentation/widgets/mini_player.dart';
import 'package:sonora/data/hive/hive_service.dart';
import 'package:sonora/data/models/track_model.dart';

class PlaylistsScreen extends StatefulWidget {
  const PlaylistsScreen({super.key});

  @override
  State<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends State<PlaylistsScreen> {
  final HiveService _hiveService = HiveService();
  late Future<List<Map<String, dynamic>>> _playlistsFuture;
  Track? _currentTrack;
  Map<String, dynamic>? _selectedPlaylist;

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  void _loadPlaylists() {
    setState(() {
      _playlistsFuture = Future.value(_hiveService.playlists);
    });
  }

  Future<void> _createPlaylist() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text('Новый плейлист', style: TextStyle(color: AppTheme.textPrimary)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: 'Название плейлиста',
            hintStyle: const TextStyle(color: AppTheme.textSecondary),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppTheme.onSurfaceVariant),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppTheme.primary),
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Создать', style: TextStyle(color: AppTheme.primary)),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await _hiveService.createPlaylist(result, []);
      _loadPlaylists();
    }
  }

  Future<void> _renamePlaylist(Map<String, dynamic> playlist) async {
    final controller = TextEditingController(text: playlist['name'] as String);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text('Переименовать', style: TextStyle(color: AppTheme.textPrimary)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: 'Новое название',
            hintStyle: const TextStyle(color: AppTheme.textSecondary),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppTheme.onSurfaceVariant),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppTheme.primary),
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Сохранить', style: TextStyle(color: AppTheme.primary)),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await _hiveService.updatePlaylist(playlist['id'] as String, result);
      _loadPlaylists();
    }
  }

  Future<void> _deletePlaylist(Map<String, dynamic> playlist) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text('Удалить плейлист', style: TextStyle(color: AppTheme.textPrimary)),
        content: Text(
          'Удалить "${playlist['name']}"?',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _hiveService.deletePlaylist(playlist['id'] as String);
      _loadPlaylists();
    }
  }

  Future<void> _openPlaylist(Map<String, dynamic> playlist) async {
    setState(() => _selectedPlaylist = playlist);
  }

  Widget _buildPlaylistList(List<Map<String, dynamic>> playlists) {
    if (playlists.isEmpty) {
      return _buildEmpty();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: playlists.length,
      itemBuilder: (context, index) {
        final playlist = playlists[index];
        final tracks = playlist['tracks'] as List<dynamic>? ?? [];
        return Card(
          color: AppTheme.cardColor,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.queue_music, color: AppTheme.primary, size: 24),
            ),
            title: Text(
              playlist['name'] as String,
              style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${tracks.length} треков',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppTheme.textSecondary),
              color: AppTheme.cardColor,
              onSelected: (value) {
                switch (value) {
                  case 'rename':
                    _renamePlaylist(playlist);
                    break;
                  case 'delete':
                    _deletePlaylist(playlist);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'rename', child: Text('Переименовать')),
                const PopupMenuItem(value: 'delete', child: Text('Удалить', style: TextStyle(color: Colors.red))),
              ],
            ),
            onTap: () => _openPlaylist(playlist),
          ),
        );
      },
    );
  }

  Widget _buildPlaylistDetail(Map<String, dynamic> playlist) {
    final tracks = playlist['tracks'] as List<dynamic>? ?? [];
    return Column(
      children: [
        // Playlist header
        Container(
          padding: const EdgeInsets.all(16),
          color: AppTheme.surfaceColor,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
                onPressed: () => setState(() => _selectedPlaylist = null),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      playlist['name'] as String,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${tracks.length} треков',
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: AppTheme.textPrimary),
                color: AppTheme.cardColor,
                onSelected: (value) {
                  if (value == 'rename') _renamePlaylist(playlist);
                  if (value == 'delete') _deletePlaylist(playlist);
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'rename', child: Text('Переименовать')),
                  const PopupMenuItem(value: 'delete', child: Text('Удалить', style: TextStyle(color: Colors.red))),
                ],
              ),
            ],
          ),
        ),
        // Tracks list
        if (tracks.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.music_off, size: 48, color: AppTheme.textSecondary),
                  const SizedBox(height: 16),
                  const Text('Плейлист пуст', style: TextStyle(color: AppTheme.textSecondary)),
                  const SizedBox(height: 8),
                  Text('Добавьте треки из поиска или медиатеки', style: TextStyle(color: AppTheme.textSecondary)),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tracks.length,
              onReorder: (oldIndex, newIndex) async {
                await _hiveService.reorderPlaylistTracks(
                  playlist['id'] as String,
                  oldIndex,
                  newIndex > oldIndex ? newIndex - 1 : newIndex,
                );
                _loadPlaylists();
              },
              itemBuilder: (context, index) {
                final trackData = tracks[index] as Map<String, dynamic>;
                final track = TrackModel.fromJson(trackData).toEntity();
                return Card(
                  key: ValueKey(track.id),
                  color: AppTheme.cardColor,
                  child: TrackTile(
                    track: track,
                    isCurrent: _currentTrack?.id == track.id,
                    onTap: () => setState(() => _currentTrack = track),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppTheme.textSecondary),
                      onPressed: () async {
                        await _hiveService.removeTrackFromPlaylist(
                          playlist['id'] as String,
                          track.id,
                        );
                        _loadPlaylists();
                      },
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.queue_music, size: 64, color: AppTheme.textSecondary),
            const SizedBox(height: 16),
            const Text(
              'Плейлистов пока нет',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Создайте первый плейлист',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _createPlaylist,
              icon: const Icon(Icons.add),
              label: const Text('Создать плейлист'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: AppTheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Плейлисты'),
        backgroundColor: AppTheme.surfaceColor,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Создать плейлист',
            onPressed: _createPlaylist,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Обновить',
            onPressed: _loadPlaylists,
          ),
        ],
      ),
      body: _selectedPlaylist != null
          ? _buildPlaylistDetail(_selectedPlaylist!)
          : FutureBuilder<List<Map<String, dynamic>>>(
              future: _playlistsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final playlists = snapshot.data ?? [];
                return _buildPlaylistList(playlists);
              },
            ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_currentTrack != null) MiniPlayer(track: _currentTrack),
          const NavigationBar(
            selectedIndex: 1,
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
}