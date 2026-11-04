import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/providers.dart';
import '../domain/entities/queue_item.dart';
import 'audio_engine.dart';

final audioEngineProvider = Provider<AudioEngine>((ref) {
  final e = HybridAudioEngine();
  ref.onDispose(e.dispose);
  return e;
});

class PlayerState {
  const PlayerState({
    this.queue = const [],
    this.index = 0,
    this.playing = false,
    this.position = Duration.zero,
    this.durationMs,
    this.hasAudio = false,
  });
  final List<QueueItem> queue;
  final int index;
  final bool playing;
  final Duration position;
  final int? durationMs;
  final bool hasAudio;

  QueueItem? get current => index >= 0 && index < queue.length ? queue[index] : null;

  PlayerState copyWith({
    List<QueueItem>? queue,
    int? index,
    bool? playing,
    Duration? position,
    int? durationMs,
    bool? hasAudio,
  }) =>
      PlayerState(
        queue: queue ?? this.queue,
        index: index ?? this.index,
        playing: playing ?? this.playing,
        position: position ?? this.position,
        durationMs: durationMs ?? this.durationMs,
        hasAudio: hasAudio ?? this.hasAudio,
      );
}

class PlayerController extends Notifier<PlayerState> {
  late final AudioEngine _engine;

  @override
  PlayerState build() {
    _engine = ref.watch(audioEngineProvider);
    final pos = _engine.positionStream.listen((p) {
      if (state.current != null) state = state.copyWith(position: p);
    });
    final dur = _engine.durationStream.listen((d) {
      if (d != null && state.current != null) state = state.copyWith(durationMs: d.inMilliseconds);
    });
    final done = _engine.completedStream.listen((_) => next());
    final playing = _engine.playingStream.listen((p) {
      if (state.current != null && state.playing != p) state = state.copyWith(playing: p);
    });
    ref.onDispose(() {
      pos.cancel();
      dur.cancel();
      done.cancel();
      playing.cancel();
    });
    return const PlayerState();
  }

  Future<void> playQueue(List<QueueItem> queue, int start) async {
    if (queue.isEmpty || start < 0 || start >= queue.length) return;
    state = PlayerState(queue: queue, index: start);
    await _start(start);
  }

  Future<void> _start(int i) async {
    final item = state.queue[i];
    state = PlayerState(queue: state.queue, index: i, playing: true, durationMs: item.durationMs);
    await _engine.load(item);
    state = state.copyWith(hasAudio: _engine.hasAudio);
    await _engine.play();
    ref.read(libraryRepoProvider).logPlay(item.albumId, item.trackId).catchError((_) {});
  }

  Future<void> toggle() async {
    if (state.current == null) return;
    if (state.playing) {
      await _engine.pause();
      state = state.copyWith(playing: false);
    } else {
      final d = state.durationMs;
      if (d != null && state.position.inMilliseconds >= d) {
        await _engine.seek(Duration.zero);
      }
      await _engine.play();
      state = state.copyWith(playing: true);
    }
  }

  Future<void> next() async {
    if (state.queue.isEmpty) return;
    if (state.index + 1 < state.queue.length) {
      await _start(state.index + 1);
    } else {
      await _engine.pause();
      await _engine.seek(Duration.zero);
      state = state.copyWith(playing: false, position: Duration.zero);
    }
  }

  Future<void> previous() async {
    if (state.queue.isEmpty) return;
    if (state.position.inSeconds > 3 || state.index == 0) {
      await _engine.seek(Duration.zero);
      state = state.copyWith(position: Duration.zero);
    } else {
      await _start(state.index - 1);
    }
  }

  Future<void> jumpTo(int i) async {
    if (i >= 0 && i < state.queue.length) await _start(i);
  }

  Future<void> seek(Duration p) async {
    await _engine.seek(p);
    state = state.copyWith(position: p);
  }

  Future<void> stop() async {
    await _engine.pause();
    state = const PlayerState();
  }
}

final playerProvider = NotifierProvider<PlayerController, PlayerState>(PlayerController.new);
