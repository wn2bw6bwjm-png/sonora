import 'package:bloc/bloc.dart';
import 'package:sonora/presentation/blocs/player/player_event.dart';
import 'package:sonora/presentation/blocs/player/player_state.dart';
import 'package:sonora/services/audio_player_service.dart';
import 'package:sonora/domain/entities/track.dart';

class PlayerBloc extends Bloc<PlayerEvent, PlayerState> {
  final AudioPlayerService _audioPlayerService = AudioPlayerService();

  PlayerBloc() : super(PlayerInitial()) {
    _initAudioService();
    on<PlayerPlayPauseEvent>((event, emit) => _onPlayPause(emit));
    on<PlayerNextTrackEvent>((event, emit) => _onNext(emit));
    on<PlayerPreviousTrackEvent>((event, emit) => _onPrevious(emit));
    on<PlayerSeekEvent>((event, emit) => _onSeek(event, emit));
    on<PlayerVolumeEvent>((event, emit) => _onVolume(event, emit));
    on<PlayerSetTrackEvent>((event, emit) => _onSetTrack(event, emit));
    on<PlayerQueueUpdateEvent>((event, emit) => _onQueueUpdate(event, emit));
    on<PlayerShuffleToggleEvent>((event, emit) => _onShuffleToggle(emit));
    on<PlayerRepeatToggleEvent>((event, emit) => _onRepeatToggle(emit));
  }

  Future<void> _initAudioService() async {
    await _audioPlayerService.init();
    _audioPlayerService.positionStream.listen((position) {
      if (state is PlayerReady) {
        final currentState = state as PlayerReady;
        emit(currentState.copyWith(currentPosition: position));
      }
    });
    _audioPlayerService.durationStream.listen((duration) {
      if (state is PlayerReady) {
        final currentState = state as PlayerReady;
        emit(currentState.copyWith(totalDuration: duration));
      }
    });
    _audioPlayerService.playingStream.listen((playing) {
      if (state is PlayerReady) {
        final currentState = state as PlayerReady;
        emit(currentState.copyWith(isPlaying: playing));
      }
    });
    _audioPlayerService.currentIndexStream.listen((index) {
      if (state is PlayerReady && index < _audioPlayerService.queue.length) {
        final track = _audioPlayerService.queue[index].extras?['track'] as Track?;
        if (track != null) {
          final currentState = state as PlayerReady;
          emit(currentState.copyWith(
            currentTrack: track,
            queue: _audioPlayerService.queue.map(_mediaItemToTrack).toList(),
          ));
        }
      }
    });
  }

  Track _mediaItemToTrack(MediaItem item) {
    return item.extras!['track'] as Track;
  }

  Future<void> _onPlayPause(Emitter<PlayerState> emit) async {
    if (state is PlayerReady) {
      final currentState = state as PlayerReady;
      if (currentState.isPlaying) {
        await _audioPlayerService.pause();
      } else {
        await _audioPlayerService.play();
      }
    }
  }

  Future<void> _onNext(Emitter<PlayerState> emit) async {
    await _audioPlayerService.next();
  }

  Future<void> _onPrevious(Emitter<PlayerState> emit) async {
    await _audioPlayerService.previous();
  }

  Future<void> _onSeek(PlayerSeekEvent event, Emitter<PlayerState> emit) async {
    await _audioPlayerService.seek(event.position);
  }

  Future<void> _onVolume(PlayerVolumeEvent event, Emitter<PlayerState> emit) async {
    await _audioPlayerService.setVolume(event.volume);
  }

  Future<void> _onSetTrack(PlayerSetTrackEvent event, Emitter<PlayerState> emit) async {
    await _audioPlayerService.setQueue([event.track], initialIndex: 0);
    await _audioPlayerService.play();
    emit(PlayerReady(
      currentTrack: event.track,
      currentPosition: Duration.zero,
      totalDuration: event.track.duration,
      isPlaying: true,
      queue: [event.track],
    ));
  }

  Future<void> _onQueueUpdate(PlayerQueueUpdateEvent event, Emitter<PlayerState> emit) async {
    await _audioPlayerService.setQueue(event.queue);
    if (event.queue.isNotEmpty) {
      await _audioPlayerService.play();
      emit(PlayerReady(
        currentTrack: event.queue.first,
        currentPosition: Duration.zero,
        totalDuration: event.queue.first.duration,
        isPlaying: true,
        queue: event.queue,
      ));
    }
  }

  Future<void> _onShuffleToggle(Emitter<PlayerState> emit) async {
    await _audioPlayerService.setShuffleMode(!_audioPlayerService.shuffleMode);
    if (state is PlayerReady) {
      final currentState = state as PlayerReady;
      emit(currentState.copyWith(isShuffling: _audioPlayerService.shuffleMode));
    }
  }

  Future<void> _onRepeatToggle(Emitter<PlayerState> emit) async {
    final currentMode = _audioPlayerService.loopMode;
    LoopMode newMode;
    switch (currentMode) {
      case LoopMode.off:
        newMode = LoopMode.one;
        break;
      case LoopMode.one:
        newMode = LoopMode.all;
        break;
      case LoopMode.all:
        newMode = LoopMode.off;
        break;
    }
    await _audioPlayerService.setLoopMode(newMode);
    if (state is PlayerReady) {
      final currentState = state as PlayerReady;
      emit(currentState.copyWith(repeatMode: newMode));
    }
  }

  @override
  Future<void> close() {
    _audioPlayerService.dispose();
    return super.close();
  }
}