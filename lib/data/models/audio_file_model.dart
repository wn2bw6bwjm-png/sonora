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

  factory AudioFileModel.fromPath(String filePath) async {
    // Use audio_metadata or just basic file info
    // For now, create with basic info
    final file = File(filePath);
    final bytes = await file.length();

    // Try to extract metadata using a simple approach
    final title = _extractTitleFromPath(filePath);
    final artist = 'Unknown Artist';

    // Duration estimation based on file size (rough)
    final estimatedDuration = Duration(
      milliseconds: (bytes / 1024 / 1024 * 5 * 60 * 1000).round(),
    );

    final id = '${filePath.hashCode}';

    return AudioFileModel(
      id: id,
      filePath: filePath,
      title: title,
      artist: artist,
      duration: estimatedDuration,
    );
  }

  static String _extractTitleFromPath(String path) {
    final basename = path.split('/').last.replaceAll('.', ' ');
    // Remove numbers at the beginning
    final cleaned = basename.split(' ').where((w) => RegExp(r'[a-zA-Z]').hasNext(w)).join(' ');
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