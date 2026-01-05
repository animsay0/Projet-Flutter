import 'dart:convert';
import 'package:http/http.dart' as http;
import '../data/models/place_model.dart';

class PlaceService {
  static const String _serviceKey =
      'NTC113TRV2OR14JLI50VNYY0URAOE4NDL4F3AP2K1H0PAR2S';

  static const String _weatherApiKey =
      '495085d1742ca1c53601a24d0a66977e';

  // Version Foursquare au format YYYYMMDD (requise par l'API)
  static const String _placesApiVersion = '20250617';

  static const Map<String, String> _headers = {
    'Accept': 'application/json',
    'Authorization': 'Bearer $_serviceKey',
    'X-Places-Api-Version': '2025-06-17',
  };

  /// 🔍 Autocomplete avec filtre pays corrigé
  /// Utilise Foursquare si possible, sinon fallback vers Nominatim (OpenStreetMap)
  Future<List<Place>> searchPlaces(
      String query, {
        String? countryCode,
      }) async {
    final params = {
      'query': query,
      'limit': '20',
      'v': _placesApiVersion, // Ajout de la version exigée par l'API
    };

    if (countryCode != null) {
      params['countries'] = countryCode;
    }

    final uri = Uri.https(
      'places-api.foursquare.com',
      'places/search',
      params,
    );

    print('🔍 Recherche: $query ${countryCode != null ? "dans $countryCode" : "mondial"}');
    print('📍 URL: $uri');

    try {
      final response = await http.get(uri, headers: _headers);

      if (response.statusCode != 200) {
        print('Foursquare returned ${response.statusCode}: ${response.body}');
        // Fallback vers Nominatim
        return await _searchNominatim(query, countryCode: countryCode);
      }

      final data = jsonDecode(response.body);
      final List results = data['results'] ?? [];

      print('✅ ${results.length} résultats trouvés (Foursquare)');

      return results.map<Place>((place) {
        final location = place['geocodes']?['main'];

        return Place(
          id: place['fsq_place_id'],
          name: place['name'],
          address: place['location']?['formatted_address'] ?? '',
          lat: location?['latitude'] ?? 0.0,
          lng: location?['longitude'] ?? 0.0,
          photoUrl: null,
          weather: null,
          temperature: null,
        );
      }).toList();
    } catch (e) {
      print('Erreur recherche Foursquare: $e — fallback vers Nominatim');
      return await _searchNominatim(query, countryCode: countryCode);
    }
  }

  /// Fallback: recherche via Nominatim (OpenStreetMap) — sans clé API
  Future<List<Place>> _searchNominatim(String query, {String? countryCode}) async {
    final params = {
      'q': query,
      'format': 'json',
      'limit': '20',
    };

    if (countryCode != null) {
      // Nominatim attend des codes pays en minuscules, séparés par ',' si plusieurs
      params['countrycodes'] = countryCode.toLowerCase();
    }

    final uri = Uri.https('nominatim.openstreetmap.org', '/search', params);

    print('Fallback Nominatim URL: $uri');

    try {
      final response = await http.get(uri, headers: {
        'User-Agent': 'Projet-Flutter/1.0 (contact: dev@example.com)'
      });

      if (response.statusCode != 200) {
        print('Nominatim error ${response.statusCode}: ${response.body}');
        return [];
      }

      final List data = jsonDecode(response.body) as List;

      print('✅ ${data.length} résultats trouvés (Nominatim)');

      return data.map<Place>((place) {
        final lat = double.tryParse(place['lat']?.toString() ?? '') ?? 0.0;
        final lon = double.tryParse(place['lon']?.toString() ?? '') ?? 0.0;
        final osmId = place['osm_id']?.toString() ?? '';
        final osmType = place['osm_type']?.toString() ?? '';

        return Place(
          id: 'nominatim_${osmId}_$osmType',
          name: place['display_name'] ?? 'Lieu',
          address: place['display_name'] ?? '',
          lat: lat,
          lng: lon,
          photoUrl: null,
          weather: null,
          temperature: null,
        );
      }).toList();
    } catch (e) {
      print('Erreur Nominatim: $e');
      return [];
    }
  }

  /// 🌤 OpenWeatherMap
  Future<Map<String, dynamic>> _getWeather(
      double lat,
      double lng,
      ) async {
    final uri = Uri.parse(
      'https://api.openweathermap.org/data/2.5/weather'
          '?lat=$lat&lon=$lng'
          '&units=metric'
          '&appid=$_weatherApiKey',
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      return {
        'temp': null,
        'description': null,
      };
    }

    final data = jsonDecode(response.body);

    return {
      'temp': data['main']['temp'],
      'description': data['weather'][0]['main'],
    };
  }


  Future<Place> getPlaceDetails(String fsqPlaceId) async {
    final uri = Uri.https(
      'places-api.foursquare.com',
      'places/$fsqPlaceId',
      {
        'v': _placesApiVersion,
      },
    );

    print('Fetching details for place ID: $fsqPlaceId (URL: $uri)');

    final response = await http.get(uri, headers: _headers);

    if (response.statusCode != 200) {
      throw Exception('Erreur détails lieu ${response.statusCode} - ${response.body}');
    }

    final data = jsonDecode(response.body);

    String? photoUrl;
    if (data['photos'] != null && data['photos'].isNotEmpty) {
      final photo = data['photos'][0];
      photoUrl = "${photo['prefix']}original${photo['suffix']}";
    }

    final location = data['geocodes']?['main'];

    return Place(
      id: data['fsq_place_id'],
      name: data['name'],
      address: data['location']?['formatted_address'] ?? '',
      lat: location?['latitude'] ?? 0.0,
      lng: location?['longitude'] ?? 0.0,
      photoUrl: photoUrl,
      weather: null,
      temperature: null,
    );
  }

  /// Enrich a Place with photo and weather information.
  /// Retourne un nouvel objet Place avec les champs `photoUrl`, `weather` et `temperature` remplis si disponibles.
  Future<Place> enrichPlace(Place place) async {
    try {
      // Récupérer les détails (photo + coordonnées précises)
      final details = await getPlaceDetails(place.id);

      // Récupérer la météo basée sur les coordonnées des détails
      final weatherData = await _getWeather(details.lat, details.lng);

      return Place(
        id: details.id,
        name: details.name,
        address: details.address,
        lat: details.lat,
        lng: details.lng,
        photoUrl: details.photoUrl,
        weather: weatherData['description'] as String?,
        temperature: (weatherData['temp'] is num) ? (weatherData['temp'] as num).toDouble() : null,
      );
    } catch (e) {
      print('Erreur lors de l\'enrichissement du lieu ${place.id}: $e');
      // En cas d'erreur, retourner l'objet initial sans bloquer l'affichage
      return place;
    }
  }
}