import 'dart:async';

import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../data/media/image_store.dart';
import '../domain/entities/queue_item.dart';

/// Контракт аудио-движка.
abstract class AudioEngine {
  Stream<Duration> get positionStream;
  Stream<Duration?> get durationStream;
  Stream<void> get completedStream;

  /// Состояние play/pause, которое может меняться извне (уведомление, наушники, звонок).
  Stream<bool> get playingStream;

  /// true, если текущий трек реально воспроизводится из аудиофайла.
  bool get hasAudio;
  Future<void> load(QueueItem item);
  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration position);
  void dispose();
}

/// Беззвучный движок: ведёт реальный таймлайн трека, но звук не воспроизводит.
class SilentTimelineEngine implements AudioEngine {
  final _pos = StreamController<Duration>.broadcast();
  final _dur = StreamController<Duration?>.broadcast();
  final _done = StreamController<void>.broadcast();
  final _sw = Stopwatch();
  Timer? _timer;
  Duration _position = Duration.zero, _base = Duration.zero;
  Duration? _duration;

  @override
  Stream<Duration> get positionStream => _pos.stream;
  @override
  Stream<Duration?> get durationStream => _dur.stream;
  @override
  Stream<void> get completedStream => _done.stream;
  @override
  Stream<bool> get playingStream => const Stream<bool>.empty();
  @override
  bool get hasAudio => false;

  void _halt() {
    _timer?.cancel();
    _timer = null;
    _sw.stop();
  }

  @override
  Future<void> load(QueueItem item) async {
    _halt();
    _sw.reset();
    _position = Duration.zero;
    _base = Duration.zero;
    _duration = item.durationMs == null ? null : Duration(milliseconds: item.durationMs!);
    _dur.add(_duration);
    _pos.add(_position);
  }

  @override
  Future<void> play() async {
    _halt();
    _base = _position;
    _sw
      ..reset()
      ..start();
    _timer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      _position = _base + _sw.elapsed;
      final d = _duration;
      if (d != null && _position >= d) {
        _position = d;
        _pos.add(_position);
        _halt();
        _done.add(null);
        return;
      }
      _pos.add(_position);
    });
  }

  @override
  Future<void> pause() async {
    _position = _base + _sw.elapsed;
    _halt();
  }

  @override
  Future<void> seek(Duration position) async {
    final d = _duration;
    _position = (d != null && position > d) ? d : position;
    _base = _position;
    _sw.reset();
    _pos.add(_position);
  }

  @override
  void dispose() {
    _halt();
    _pos.close();
    _dur.close();
    _done.close();
  }
}

/// Играет локальные аудиофайлы пользователя через just_audio; для треков без
/// файла (или если файл не открылся) переключается на беззвучный таймлайн.
class HybridAudioEngine implements AudioEngine {
  HybridAudioEngine() {
    _subs
      ..add(_silent.positionStream.listen((p) {
        if (!_file) _pos.add(p);
      }))
      ..add(_silent.durationStream.listen((d) {
        if (!_file) _dur.add(d);
      }))
      ..add(_silent.completedStream.listen((_) {
        if (!_file) _done.add(null);
      }));
  }

  final _silent = SilentTimelineEngine();
  AudioPlayer? _player; // создаётся лениво, пока нет файлов, плагин не трогаем
  final _pos = StreamController<Duration>.broadcast();
  final _dur = StreamController<Duration?>.broadcast();
  final _done = StreamController<void>.broadcast();
  final _playing = StreamController<bool>.broadcast();
  final _subs = <StreamSubscription<dynamic>>[];
  bool _file = false;

  AudioPlayer _ensure() {
    final existing = _player;
    if (existing != null) return existing;
    final p = AudioPlayer();
    _player = p;
    _subs
      ..add(p.positionStream.listen((x) {
        if (_file) _pos.add(x);
      }))
      ..add(p.durationStream.listen((d) {
        if (_file) _dur.add(d);
      }))
      ..add(p.processingStateStream.listen((s) {
        if (_file && s == ProcessingState.completed) _done.add(null);
      }))
      ..add(p.playingStream.listen((x) {
        if (_file) _playing.add(x);
      }));
    return p;
  }

  @override
  Stream<Duration> get positionStream => _pos.stream;
  @override
  Stream<Duration?> get durationStream => _dur.stream;
  @override
  Stream<void> get completedStream => _done.stream;
  @override
  Stream<bool> get playingStream => _playing.stream;
  @override
  bool get hasAudio => _file;

  @override
  Future<void> load(QueueItem item) async {
    _file = false;
    await _silent.pause();
    final path = ImageStore.resolve(item.filePath);
    if (path != null) {
      try {
        final p = _ensure();
        await p.stop();
        final cover = ImageStore.resolve(item.coverPath);
        await p.setAudioSource(AudioSource.uri(
          Uri.file(path),
          tag: MediaItem(
            id: '${item.trackId}',
            title: item.title,
            artist: item.artist,
            album: item.albumTitle,
            artUri: cover != null
                ? Uri.file(cover)
                : (ImageStore.isUrl(item.coverPath) ? Uri.parse(item.coverPath!) : null),
          ),
        ));
        _file = true;
        _dur.add(p.duration);
        _pos.add(Duration.zero);
        return;
      } catch (_) {
        // Файл не открылся: падаем в беззвучный режим.
      }
    }
    await _player?.stop();
    await _silent.load(item);
  }

  @override
  Future<void> play() async {
    if (_file) {
      unawaited(_player!.play());
    } else {
      await _silent.play();
    }
  }

  @override
  Future<void> pause() async {
    if (_file) {
      await _player!.pause();
    } else {
      await _silent.pause();
    }
  }

  @override
  Future<void> seek(Duration position) async {
    if (_file) {
      await _player!.seek(position);
    } else {
      await _silent.seek(position);
    }
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _player?.dispose();
    _silent.dispose();
    _playing.close();
    _pos.close();
    _dur.close();
    _done.close();
  }
}
