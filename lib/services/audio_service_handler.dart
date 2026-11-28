import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:sonora/domain/entities/track.dart';
import 'package:sonora/services/audio_player_service.dart';

/// AudioHandler for background playback and lock screen controls
class SonoraAudioHandler extends BaseAudioHandler
    with SeekHandler, QueueHandler, CustomEventHandler {
  final AudioPlayerService _playerService = AudioPlayerService();

  SonoraAudioHandler();

  Future<void> init() async {
    await _playerService.init();
    _syncPlayerState();
  }

  void _syncPlayerState() {
    _playerService.playingStream.listen((playing) {
      playbackState.add(playbackState.value.copyWith(
        playing: playing,
        processingState: playing
            ? AudioProcessingState.playing
            : AudioProcessingState.paused,
      ));
    });

    _playerService.positionStream.listen((position) {
      playbackState.add(playbackState.value.copyWith(
        updatePosition: position,
      ));
    });

    _playerService.durationStream.listen((duration) {
      mediaItem.add(_currentMediaItem?.copyWith(duration: duration));
    });

    _playerService.currentIndexStream.listen((index) {
      if (index < _playerService.queue.length) {
        final item = _playerService.queue[index];
        mediaItem.add(item);
      }
    });

    _playerService.queueStream.listen((queue) {
      queue.add(queue);
    });
  }

  MediaItem? get _currentMediaItem => mediaItem.valueOrNull;

  @override
  Future<void> play() async {
    await _playerService.play();
  }

  @override
  Future<void> pause() async {
    await _playerService.pause();
  }

  @override
  Future<void> seek(Duration position) async {
    await _playerService.seek(position);
  }

  @override
  Future<void> skipToNext() async {
    await _playerService.next();
  }

  @override
  Future<void> skipToPrevious() async {
    await _playerService.previous();
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    switch (repeatMode) {
      case AudioServiceRepeatMode.off:
        await _playerService.setLoopMode(LoopMode.off);
        break;
      case AudioServiceRepeatMode.one:
        await _playerService.setLoopMode(LoopMode.one);
        break;
      case AudioServiceRepeatMode.all:
        await _playerService.setLoopMode(LoopMode.all);
        break;
    }
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    await _playerService.setShuffleMode(shuffleMode == AudioServiceShuffleMode.all);
  }

  @override
  Future<void> setVolume(double volume) async {
    await _playerService.setVolume(volume);
  }

  @override
  Future<void> addQueueItem(MediaItem mediaItem) async {
    final track = mediaItem.extras!['track'] as Track;
    await _playerService.addToQueue(track);
    final newQueue = List<MediaItem>.from(queue.value)..add(mediaItem);
    queue.add(newQueue);
  }

  @override
  Future<void> removeQueueItem(MediaItem mediaItem) async {
    final index = queue.value.indexOf(mediaItem);
    if (index >= 0) {
      await _playerService.removeFromQueue(index);
      final newQueue = List<MediaItem>.from(queue.value)..removeAt(index);
      queue.add(newQueue);
    }
  }

  @override
  Future<void> onCustomEvent(String name, dynamic arguments) async {
    switch (name) {
      case 'setQueue':
        final tracks = (arguments as List).cast<Track>();
        await _playerService.setQueue(tracks);
        queue.add(arguments);
        break;
      case 'clearQueue':
        await _playerService.clearQueue();
        queue.add([]);
        break;
    }
  }

  Future<void> updateMediaItem(Track track) async {
    final mediaItem = MediaItem(
      id: track.id,
      title: track.title,
      artist: track.artist,
      album: track.album,
      artUri: track.coverUrl != null ? Uri.parse(track.coverUrl!) : null,
      duration: track.duration,
      extras: {
        'streamUrl': track.streamUrl ?? '',
        'sourceName': track.sourceName,
        'availabilityType': track.availabilityType,
        'track': track,
      },
    );
    this.mediaItem.add(mediaItem);
  }
}