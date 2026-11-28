import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:sonora/domain/entities/track.dart';
import 'package:rxdart/rxdart.dart';

class AudioPlayerService {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;
  AudioPlayerService._internal();

  final AudioPlayer _player = AudioPlayer();
  final BehaviorSubject<Duration> _positionSubject = BehaviorSubject.seeded(Duration.zero);
  final BehaviorSubject<Duration> _durationSubject = BehaviorSubject.seeded(Duration.zero);
  final BehaviorSubject<bool> _playingSubject = BehaviorSubject.seeded(false);
  final BehaviorSubject<int> _currentIndexSubject = BehaviorSubject.seeded(0);
  final BehaviorSubject<List<MediaItem>> _queueSubject = BehaviorSubject.seeded([]);
  final BehaviorSubject<LoopMode> _loopModeSubject = BehaviorSubject.seeded(LoopMode.off);
  final BehaviorSubject<bool> _shuffleSubject = BehaviorSubject.seeded(false);

  AudioPlayer get player => _player;
  Stream<Duration> get positionStream => _positionSubject.stream;
  Stream<Duration> get durationStream => _durationSubject.stream;
  Stream<bool> get playingStream => _playingSubject.stream;
  Stream<int> get currentIndexStream => _currentIndexSubject.stream;
  Stream<List<MediaItem>> get queueStream => _queueSubject.stream;
  Stream<LoopMode> get loopModeStream => _loopModeSubject.stream;
  Stream<bool> get shuffleStream => _shuffleSubject.stream;

  Duration get currentPosition => _positionSubject.value;
  Duration get currentDuration => _durationSubject.value;
  bool get isPlaying => _playingSubject.value;
  int get currentIndex => _currentIndexSubject.value;
  List<MediaItem> get queue => _queueSubject.value;
  LoopMode get loopMode => _loopModeSubject.value;
  bool get shuffleMode => _shuffleSubject.value;

  Future<void> init() async {
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration.music());

    _player.positionStream.listen((pos) => _positionSubject.add(pos));
    _player.durationStream.listen((dur) => _durationSubject.add(dur ?? Duration.zero));
    _player.playingStream.listen((playing) => _playingSubject.add(playing));
    _player.currentIndexStream.listen((idx) {
      if (idx != null) _currentIndexSubject.add(idx);
    });
    _player.sequenceStateStream.listen((state) {
      if (state != null) _queueSubject.add(state.sequence.map(_toMediaItem).toList());
    });
    _player.loopModeStream.listen((mode) => _loopModeSubject.add(mode));
    _player.shuffleModeEnabledStream.listen((shuffle) => _shuffleSubject.add(shuffle));

    _player.processingStateStream.listen((state) async {
      if (state == ProcessingState.completed) {
        await _handleCompletion();
      }
    });
  }

  MediaItem _toMediaItem(SequenceState state) {
    final track = state.source.tag as Track;
    return MediaItem(
      id: track.id,
      title: track.title,
      artist: track.artist,
      album: track.album,
      artUri: track.coverUrl != null ? Uri.parse(track.coverUrl!) : null,
      duration: track.duration,
      extras: {
        'streamUrl': track.streamUrl,
        'sourceName': track.sourceName,
        'availabilityType': track.availabilityType,
      },
    );
  }

  Future<void> _handleCompletion() async {
    final mode = _loopModeSubject.value;
    if (mode == LoopMode.one) {
      await _player.seek(Duration.zero);
      await _player.play();
    } else if (mode == LoopMode.off && _currentIndexSubject.value >= _queueSubject.value.length - 1) {
      await _player.stop();
    }
  }

  Future<void> setQueue(List<Track> tracks, {int initialIndex = 0}) async {
    final mediaItems = tracks.map((t) => _toTrackMediaItem(t)).toList();
    await _player.setAudioSource(
      ConcatenatingAudioSource(
        children: mediaItems.map((item) => AudioSource.uri(
          Uri.parse(item.extras!['streamUrl'] as String),
          tag: item.extras!['track'] as Track,
        )).toList(),
      ),
      initialIndex: initialIndex,
    );
    _queueSubject.add(mediaItems);
    _currentIndexSubject.add(initialIndex);
  }

  MediaItem _toTrackMediaItem(Track track) {
    return MediaItem(
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
  }

  Future<void> play() async => await _player.play();
  Future<void> pause() async => await _player.pause();
  Future<void> seek(Duration position) async => await _player.seek(position);
  Future<void> next() async => await _player.seekToNext();
  Future<void> previous() async => await _player.seekToPrevious();
  Future<void> setLoopMode(LoopMode mode) async {
    await _player.setLoopMode(mode);
    _loopModeSubject.add(mode);
  }
  Future<void> setShuffleMode(bool enabled) async {
    await _player.setShuffleModeEnabled(enabled);
    _shuffleSubject.add(enabled);
  }
  Future<void> setVolume(double volume) async => await _player.setVolume(volume);

  Future<void> addToQueue(Track track) async {
    await _player.addAudioSource(
      AudioSource.uri(Uri.parse(track.streamUrl ?? ''), tag: track),
    );
    final newQueue = List<MediaItem>.from(_queueSubject.value).._toTrackMediaItem(track);
    _queueSubject.add(newQueue);
  }

  Future<void> removeFromQueue(int index) async {
    await _player.removeAudioSource(index);
    final newQueue = List<MediaItem>.from(_queueSubject.value)..removeAt(index);
    _queueSubject.add(newQueue);
  }

  Future<void> clearQueue() async {
    await _player.stop();
    await _player.setAudioSource(ConcatenatingAudioSource(children: []));
    _queueSubject.add([]);
    _currentIndexSubject.add(0);
  }

  void dispose() {
    _positionSubject.close();
    _durationSubject.close();
    _playingSubject.close();
    _currentIndexSubject.close();
    _queueSubject.close();
    _loopModeSubject.close();
    _shuffleSubject.close();
    _player.dispose();
  }
}