import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/local_track_model.dart';

class LocalDataSource {
  static const _uuid = Uuid();
  late final Directory _appStorageDir;

  Future<void> init() async {
    final appDir = await getApplicationDocumentsDirectory();
    _appStorageDir = Directory('${appDir.path}/sonora_music');
    if (!await _appStorageDir.exists()) {
      await _appStorageDir.create(recursive: true);
    }
  }

  /// Pick audio files from device
  Future<List<PlatformFile>> pickAudioFiles({
    bool allowMultiple = true,
    List<String> allowedExtensions = const [
      'mp3',
      'm4a',
      'aac',
      'wav',
      'flac',
      'ogg',
      'opus',
      'wma',
    ],
  }) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
      allowMultiple: allowMultiple,
      withData: false,
      withReadStream: false,
    );
    return result?.files ?? [];
  }

  /// Create local track model from platform file
  Future<LocalTrackModel> createTrackFromFile(PlatformFile file) async {
    final id = _uuid.v4();
    final filePath = file.path ?? '';
    final fileName = file.name;
    final extension = file.extension?.toLowerCase() ?? 'unknown';

    // Extract metadata (placeholder - would use audio_metadata package)
    final title = _extractTitleFromFilename(fileName);
    final artist = 'Unknown Artist';
    final album = 'Unknown Album';
    final duration = Duration.zero; // Would read from metadata

    return LocalTrackModel(
      id: id,
      originalPath: filePath,
      fileName: fileName,
      extension: extension,
      title: title,
      artist: artist,
      album: album,
      duration: duration,
      dateAdded: DateTime.now(),
      isAvailable: await _checkFileExists(filePath),
    );
  }

  /// Check if file exists at path
  Future<bool> _checkFileExists(String path) async {
    if (path.isEmpty) return false;
    return await File(path).exists();
  }

  /// Copy file to app storage for persistence
  Future<String?> copyToAppStorage(PlatformFile file) async {
    if (file.path == null) return null;
    final fileName = '${_uuid.v4()}.${file.extension}';
    final destPath = '${_appStorageDir.path}/$fileName';
    try {
      await File(file.path!).copy(destPath);
      return destPath;
    } catch (e) {
      return null;
    }
  }

  /// Get all tracks from app storage
  Future<List<LocalTrackModel>> getStoredTracks() async {
    if (!await _appStorageDir.exists()) return [];
    final files = await _appStorageDir.list().toList();
    final tracks = <LocalTrackModel>[];
    for (final entity in files) {
      if (entity is File) {
        final ext = entity.path.split('.').last.toLowerCase();
        if (['mp3', 'm4a', 'aac', 'wav', 'flac', 'ogg', 'opus', 'wma'].contains(ext)) {
          final id = _uuid.v4();
          final fileName = entity.path.split('/').last;
          tracks.add(LocalTrackModel(
            id: id,
            originalPath: entity.path,
            fileName: fileName,
            extension: ext,
            title: _extractTitleFromFilename(fileName),
            artist: 'Unknown Artist',
            album: 'Unknown Album',
            duration: Duration.zero,
            dateAdded: DateTime.now(),
            isAvailable: true,
          ));
        }
      }
    }
    return tracks;
  }

  /// Delete stored file
  Future<void> deleteStoredFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // Ignore delete errors
    }
  }

  String _extractTitleFromFilename(String filename) {
    final nameWithoutExt = filename.split('.').first;
    return nameWithoutExt.replaceAll(RegExp(r'[_-]'), ' ').trim();
  }

  Future<Directory> getAppStorageDir() async => _appStorageDir;
}