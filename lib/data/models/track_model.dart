import 'package:sonora/domain/entities/track.dart';

class TrackModel {
  final String id;
  final String sourceId;
  final String title;
  final String artist;
  final String? album;
  final String? coverUrl;
  final Duration duration;
  final String? streamUrl;
  final String sourceName;
  final String availabilityType;
  final Map<String, dynamic>? licenseInfo;

  TrackModel({
    required this.id,
    required this.sourceId,
    required this.title,
    required this.artist,
    this.album,
    this.coverUrl,
    required this.duration,
    this.streamUrl,
    required this.sourceName,
    required this.availabilityType,
    this.licenseInfo,
  });

  factory TrackModel.fromJson(Map<String, dynamic> json) {
    return TrackModel(
      id: json['id'] as String,
      sourceId: json['source_id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      album: json['album'] as String?,
      coverUrl: json['cover_url'] as String?,
      duration: Duration(seconds: json['duration'] as int? ?? 0),
      streamUrl: json['stream_url'] as String?,
      sourceName: json['source_name'] as String,
      availabilityType: json['availability_type'] as String,
      licenseInfo: json['license_info'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'source_id': sourceId,
        'title': title,
        'artist': artist,
        'album': album,
        'cover_url': coverUrl,
        'duration': duration.inSeconds,
        'stream_url': streamUrl,
        'source_name': sourceName,
        'availability_type': availabilityType,
        'license_info': licenseInfo,
      };

  Track toEntity() => Track(
        id: id,
        sourceId: sourceId,
        title: title,
        artist: artist,
        album: album,
        coverUrl: coverUrl,
        duration: duration,
        streamUrl: streamUrl,
        sourceName: sourceName,
        availabilityType: availabilityType,
        licenseInfo: licenseInfo,
      );

  factory TrackModel.fromEntity(Track track) => TrackModel(
        id: track.id,
        sourceId: track.sourceId,
        title: track.title,
        artist: track.artist,
        album: track.album,
        coverUrl: track.coverUrl,
        duration: track.duration,
        streamUrl: track.streamUrl,
        sourceName: track.sourceName,
        availabilityType: track.availabilityType,
        licenseInfo: track.licenseInfo,
      );
}