import 'package:equatable/equatable.dart';

/// Model for local audio files stored in app
class LocalTrackModel extends Equatable {
  final String id;
  final String originalPath;
  final String fileName;
  final String extension;
  final String title;
  final String artist;
  final String? album;
  final String? artworkPath;
  final Duration duration;
  final DateTime dateAdded;
  final bool isAvailable;
  final String? copiedPath; // Path in app storage if copied

  const LocalTrackModel({
    required this.id,
    required this.originalPath,
    required this.fileName,
    required this.extension,
    required this.title,
    required this.artist,
    this.album,
    this.artworkPath,
    required this.duration,
    required this.dateAdded,
    required this.isAvailable,
    this.copiedPath,
  });

  factory LocalTrackModel.fromJson(Map<String, dynamic> json) {
    return LocalTrackModel(
      id: json['id'] as String,
      originalPath: json['originalPath'] as String,
      fileName: json['fileName'] as String,
      extension: json['extension'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      album: json['album'] as String?,
      artworkPath: json['artworkPath'] as String?,
      duration: Duration(seconds: json['duration'] as int? ?? 0),
      dateAdded: DateTime.parse(json['dateAdded'] as String),
      isAvailable: json['isAvailable'] as bool? ?? false,
      copiedPath: json['copiedPath'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'originalPath': originalPath,
        'fileName': fileName,
        'extension': extension,
        'title': title,
        'artist': artist,
        'album': album,
        'artworkPath': artworkPath,
        'duration': duration.inSeconds,
        'dateAdded': dateAdded.toIso8601String(),
        'isAvailable': isAvailable,
        'copiedPath': copiedPath,
      };

  LocalTrackModel copyWith({
    String? id,
    String? originalPath,
    String? fileName,
    String? extension,
    String? title,
    String? artist,
    String? album,
    String? artworkPath,
    Duration? duration,
    DateTime? dateAdded,
    bool? isAvailable,
    String? copiedPath,
  }) {
    return LocalTrackModel(
      id: id ?? this.id,
      originalPath: originalPath ?? this.originalPath,
      fileName: fileName ?? this.fileName,
      extension: extension ?? this.extension,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      artworkPath: artworkPath ?? this.artworkPath,
      duration: duration ?? this.duration,
      dateAdded: dateAdded ?? this.dateAdded,
      isAvailable: isAvailable ?? this.isAvailable,
      copiedPath: copiedPath ?? this.copiedPath,
    );
  }

  /// Get effective path for playback (prefer copied path if available)
  String get playbackPath => copiedPath ?? originalPath;

  @override
  List<Object?> get props => [
        id,
        originalPath,
        fileName,
        extension,
        title,
        artist,
        album,
        artworkPath,
        duration,
        dateAdded,
        isAvailable,
        copiedPath,
      ];
}