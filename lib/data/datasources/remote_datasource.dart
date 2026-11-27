abstract class RemoteDataSource {
  Future<List<dynamic>> getTrendingTracks();
  Future<List<dynamic>> searchTracks(String query);
  Future<dynamic> getTrackById(String trackId);
}