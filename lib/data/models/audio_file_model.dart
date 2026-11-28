class AudioFileModel {
  final String id;
  final String filePath;
  final String title;
  final String artist;
  final Duration duration;
  final String? coverArtPath;

  AudioFileModel({
    required this.id,
    required this.filePath,
    required this.title,
    required this.artist,
    required this.duration,
    this.coverArtPath,
  });

  factory AudioFileModel.fromPath(String filePath) {
    final title = _extractTitleFromPath(filePath);

    return AudioFileModel(
      id: filePath.hashCode.toString(),
      filePath: filePath,
      title: title,
      artist: 'Unknown Artist',
      duration: Duration.zero,
    );
  }

  static String _extractTitleFromPath(String path) {
    final basename = path.split('/').last.replaceAll('.', ' ');
    final cleaned = basename.split(' ').where((w) => RegExp(r'[a-zA-Z]').hasMatch(w)).join(' ');
    return cleaned.isEmpty ? 'Audio File' : cleaned.trim();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'filePath': filePath,
        'title': title,
        'artist': artist,
        'duration': duration.inSeconds,
        'coverArtPath': coverArtPath,
      };

  factory AudioFileModel.fromJson(Map<String, dynamic> json) {
    return AudioFileModel(
      id: json['id'] as String,
      filePath: json['filePath'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      duration: Duration(seconds: json['duration'] as int? ?? 0),
      coverArtPath: json['coverArtPath'] as String?,
    );
  }
}