import 'package:equatable/equatable.dart';
import 'package:sonora/domain/entities/track.dart';

enum RepeatMode { off, one, all }
extension RepeatModeExtension on RepeatMode {
  String get label {
    switch (this) {
      case RepeatMode.off:
        return 'off';
      case RepeatMode.one:
        return 'one';
      case RepeatMode.all:
        return 'all';
    }
  }
}

abstract class PlayerState extends Equatable {
  const PlayerState();

  @override
  List<Object?> get props => [];

  PlayerState get status => this;
}

class PlayerInitial extends PlayerState {}

class PlayerLoading extends PlayerState {}

class PlayerReady extends PlayerState {
  final Track currentTrack;
  final Duration currentPosition;
  final Duration totalDuration;
  final bool isPlaying;
  final RepeatMode repeatMode;
  final bool isShuffling;
  final List<Track> queue;

  const PlayerReady({
    required this.currentTrack,
    required this.currentPosition,
    required this.totalDuration,
    required this.isPlaying,
    this.repeatMode = RepeatMode.off,
    this.isShuffling = false,
    required this.queue,
  });

  PlayerReady copyWith({
    Track? currentTrack,
    Duration? currentPosition,
    Duration? totalDuration,
    bool? isPlaying,
    RepeatMode? repeatMode,
    bool? isShuffling,
    List<Track>? queue,
  }) {
    return PlayerReady(
      currentTrack: currentTrack ?? this.currentTrack,
      currentPosition: currentPosition ?? this.currentPosition,
      totalDuration: totalDuration ?? this.totalDuration,
      isPlaying: isPlaying ?? this.isPlaying,
      repeatMode: repeatMode ?? this.repeatMode,
      isShuffling: isShuffling ?? this.isShuffling,
      queue: queue ?? this.queue,
    );
  }

  @override
  List<Object?> get props => [
        currentTrack,
        currentPosition,
        totalDuration,
        isPlaying,
        repeatMode,
        isShuffling,
        queue,
      ];
}

class PlayerQueueUpdate extends PlayerState {
  final List<Track> queue;

  const PlayerQueueUpdate({required this.queue});

  @override
  List<Object?> get props => [queue];
}

class PlayerError extends PlayerState {
  final String message;

  const PlayerError(this.message);

  @override
  List<Object?> get props => [message];
}