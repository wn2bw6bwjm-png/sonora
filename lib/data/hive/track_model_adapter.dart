import 'package:hive_flutter/hive_flutter.dart';
import 'package:sonora/lib/data/models/track_model.dart';

class TrackModelAdapter extends TypeAdapter<TrackModel> {
  @override
  final int typeId = 1;

  @override
  TrackModel read(Reader reader) {
    final Map<String, dynamic> map = reader.readMap();
    return TrackModel.fromJson(map);
  }

  @override
  void write(Writer writer, TrackModel obj) {
    writer.writeMap(obj.toJson());
  }
}