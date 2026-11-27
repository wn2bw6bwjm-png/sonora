import 'package:dio/dio.dart';
import '../models/track_model.dart';

class ITunesDataSource {
  final Dio _dio = Dio();

  /// Поиск треков через iTunes Search API (бесплатный официальный API Apple)
  Future<List<TrackModel>> searchTracks(String query) async {
    try {
      final response = await _dio.get(
        'https://itunes.apple.com/search',
        queryParameters: {
          'term': query,
          'country': 'US',
          'media': 'music',
          'limit': 20,
        },
      );
      final List<dynamic> results = response.data['results'] ?? [];
      return results.map((json) => TrackModel.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<TrackModel>> getTrendingTracks() async {
    try {
      final response = await _dio.get(
        'https://itunes.apple.com/search',
        queryParameters: {
          'term': 'music',
          'country': 'US',
          'media': 'music',
          'limit': 20,
        },
      );
      final List<dynamic> results = response.data['results'] ?? [];
      return results.map((json) => TrackModel.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<TrackModel?> getTrackById(String trackId) async {
    try {
      final response = await _dio.get(
        '/lookup',
        queryParameters: {
          'id': trackId,
          'entity': 'track',
          'limit': 1,
        },
      );
      final List<dynamic> results = response.data['results'] ?? [];
      if (results.isNotEmpty) {
        return TrackModel.fromJson(results.first);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}