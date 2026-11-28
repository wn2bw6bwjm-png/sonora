import 'package:equatable/equatable.dart';
import 'package:sonora/domain/entities/track.dart';

abstract class PlayerEvent extends Equatable {
  const PlayerEvent();

  @override
  List<Object?> get props => [];
}

class PlayerPlayPauseEvent extends PlayerEvent {}

class PlayerNextTrackEvent extends PlayerEvent {}

class PlayerPreviousTrackEvent extends PlayerEvent {}

class PlayerSeekEvent extends PlayerEvent {
  final Duration position;

  const PlayerSeekEvent(this.position);

  @override
  List<Object?> get props => [position];
}

class PlayerVolumeEvent extends PlayerEvent {
  final double volume;

  const PlayerVolumeEvent(this.volume);

  @override
  List<Object?> get props => [volume];
}

class PlayerSetTrackEvent extends PlayerEvent {
  final Track track;

  const PlayerSetTrackEvent(this.track);

  @override
  List<Object?> get props => [track];
}

class PlayerQueueUpdateEvent extends PlayerEvent {
  final List<Track> queue;

  const PlayerQueueUpdateEvent(this.queue);

  @override
  List<Object?> get props => [queue];
}

class PlayerShuffleToggleEvent extends PlayerEvent {}

class PlayerRepeatToggleEvent extends PlayerEvent {}