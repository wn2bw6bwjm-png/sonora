import 'package:file_picker/file_picker.dart';
import 'package:sonora/lib/data/models/audio_file_model.dart';

abstract class AudioFileRepository {
  Future<AudioFileModel?> pickAudioFile();
  List<AudioFileModel> getLocalFiles();
  Future<void> deleteFile(String filePath);
}

class AudioFileRepositoryImpl implements AudioFileRepository {
  @override
  Future<AudioFileModel?> pickAudioFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
    );

    if (result == null || result.files.single.path == null) {
      return null;
    }

    final filePath = result.files.single.path!;
    return AudioFileModel.fromPath(filePath);
  }

  @override
  List<AudioFileModel> getLocalFiles() {
    // In a real implementation, would scan a specific directory
    // For now, return empty list
    return [];
  }

  @override
  Future<void> deleteFile(String filePath) {
    // Implementation would delete the file
    return Future.value();
  }
}