import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../models/search_result.dart';

class SearchService {
  static const String _baseUrl = 'https://nominatim.openstreetmap.org';
  static const String _userAgent = 'DeFlock/1.0 (OSM surveillance mapping app)';
  static const int _maxResults = 5;
  static const Duration _timeout = Duration(seconds: 10);
  
  /// Search for places using Nominatim geocoding service
  Future<List<SearchResult>> search(String query) async {
    if (query.trim().isEmpty) {
      return [];
    }
    
    // Check if query looks like coordinates first
    final coordResult = _tryParseCoordinates(query.trim());
    if (coordResult != null) {
      return [coordResult];
    }
    
    // Otherwise, use Nominatim API
    return await _searchNominatim(query.trim());
  }
  
  /// Try to parse various coordinate formats
  SearchResult? _tryParseCoordinates(String query) {
    // Remove common separators and normalize
    final normalized = query.replaceAll(RegExp(r'[,;]'), ' ').trim();
    final parts = normalized.split(RegExp(r'\s+'));
    
    if (parts.length != 2) return null;
    
    final lat = double.tryParse(parts[0]);
    final lon = double.tryParse(parts[1]);
    
    if (lat == null || lon == null) return null;
    
    // Basic validation for Earth coordinates
    if (lat < -90 || lat > 90 || lon < -180 || lon > 180) return null;
    
    return SearchResult(
      displayName: 'Coordinates: ${lat.toStringAsFixed(6)}, ${lon.toStringAsFixed(6)}',
      coordinates: LatLng(lat, lon),
      category: 'coordinates',
      type: 'point',
    );
  }
  
  /// Search using Nominatim API
  Future<List<SearchResult>> _searchNominatim(String query) async {
    final uri = Uri.parse('$_baseUrl/search').replace(queryParameters: {
      'q': query,
      'format': 'json',
      'limit': _maxResults.toString(),
      'addressdetails': '1',
      'extratags': '1',
    });
    
    debugPrint('[SearchService] Searching Nominatim: $uri');
    
    try {
      final response = await http.get(
        uri,
        headers: {
          'User-Agent': _userAgent,
        },
      ).timeout(_timeout);
      
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
      
      final List<dynamic> jsonResults = json.decode(response.body);
      final results = jsonResults
          .map((json) => SearchResult.fromNominatim(json as Map<String, dynamic>))
          .toList();
      
      debugPrint('[SearchService] Found ${results.length} results');
      return results;
      
    } catch (e) {
      debugPrint('[SearchService] Search failed: $e');
      throw Exception('Search failed: $e');
    }
  }
}