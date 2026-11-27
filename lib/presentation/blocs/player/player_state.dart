abstract class PlayerState extends Equatable {
  @override
  List<Object> get props => [];

  PlayerState get status => this;
}

class PlayerInitial extends PlayerState {
  @override
  List<Object> get props => [];
}

class PlayerLoading extends PlayerState {
  @override
  List<Object> get props => [];
}

class PlayerReady extends PlayerState {
  final Track currentTrack;
  final Duration currentPosition;
  final Duration totalDuration;
  final bool isPlaying;
  final RepeatMode repeatMode;
  final bool isShuffling;
  final List<Track> queue;
  final int? repeatIndex; // Which track in queue is repeating

  PlayerReady({
    required this.currentTrack,
    required this.currentPosition,
    required this.totalDuration,
    required this.isPlaying,
    this.repeatMode = RepeatMode.off,
    this.isShuffling = false,
    required this.queue,
    this.repeatIndex,
  });

  @override
  List<Object> get props =>
      [currentTrack, currentPosition, totalDuration, isPlaying, repeatMode, isShuffling, queue, repeatIndex];
}

class PlayerQueueUpdate extends PlayerState {
  final List<Track> queue;
  final int? removedIndex;
  final bool? added;
  final Track? addedTrack;

  PlayerQueueUpdate({
    required this.queue,
    this.removedIndex,
    this.added,
    this.addedTrack,
  });

  @override
  List<Object> get props => [queue, removedIndex, added, addedTrack];
}

class PlayerError extends PlayerState {
  final String message;

  PlayerError(this.message);

  @override
  List<Object> get props => [message];
}

class PlayerRepeatModeChanged extends PlayerState {
  final RepeatMode mode;

  PlayerRepeatModeChanged(this.mode);

  @override
  List<Object> get props => [mode];
}

enum RepeatMode { off, one, all }