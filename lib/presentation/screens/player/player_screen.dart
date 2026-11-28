import 'package:flutter/material.dart';
import 'package:sonora/core/themes/app_theme.dart';
import 'package:sonora/domain/entities/track.dart';
import 'package:sonora/presentation/widgets/mini_player.dart';
import 'package:sonora/services/audio_player_service.dart';

enum RepeatMode { off, one, all }

class PlayerScreen extends StatefulWidget {
  final Track? initialTrack;
  final List<Track> initialQueue;

  const PlayerScreen({
    super.key,
    this.initialTrack,
    this.initialQueue = const [],
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with SingleTickerProviderStateMixin {
  final AudioPlayerService _audioPlayerService = AudioPlayerService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;
  Track? _currentTrack;
  List<Track> _queue = [];
  RepeatMode _repeatMode = RepeatMode.off;
  bool _isShuffling = false;
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _showQueue = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _slideAnimation = Tween<double>(begin: 50, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _initAudioService();
    _animationController.forward();

    // Initialize from provided track
    _currentTrack = widget.initialTrack;
    _queue = widget.initialQueue;
    if (_currentTrack != null && _queue.isEmpty) {
      _queue = [_currentTrack!];
    }
  }

  Future<void> _initAudioService() async {
    await _audioPlayerService.init();

    _audioPlayerService.playingStream.listen((playing) {
      if (mounted) setState(() => _isPlaying = playing);
    });

    _audioPlayerService.positionStream.listen((position) {
      if (mounted) setState(() => _currentPosition = position);
    });

    _audioPlayerService.durationStream.listen((duration) {
      if (mounted) setState(() => _totalDuration = duration);
    });

    _audioPlayerService.currentIndexStream.listen((index) {
      if (mounted && index < _audioPlayerService.queue.length) {
        final item = _audioPlayerService.queue[index];
        final track = item.extras?['track'] as Track?;
        if (track != null) {
          setState(() {
            _currentTrack = track;
            _queue = _audioPlayerService.queue.map(_mediaItemToTrack).toList();
          });
        }
      }
    });

    _audioPlayerService.loopModeStream.listen((mode) {
      if (mounted) {
        RepeatMode newMode;
        switch (mode) {
          case LoopMode.off:
            newMode = RepeatMode.off;
            break;
          case LoopMode.one:
            newMode = RepeatMode.one;
            break;
          case LoopMode.all:
            newMode = RepeatMode.all;
            break;
        }
        setState(() => _repeatMode = newMode);
      }
    });

    _audioPlayerService.shuffleStream.listen((shuffle) {
      if (mounted) setState(() => _isShuffling = shuffle);
    });
  }

  Track _mediaItemToTrack(MediaItem item) {
    return item.extras!['track'] as Track;
  }

  @override
  void dispose() {
    _animationController.dispose();
    _audioPlayerService.dispose();
    super.dispose();
  }

  Future<void> _togglePlayPause() async {
    if (_isPlaying) {
      await _audioPlayerService.pause();
    } else {
      await _audioPlayerService.play();
    }
  }

  Future<void> _nextTrack() async => await _audioPlayerService.next();

  Future<void> _previousTrack() async => await _audioPlayerService.previous();

  Future<void> _seekTo(Duration position) async => await _audioPlayerService.seek(position);

  Future<void> _toggleRepeat() async {
    RepeatMode newMode;
    switch (_repeatMode) {
      case RepeatMode.off:
        newMode = RepeatMode.one;
        break;
      case RepeatMode.one:
        newMode = RepeatMode.all;
        break      case RepeatMode.all:
        newMode = RepeatMode.off;
        break;
    }
    await _audioPlayerService.setLoopMode(
      newMode == RepeatMode.off ? LoopMode.off : newMode == RepeatMode.one ? LoopMode.one : LoopMode.all,
    );
    setState(() => _repeatMode = newMode);
  }

  Future<void> _toggleShuffle() async {
    await _audioPlayerService.setShuffleMode(!_isShuffling);
    setState(() => _isShuffling = !_isShuffling);
  }

  Future<void> _removeFromQueue(int index) async {
    await _audioPlayerService.removeFromQueue(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background with album art colors
          _buildBackground(),
          // Content
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) => Transform.translate(
              offset: Offset(0, _slideAnimation.value),
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: _buildPlayerContent(),
                ),
              ),
            ),
          ),
          // Mini player at bottom (when not fullscreen)
          if (!_showQueue && _currentTrack != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: MiniPlayer(track: _currentTrack!),
            ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: _currentTrack?.coverUrl != null
              ? [
                  AppTheme.surfaceColor,
                  AppTheme.background,
                  AppTheme.background,
                ]
              : [
                  AppTheme.surfaceColor,
                  AppTheme.background,
                ],
        ),
      ),
      child: _currentTrack?.coverUrl != null
          ? Positioned.fill(
              child: Image.network(
                _currentTrack!.coverUrl!,
                fit: BoxFit.cover,
                colorBlendMode: BlendMode.darken,
                color: Colors.black.withValues(alpha: 0.7),
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),
            )
          : const SizedBox(),
    );
  }

  Widget _buildPlayerContent() {
    if (_currentTrack == null) {
      return _buildWelcomeScreen();
    }

    return SafeArea(
      child: Column(
        children: [
          // Top bar with close button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 40),
                const Text(
                  'Воспроизведение',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: _showQueue
                      ? const Icon(Icons.queue_music, color: AppTheme.primary)
                      : const Icon(Icons.queue_music, color: AppTheme.textSecondary),
                  onPressed: () => setState(() => _showQueue = !_showQueue),
                ),
              ],
            ),
          ),

          if (!_showQueue) ...[
            // Album art with hero animation
            Expanded(
              flex: 3,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Hero(
                    tag: 'album-art-${_currentTrack!.id}',
                    child: _buildAlbumArt(),
                  ),
                ),
              ),
            ),

            // Track info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: _buildTrackInfo(),
            ),

            // Progress bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildProgressBar(),
            ),

            // Controls
            Padding(
              padding: const EdgeInsets.all(24),
              child: _buildControls(),
            ),

            // Repeat/Shuffle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildQueueOptions(),
            ),

            const SizedBox(height: 80), // Space for mini player
          ] else ...[
            // Queue view
            Expanded(
              child: _buildQueueView(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.music_note,
            size: 80,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(height: 24),
          const Text(
            'Выберите композицию',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Используйте поиск или медиатеку для выбора трека',
            style: TextStyle(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumArt() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _currentTrack!.coverUrl != null && _currentTrack!.coverUrl!.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  _currentTrack!.coverUrl!,
                  width: 280,
                  height: 280,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildArtPlaceholder(),
                ),
              )
            : _buildArtPlaceholder(),
      ],
    );
  }

  Widget _buildArtPlaceholder() {
    return Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary.withValues(alpha: 0.3), AppTheme.secondary.withValues(alpha: 0.3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
        child: Icon(Icons.music_note, size: 100, color: AppTheme.textSecondary),
      ),
    );
  }

  Widget _buildTrackInfo() {
    return Column(
      children: [
        Text(
          _currentTrack!.title,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 26,
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          _currentTrack!.artist,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 18,
          ),
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        if (_currentTrack!.album != null) ...[
          const SizedBox(height: 4),
          Text(
            _currentTrack!.album!,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildProgressBar() {
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            activeTrackColor: AppTheme.accentColor,
            inactiveTrackColor: AppTheme.onSurfaceVariant.withValues(alpha: 0.3),
            thumbColor: AppTheme.accentColor,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            overlayColor: AppTheme.accentColor.withValues(alpha: 0.2),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
          ),
          child: Slider(
            value: _currentPosition.inMilliseconds.toDouble().clamp(
              0,
              _totalDuration.inMilliseconds.toDouble().max(1),
            ),
            max: _totalDuration.inMilliseconds.toDouble().max(1),
            onChanged: (value) => _seekTo(Duration(milliseconds: value.round())),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(_currentPosition),
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
              Text(
                _formatDuration(_totalDuration),
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Shuffle
        IconButton(
          icon: Icon(
            _isShuffling ? Icons.shuffle : Icons.shuffle_outlined,
            color: _isShuffling ? AppTheme.primary : AppTheme.textSecondary,
            size: 28,
          ),
          onPressed: _toggleShuffle,
          tooltip: 'Перемешивать',
        ),

        // Previous
        IconButton(
          icon: const Icon(Icons.skip_previous, size: 40, color: AppTheme.textPrimary),
          onPressed: _previousTrack,
          tooltip: 'Предыдущий',
        ),

        // Play/Pause - Large button with animation
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primary, AppTheme.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.4),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              size: 32,
              color: AppTheme.onPrimary,
            ),
            onPressed: _togglePlayPause,
            tooltip: _isPlaying ? 'Пауза' : 'Воспроизвести',
          ),
        ),

        // Next
        IconButton(
          icon: const Icon(Icons.skip_next, size: 40, color: AppTheme.textPrimary),
          onPressed: _nextTrack,
          tooltip: 'Следующий',
        ),

        // Repeat
        IconButton(
          icon: Icon(
            _repeatMode == RepeatMode.off
                ? Icons.repeat
                : _repeatMode == RepeatMode.one
                    ? Icons.repeat_one
                    : Icons.repeat,
            color: _repeatMode != RepeatMode.off ? AppTheme.primary : AppTheme.textSecondary,
            size: 28,
          ),
          onPressed: _toggleRepeat,
          tooltip: 'Повтор',
        ),
      ],
    );
  }

  Widget _buildQueueOptions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildOptionChip(
          icon: _isShuffling ? Icons.shuffle : Icons.shuffle_outlined,
          label: 'Перемешивать',
          isActive: _isShuffling,
          onTap: _toggleShuffle,
        ),
        const SizedBox(width: 16),
        _buildOptionChip(
          icon: _repeatMode == RepeatMode.off
              ? Icons.repeat
              : _repeatMode == RepeatMode.one
                  ? Icons.repeat_one
                  : Icons.repeat,
          label: 'Повтор',
          isActive: _repeatMode != RepeatMode.off,
          onTap: _toggleRepeat,
        ),
      ],
    );
  }

  Widget _buildOptionChip({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primary.withValues(alpha: 0.2) : AppTheme.cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isActive ? AppTheme.primary : AppTheme.onSurfaceVariant.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isActive ? AppTheme.primary : AppTheme.textSecondary),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppTheme.primary : AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQueueView() {
    if (_queue.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.queue_music, size: 64, color: AppTheme.textSecondary),
            const SizedBox(height: 16),
            const Text('Очередь пуста', style: TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Очередь (${_queue.length})',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton.icon(
                onPressed: () async {
                  await _audioPlayerService.clearQueue();
                  setState(() => _queue.clear());
                },
                icon: const Icon(Icons.clear_all, size: 18),
                label: const Text('Очистить'),
                style: TextButton.styleFrom(foregroundColor: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _queue.length,
            onReorder: (oldIndex, newIndex) async {
              await _audioPlayerService.removeFromQueue(oldIndex);
              // Note: Full reorder would need queue manipulation
            },
            itemBuilder: (context, index) {
              final track = _queue[index];
              final isCurrent = _currentTrack?.id == track.id;
              return Card(
                key: ValueKey(track.id),
                color: isActive ? AppTheme.primary.withValues(alpha: 0.1) : AppTheme.cardColor,
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: track.coverUrl != null && track.coverUrl!.isNotEmpty
                        ? Image.network(
                            track.coverUrl!,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _queuePlaceholder(),
                          )
                        : _queuePlaceholder(),
                  ),
                  title: Text(
                    track.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isCurrent ? AppTheme.primary : AppTheme.textPrimary,
                      fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    track.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isCurrent)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Сейчас',
                            style: TextStyle(
                              color: AppTheme.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      else
                        IconButton(
                          icon: const Icon(Icons.close, size: 18, color: AppTheme.textSecondary),
                          onPressed: () => _removeFromQueue(index),
                        ),
                    ],
                  ),
                  onTap: () {
                    _audioPlayerService.player.seek(Duration.zero, index: index);
                    setState(() => _showQueue = false);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _queuePlaceholder() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Icon(Icons.music_note, color: AppTheme.textSecondary, size: 22),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}