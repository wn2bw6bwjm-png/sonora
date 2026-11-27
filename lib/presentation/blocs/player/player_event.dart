abstract class PlayerEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class PlayerPlayPauseEvent extends PlayerEvent {}

class PlayerNextTrackEvent extends PlayerEvent {}

class PlayerPreviousTrackEvent extends PlayerEvent {}

class PlayerSeekEvent extends PlayerEvent {
  final Duration position;

  PlayerSeekEvent(this.position);

  @override
  List<Object> get props => [position];
}

class PlayerVolumeEvent extends PlayerEvent {
  final double volume;

  PlayerVolumeEvent(this.volume);

  @override
  List<Object> get props => [volume];
}

class PlayerSetTrackEvent extends PlayerEvent {
  final Track track;

  PlayerSetTrackEvent(this.track);

  @override
  List<Object> get props => [track];
}

class PlayerQueueUpdateEvent extends PlayerEvent {
  final List<Track> queue;
  final int? removedIndex;
  final bool? added;
  final Track? addedTrack;

  PlayerQueueUpdateEvent(this.queue, {this.removedIndex, this.added, this.addedTrack});

  @override
  List<Object> get props => [queue, removedIndex, added, addedTrack];
}

class PlayerRepeatModeChangedEvent extends PlayerEvent {
  final RepeatMode mode;

  PlayerRepeatModeChangedEvent(this.mode);

  @override
  List<Object> get props => [mode];
}

class PlayerShuffleToggleEvent extends PlayerEvent {}