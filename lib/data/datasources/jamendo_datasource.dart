class JamendoDataSource implements RemoteDataSource {
  @override
  Future<List<TrackModel>> getTrendingTracks() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return [];
  }

  @override
  Future<List<TrackModel>> searchTracks(String query) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return [];
  }

  @override
  Future<TrackModel?> getTrackById(String trackId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return null;
  }
}