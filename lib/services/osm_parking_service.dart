import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class OsmParking {
  OsmParking({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  final String id;
  final String name;
  final double latitude;
  final double longitude;
}

class OsmParkingService {
  OsmParkingService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const _overpassHosts = [
    'overpass-api.de',
    'overpass.kumi.systems',
    'overpass.openstreetmap.ru',
    'overpass.openstreetmap.fr',
  ];

  Future<List<OsmParking>> fetchNearby({
    required double latitude,
    required double longitude,
    int radiusMeters = 1000,
  }) async {
    final query =
        '[out:json];node["amenity"="parking"](around:$radiusMeters,$latitude,$longitude);out;';
    Exception? lastError;

    for (final host in _overpassHosts) {
      final uri = Uri.https(host, '/api/interpreter');
      try {
        final response = await _client
            .post(
              uri,
              headers: const {
                'Content-Type': 'application/x-www-form-urlencoded',
                'User-Agent': 'smartparkapp/1.0',
              },
              body: {'data': query},
            )
            .timeout(const Duration(seconds: 15));
        if (response.statusCode < 200 || response.statusCode >= 300) {
          lastError = Exception(
            'Failed to fetch nearby parking: ${response.statusCode}',
          );
          continue;
        }

        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final elements = (data['elements'] as List<dynamic>? ?? []);

        return elements.map((element) {
          final item = element as Map<String, dynamic>;
          final tags = item['tags'] as Map<String, dynamic>? ?? {};
          return OsmParking(
            id: item['id'].toString(),
            name: tags['name']?.toString() ?? 'Public parking',
            latitude: (item['lat'] as num).toDouble(),
            longitude: (item['lon'] as num).toDouble(),
          );
        }).toList();
      } catch (e) {
        lastError = Exception('Failed to fetch nearby parking: $e');
      }
    }

    throw lastError ?? Exception('Failed to fetch nearby parking');
  }
}
