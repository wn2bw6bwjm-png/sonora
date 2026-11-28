import 'package:http/http.dart' as http;
import 'dart:convert';

class AudiusDataSource {
  final String apiBaseUrl = 'https://api.audius.co/v1';
  final String? apiKey; // Optional API key for higher rate limits
  final String? userId; // Optional user ID for context-specific responses

  AudiusDataSource({this.apiKey, this.userId});

  Uri _uri(String path, Map<String, String> params) {
    return Uri.https('api.audius.co', '/v1$path', {
      ...params,
      if (userId != null) 'user_id': userId!,
    });
  }

  /// Search tracks across Audius
  Future<List<Map<String, dynamic>>> searchTracks({
    required String query,
    int offset = 0,
    int limit = 10,
    String? genre,
    String? mood,
    String? sortMethod,
    bool onlyDownloadable = false,
  }) async {
    final params = {
      'query': query,
      'offset': offset.toString(),
      'limit': limit.toString(),
      if (genre != null) 'genre[]': genre,
      if (mood != null) 'mood[]': mood,
      if (sortMethod != null) 'sort_method': sortMethod,
      if (onlyDownloadable) 'only_downloadable': 'true',
    };

    final uri = _uri('/tracks/search', params);

    try {
      final response = await _httpGet(uri, headers: {
        'Accept': 'application/json',
        if (apiKey != null) 'Authorization': 'Bearer $apiKey',
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final tracks = data['data'] as List<dynamic>?;
        return tracks?.cast<Map<String, dynamic>>() ?? [];
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required for Audius API');
      } else if (response.statusCode == 429) {
        throw Exception('Rate limit exceeded. Please wait and retry.');
      } else {
        throw Exception('Failed to search tracks: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to search Audius: $e');
    }
  }

  /// Get trending tracks from Audius
  Future<List<Map<String, dynamic>>> getTrendingTracks({
    int offset = 0,
    int limit = 100,
    String time = 'week',
    String? genre,
  }) async {
    final uri = _uri('/tracks/trending', {
      'offset': offset.toString(),
      'limit': limit.toString(),
      'time': time,
      if (genre != null) 'genre': genre,
    });

    try {
      final response = await _httpGet(uri, headers: {
        'Accept': 'application/json',
        if (apiKey != null) 'Authorization': 'Bearer $apiKey',
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final tracks = data['data'] as List<dynamic>?;
        return tracks?.cast<Map<String, dynamic>>() ?? [];
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required for Audius API');
      } else if (response.statusCode == 429) {
        throw Exception('Rate limit exceeded. Please wait and retry.');
      } else {
        throw Exception('Failed to load trending tracks: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load trending from Audius: $e');
    }
  }

  /// Get track by ID from Audius
  Future<Map<String, dynamic>?> getTrackById(String trackId) async {
    final uri = _uri('/tracks/$trackId', {});

    try {
      final response = await _httpGet(uri, headers: {
        'Accept': 'application/json',
        if (apiKey != null) 'Authorization': 'Bearer $apiKey',
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final track = data['data'] as Map<String, dynamic>?;
        return track;
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required for Audius API');
      } else if (response.statusCode == 404) {
        throw Exception('Track $trackId not found');
      } else if (response.statusCode == 429) {
        throw Exception('Rate limit exceeded. Please wait and retry.');
      } else {
        throw Exception('Failed to load track $trackId: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load Audius track: $e');
    }
  }

  /// Helper method for HTTP GET with error handling
  Future<http.Response> _httpGet(Uri uri, {Map<String, String>? headers}) async {
    return await http.get(uri, headers: headers ?? {});
  }
}