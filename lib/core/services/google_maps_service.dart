import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class CacheEntry {
  final dynamic data;
  final DateTime expiry;
  CacheEntry(this.data, this.expiry);
  bool get isExpired => DateTime.now().isAfter(expiry);
}

class GoogleMapsServiceException implements Exception {
  final String message;
  GoogleMapsServiceException(this.message);
  @override
  String toString() => 'GoogleMapsServiceException: $message';
}

class GoogleMapsService {
  static const String _attributionHeader = 'X-Goog-Api-Client';
  static const String _attributionValue = 'gmp_git_agentskills_v1';
  
  static final Map<String, CacheEntry> _cache = {};

  static String get apiKey {
    final key = dotenv.env['GOOGLE_MAPS_API_KEY'];
    if (key == null || key.isEmpty) {
      throw GoogleMapsServiceException('GOOGLE_MAPS_API_KEY is not set in .env');
    }
    return key;
  }

  /// Sends an authenticated GET request to a Google Maps Platform REST API endpoint.
  /// Supports caching with a TTL to prevent redundant network requests.
  static Future<dynamic> get(
    String url, {
    Map<String, String>? queryParameters,
    Duration cacheTtl = const Duration(minutes: 30),
    bool useCache = true,
  }) async {
    final uri = Uri.parse(url).replace(queryParameters: {
      ...?queryParameters,
      'key': apiKey,
    });

    final cacheKey = uri.toString();

    if (useCache && _cache.containsKey(cacheKey)) {
      final entry = _cache[cacheKey]!;
      if (!entry.isExpired) {
        return entry.data;
      } else {
        _cache.remove(cacheKey);
      }
    }

    try {
      final response = await http.get(uri, headers: {
        _attributionHeader: _attributionValue,
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Cache the successful response
        if (useCache) {
          _cache[cacheKey] = CacheEntry(
            data,
            DateTime.now().add(cacheTtl),
          );
          
          // Basic LRU cleanup (if cache gets too large)
          if (_cache.length > 100) {
            _cache.remove(_cache.keys.first);
          }
        }
        
        return data;
      } else {
        throw GoogleMapsServiceException('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw GoogleMapsServiceException('Failed to fetch from Google Maps API: $e');
    }
  }

  /// Sends an authenticated POST request to a Google Maps Platform REST API endpoint.
  static Future<dynamic> post(
    String url, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse(url);

    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': apiKey,
          _attributionHeader: _attributionValue,
          ...?headers,
        },
        body: body != null ? json.encode(body) : null,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw GoogleMapsServiceException('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw GoogleMapsServiceException('Failed to post to Google Maps API: $e');
    }
  }
}
