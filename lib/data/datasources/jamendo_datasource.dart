class JamendoDataSource {
  Future<List<Map<String, dynamic>>> getTrendingTracks() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return [];
  }

  Future<List<Map<String, dynamic>>> searchTracks(String query) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return [];
  }

  Future<Map<String, dynamic>?> getTrackById(String trackId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return null;
  }
}