import 'package:sonora/data/models/audio_file_model.dart';

abstract class AudioFileRepository {
  Future<AudioFileModel?> pickAudioFile();
  List<AudioFileModel> getLocalFiles();
  Future<void> deleteFile(String filePath);
}

class AudioFileRepositoryImpl implements AudioFileRepository {
  @override
  Future<AudioFileModel?> pickAudioFile() async {
    // Local file picker integration requires file_picker package (not yet added).
    return null;
  }

  @override
  List<AudioFileModel> getLocalFiles() {
    return [];
  }

  @override
  Future<void> deleteFile(String filePath) {
    return Future.value();
  }
}