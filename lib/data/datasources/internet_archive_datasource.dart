import 'package:dio/dio.dart';
import '../models/track_model.dart';

class InternetArchiveDataSource {
  final Dio _dio = Dio();

  /// Поиск в Internet Archive (archive.org)
  /// Доступно: все записи с mediatype:audio, чья лицензия позволяет бесплатное использование
  Future<List<TrackModel>> searchTracks(String query) async {
    try {
      final response = await _dio.get(
        'http://archive.org/search.json',
        queryParameters: {
          'q': query,
          'mediatype': 'audio',
          'rows': 20,
          'sort': 'downloads',
          'sort_order': 'desc',
        },
      );
      final List<dynamic> docs = response.data['response']?['docs'] ?? [];
      return docs.map((json) => TrackModel.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<TrackModel>> getTrendingTracks() async {
    try {
      final response = await _dio.get(
        'http://archive.org/search.json',
        queryParameters: {
          'and[]': ['mediatype:audio', 'collection:music'],
          'sort': 'downloads',
          'sort_order': 'desc',
          'rows': 20,
        },
      );
      final List<dynamic> docs = response.data['response']?['docs'] ?? [];
      return docs.map((json) => TrackModel.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }
}