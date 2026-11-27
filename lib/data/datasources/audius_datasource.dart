import 'package:sonora/lib/data/datasources/remote_datasource.dart';
import 'package:sonora/lib/data/models/track_model.dart';

class AudiusDataSource implements RemoteDataSource {
  @override
  Future<List<dynamic>> getTrendingTracks() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return [];
  }

  @override
  Future<List<dynamic>> searchTracks(String query) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return [];
  }

  @override
  Future<dynamic> getTrackById(String trackId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return null;
  }
}