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

  // Correction: utiliser la même forme que le paramètre 'v' ou supprimer l'en-tête
  static const Map<String, String> _headers = {
    'Accept': 'application/json',
    'Authorization': 'Bearer $_serviceKey',
    'X-Places-Api-Version': _placesApiVersion,
  };

  /// 🔍 Autocomplete avec filtre pays corrigé
  /// Utilise Foursquare si possible, sinon fallback vers Nominatim (OpenStreetMap)
  Future<List<Place>> searchPlaces(
      String query, {
        String? countryCode,
        double? lat,
        double? lng,
      }) async {
    final params = {
      'query': query,
      'limit': '20',
      'v': _placesApiVersion, // Ajout de la version exigée par l'API
    };

    if (countryCode != null) {
      params['countries'] = countryCode;
    }

    // Si des coordonnées sont fournies, ajouter un paramètre 'll' pour Foursquare (lat,lng)
    if (lat != null && lng != null) {
      params['ll'] = '$lat,$lng';
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
        // Si on a des coordonnées, essayer d'abord Overpass pour des POI locaux
        if (lat != null && lng != null) {
          final over = await _searchOverpass(lat, lng);
          if (over.isNotEmpty) return over;
        }
        return await _searchNominatim(query, countryCode: countryCode, lat: lat, lng: lng);
      }

      final data = jsonDecode(response.body);
      final List results = data['results'] ?? [];

      print('✅ ${results.length} résultats trouvés (Foursquare)');

      // Si Foursquare n'a rien et qu'on a des coordonnées, tenter Overpass
      if (results.isEmpty && lat != null && lng != null) {
        final over = await _searchOverpass(lat, lng);
        if (over.isNotEmpty) return over;
      }

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
      if (lat != null && lng != null) {
        final over = await _searchOverpass(lat, lng);
        if (over.isNotEmpty) return over;
      }
      return await _searchNominatim(query, countryCode: countryCode, lat: lat, lng: lng);
    }
  }

  /// Fallback: recherche via Nominatim (OpenStreetMap) — sans clé API
  Future<List<Place>> _searchNominatim(String query, {String? countryCode, double? lat, double? lng}) async {
    final params = {
      'q': query,
      'format': 'json',
      'limit': '20',
    };

    if (countryCode != null) {
      // Nominatim attend des codes pays en minuscules, séparés par ',' si plusieurs
      params['countrycodes'] = countryCode.toLowerCase();
    }

    // Si des coordonnées sont fournies, utiliser une viewbox limitée pour les recherches
    if (lat != null && lng != null) {
      // viewbox format: left_lon, top_lat, right_lon, bottom_lat
      params['viewbox'] = '${lng - 0.1},${lat + 0.1},${lng + 0.1},${lat - 0.1}';
      params['bounded'] = '1';
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

  /// Recherche POI via Overpass API (OpenStreetMap) autour des coordonnées fournies.
  /// Recherches les tags tourism, amenity, historic, leisure, shop dans un rayon et retourne des Place.
  Future<List<Place>> _searchOverpass(double lat, double lng, {int radius = 2000, int limit = 20}) async {
    // Endpoints Overpass (fallback list)
    final endpoints = [
      Uri.parse('https://overpass-api.de/api/interpreter'),
      Uri.parse('https://lz4.overpass-api.de/api/interpreter'),
      Uri.parse('https://overpass.kumi.systems/api/interpreter'),
    ];

    // Requête Overpass valide (utilise nwr pour node/way/relation)
    final query = '''[out:json][timeout:25];
(
  nwr(around:$radius,$lat,$lng)[tourism];
  nwr(around:$radius,$lat,$lng)[amenity];
  nwr(around:$radius,$lat,$lng)[historic];
  nwr(around:$radius,$lat,$lng)[leisure];
  nwr(around:$radius,$lat,$lng)[shop];
);
out center;''';

    try {
      http.Response? resp;
      for (final endpoint in endpoints) {
        // 1) essayer POST
        try {
          resp = await http.post(endpoint,
                  headers: {
                    'User-Agent': 'Projet-Flutter/1.0 (contact: dev@example.com)',
                    'Accept': 'application/json'
                  },
                  body: query)
              .timeout(const Duration(seconds: 15));
          print('Overpass POST $endpoint -> status ${resp.statusCode}');
        } catch (e) {
          print('Overpass POST failed for $endpoint: $e');
          resp = null;
        }

        // 2) si POST a échoué ou renvoyé non-200, tenter GET avec param 'data'
        if (resp == null || resp.statusCode != 200) {
          try {
            final getUri = Uri.parse(endpoint.toString() + '?data=' + Uri.encodeComponent(query));
            final getResp = await http.get(getUri, headers: {
              'User-Agent': 'Projet-Flutter/1.0 (contact: dev@example.com)',
              'Accept': 'application/json'
            }).timeout(const Duration(seconds: 15));
            resp = getResp;
            print('Overpass GET ${endpoint} -> status ${resp.statusCode}');
          } catch (e) {
            print('Overpass GET failed for $endpoint: $e');
            resp = null;
          }
        }

        if (resp != null && resp.statusCode == 200) {
          print('Overpass: successful response from $endpoint');
          break;
        }
      }

      if (resp == null) {
        print('Overpass: aucune réponse valide des endpoints');
        return [];
      }
      if (resp.statusCode != 200) {
        print('Overpass returned ${resp.statusCode}: ${resp.body}');
        return [];
      }

      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final List elements = data['elements'] ?? [];
      final results = <Place>[];
      for (final e in elements) {
        final Map<String, dynamic> tags = (e['tags'] is Map) ? Map<String, dynamic>.from(e['tags']) : {};
        final name = tags['name']?.toString() ?? tags['official_name']?.toString() ?? '';
        if (name.isEmpty) continue;

        double plat = 0.0, plng = 0.0;
        if (e['type'] == 'node') {
          plat = (e['lat'] is num) ? (e['lat'] as num).toDouble() : 0.0;
          plng = (e['lon'] is num) ? (e['lon'] as num).toDouble() : 0.0;
        } else if (e['type'] == 'way' && e['center'] != null) {
          plat = (e['center']['lat'] is num) ? (e['center']['lat'] as num).toDouble() : 0.0;
          plng = (e['center']['lon'] is num) ? (e['center']['lon'] as num).toDouble() : 0.0;
        }

        final id = 'overpass_${e['id']}_${e['type']}';

        // Construire une adresse si possible
        final addressParts = <String>[];
        if (tags['addr:street'] != null) addressParts.add(tags['addr:street']);
        if (tags['addr:city'] != null) addressParts.add(tags['addr:city']);
        final address = addressParts.join(', ');

        results.add(Place(
          id: id,
          name: name,
          address: address,
          lat: plat,
          lng: plng,
          photoUrl: null,
          weather: null,
          temperature: null,
        ));
        if (results.length >= limit) break;
      }

      // limiter côté Dart
      final limited = results.take(limit).toList();
      print('✅ ${limited.length} résultats trouvés (Overpass)');
      return limited;
    } catch (e) {
      print('Erreur Overpass: $e');
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

  /// Recherche une image sur Wikipedia/Wikimedia pour un terme donné.
  /// Si `lat`/`lng` fournis, tente aussi une recherche par coordonnées (geosearch).
  /// Retourne l'URL de l'image si trouvée, sinon null.
  Future<String?> _fetchImageFromWikimedia(String query, {double? lat, double? lng}) async {
    try {
      // Nettoyer le terme de recherche : si c'est une longue adresse, prendre la première partie avant la virgule
      final shortQuery = query.split(',').first.trim();

      // Prioriser Commons puis la version française, puis anglaise
      final hosts = ['commons.wikimedia.org', 'fr.wikipedia.org', 'en.wikipedia.org'];

      // Headers pour éviter que certaines API bloquent la requête
      final headers = {
        'User-Agent': 'Projet-Flutter/1.0 (contact: dev@example.com)'
      };

      // Helper: retry wrapper
      Future<http.Response?> _getWithRetry(Uri uri, {int retries = 2}) async {
        for (var attempt = 0; attempt <= retries; attempt++) {
          try {
            final resp = await http.get(uri, headers: headers).timeout(const Duration(seconds: 8));
            return resp;
          } catch (e) {
            if (attempt == retries) return null;
            await Future.delayed(Duration(milliseconds: 300 * (attempt + 1)));
          }
        }
        return null;
      }

      // 1a) Tentative via l'API REST v1 (plus CORS-friendly) : /w/rest.php/v1/search/page
      for (final host in hosts) {
        for (final q in [shortQuery, query]) {
          try {
            final restSearchUri = Uri.https(host, '/w/rest.php/v1/search/page', {'q': q, 'limit': '5'});
            final restResp = await _getWithRetry(restSearchUri);
            if (restResp != null && restResp.statusCode == 200) {
              try {
                final restData = jsonDecode(restResp.body) as Map<String, dynamic>;
                if (restData['pages'] != null) {
                  final List pages = restData['pages'] as List;
                  for (final page in pages) {
                    final key = (page['key'] ?? page['title'] ?? '').toString();
                    if (key.isEmpty) continue;
                    final summaryUri = Uri.https(host, '/api/rest_v1/page/summary/$key', {'redirect': 'true'});
                    final sumResp = await _getWithRetry(summaryUri);
                    if (sumResp == null || sumResp.statusCode != 200) continue;
                    try {
                      final sumData = jsonDecode(sumResp.body) as Map<String, dynamic>;
                      if (sumData['originalimage'] != null && sumData['originalimage']['source'] != null) {
                        return sumData['originalimage']['source'] as String;
                      }
                      if (sumData['thumbnail'] != null && sumData['thumbnail']['source'] != null) {
                        return sumData['thumbnail']['source'] as String;
                      }
                    } catch (e) {
                      // ignore parse
                    }
                  }
                }
              } catch (e) {
                // ignore parse
              }
            }
          } catch (e) {
            // ignore host/q
          }
        }
      }

      // 1b) Méthode principale : generator search + pageimages
      for (final host in hosts) {
        for (final q in [shortQuery, query]) {
          final params = {
            'action': 'query',
            'format': 'json',
            'generator': 'search',
            'gsrsearch': q,
            'gsrlimit': '5',
            'prop': 'pageimages',
            'piprop': 'original',
            'origin': '*',
          };

          final uri = Uri.https(host, '/w/api.php', params);
          final resp = await _getWithRetry(uri);
          if (resp == null || resp.statusCode != 200) continue;

          try {
            final data = jsonDecode(resp.body) as Map<String, dynamic>;
            if (data['query'] != null && data['query']['pages'] != null) {
              final pages = data['query']['pages'] as Map<String, dynamic>;
              for (final entry in pages.entries) {
                final page = entry.value as Map<String, dynamic>;
                if (page['original'] != null && page['original']['source'] != null) {
                  return page['original']['source'] as String;
                }
              }
            }
          } catch (e) {
            // ignore parse errors for this host/q
          }
        }
      }

      // 2) Si on a des coordonnées, tenter une recherche par proximité (geosearch)
      if (lat != null && lng != null) {
        for (final host in hosts) {
          final params = {
            'action': 'query',
            'list': 'geosearch',
            'gscoord': '${lat.toString()}|${lng.toString()}',
            'gsradius': '5000',
            'gslimit': '10',
            'format': 'json',
            'origin': '*',
          };

          final uri = Uri.https(host, '/w/api.php', params);
          final resp = await _getWithRetry(uri);
          if (resp == null || resp.statusCode != 200) continue;

          try {
            final data = jsonDecode(resp.body) as Map<String, dynamic>;
            if (data['query'] != null && data['query']['geosearch'] != null) {
              final List<dynamic> geolist = data['query']['geosearch'] as List<dynamic>;
              for (final g in geolist) {
                final title = (g['title'] as String).replaceAll(' ', '_');
                final summaryUri = Uri.https(host, '/api/rest_v1/page/summary/$title', {'redirect': 'true'});
                final sumResp = await _getWithRetry(summaryUri);
                if (sumResp == null || sumResp.statusCode != 200) continue;
                try {
                  final sumData = jsonDecode(sumResp.body) as Map<String, dynamic>;
                  if (sumData['originalimage'] != null && sumData['originalimage']['source'] != null) {
                    return sumData['originalimage']['source'] as String;
                  }
                  if (sumData['thumbnail'] != null && sumData['thumbnail']['source'] != null) {
                    return sumData['thumbnail']['source'] as String;
                  }
                } catch (e) {
                  // ignore parse
                }
              }
            }
          } catch (e) {
            // ignore parse
          }
        }
      }

      // 3) Fallback : utiliser opensearch pour récupérer des titres puis page/summary pour avoir un thumbnail
      for (final host in hosts) {
        for (final q in [shortQuery, query]) {
          final opensearchParams = {
            'action': 'opensearch',
            'search': q,
            'limit': '5',
            'format': 'json',
            'origin': '*',
          };

          final opensearchUri = Uri.https(host, '/w/api.php', opensearchParams);
          final opResp = await _getWithRetry(opensearchUri);
          if (opResp == null || opResp.statusCode != 200) continue;

          try {
            final opData = jsonDecode(opResp.body) as List<dynamic>;
            if (opData.length >= 2) {
              final List<dynamic> titles = opData[1] as List<dynamic>;
              for (final t in titles) {
                final title = (t as String)
                    .replaceAll(' ', '_');
                final summaryUri = Uri.https(host, '/api/rest_v1/page/summary/$title', {'redirect': 'true'});
                final sumResp = await _getWithRetry(summaryUri);
                if (sumResp == null || sumResp.statusCode != 200) continue;
                try {
                  final sumData = jsonDecode(sumResp.body) as Map<String, dynamic>;
                  // Try originalimage then thumbnail
                  if (sumData['originalimage'] != null && sumData['originalimage']['source'] != null) {
                    return sumData['originalimage']['source'] as String;
                  }
                  if (sumData['thumbnail'] != null && sumData['thumbnail']['source'] != null) {
                    return sumData['thumbnail']['source'] as String;
                  }
                } catch (e) {
                  // ignore parse
                }
              }
            }
          } catch (e) {
            // ignore parse
          }
        }
      }

      // Enfin, fallback générique (loremflickr fournit une image libre sans clé API)
      final fallback = 'https://loremflickr.com/320/240/${Uri.encodeComponent(shortQuery)}';
      print('Wikimedia: aucun résultat, fallback image: $fallback');
      return fallback;
    } catch (e) {
      print('Erreur Wikimedia générale: $e');
      return null;
    }
  }

  /// Enrich a Place with photo and weather information.
  /// Retourne un nouvel objet Place avec les champs `photoUrl`, `weather` et `temperature` remplis si disponibles.
  Future<Place> enrichPlace(Place place) async {
    try {
      // Si l'ID provient de Nominatim, ne pas appeler l'API Foursquare (elle échouera)
      if (place.id.startsWith('nominatim_')) {
        final photo = await _fetchImageFromWikimedia(place.name, lat: place.lat, lng: place.lng);
        final weatherData = await _getWeather(place.lat, place.lng);

        return Place(
          id: place.id,
          name: place.name,
          address: place.address,
          lat: place.lat,
          lng: place.lng,
          photoUrl: photo,
          weather: weatherData['description'] as String?,
          temperature: (weatherData['temp'] is num) ? (weatherData['temp'] as num).toDouble() : null,
        );
      }

      // Récupérer les détails (photo + coordonnées précises) via Foursquare
      final details = await getPlaceDetails(place.id);

      // Récupérer la météo basée sur les coordonnées des détails
      final weatherData = await _getWeather(details.lat, details.lng);

      // Si aucune photo depuis Foursquare, essayer Wikimedia avec le nom renvoyé
      String? photo = details.photoUrl;
      if (photo == null) {
        photo = await _fetchImageFromWikimedia(details.name, lat: details.lat, lng: details.lng);
      }

      return Place(
        id: details.id,
        name: details.name,
        address: details.address,
        lat: details.lat,
        lng: details.lng,
        photoUrl: photo,
        weather: weatherData['description'] as String?,
        temperature: (weatherData['temp'] is num) ? (weatherData['temp'] as num).toDouble() : null,
      );
    } catch (e) {
      //print('Erreur lors de l\\'enrichissement du lieu ${place.id}: $e');
      // En cas d'erreur, retourner l'objet initial sans bloquer l'affichage
      return place;
    }
  }

  /// Recherche de lieux autour des coordonnées fournies — priorise Overpass (POI) puis Nominatim.
  Future<List<Place>> searchNearby(double lat, double lng, {String? countryCode, int radius = 2000, int limit = 20}) async {
    try {
      // Essayer plusieurs rayons si aucun résultat (plus robuste pour zones peu dense)
      final radii = [radius, 5000, 10000];
      for (final r in radii) {
        final over = await _searchOverpass(lat, lng, radius: r, limit: limit);
        print('searchNearby: tried Overpass radius=$r -> ${over.length} results');
        if (over.isNotEmpty) return over;
      }

      // 1) Recherche par mots-clés localisés (Nominatim dans une petite viewbox)
      final keywords = ['château', 'parc', 'musée', 'monument', 'église', 'restaurant', 'jardin'];
      final kwResults = await _searchNominatimKeywords(keywords, lat, lng, countryCode: countryCode, limit: limit);
      print('searchNearby: keyword Nominatim fallback -> ${kwResults.length} results');
      if (kwResults.isNotEmpty) return kwResults;

      // 2) Si rien, tenter un reverse geocode pour obtenir le nom de commune et rechercher cette commune (peut renvoyer POI)
      final rev = await _reverseNominatim(lat, lng);
      if (rev != null) {
        final String? city = rev['address']?['city'] ?? rev['address']?['town'] ?? rev['address']?['village'] ?? rev['address']?['county'];
        if (city != null && city.isNotEmpty) {
          final nomCity = await _searchNominatim(city, countryCode: countryCode, lat: lat, lng: lng);
          print('searchNearby: reverse Nominatim search for "$city" -> ${nomCity.length} results');
          if (nomCity.isNotEmpty) return nomCity;
        }
      }

      // 3) Dernier recours : recherche Nominatim générique dans la viewbox autour des coords (terme 'place')
      final fallback = await _searchNominatim('place', countryCode: countryCode, lat: lat, lng: lng);
      print('searchNearby: final Nominatim fallback -> ${fallback.length} results');
      if (fallback.isNotEmpty) return fallback;

      print('searchNearby: aucun POI trouvé pour coords ($lat,$lng)');
      return [];
    } catch (e) {
      print('Erreur searchNearby: $e');
      return [];
    }
  }

  /// Reverse geocode Nominatim pour obtenir la ville / boundingbox autour des coordonnées
  Future<Map<String, dynamic>?> _reverseNominatim(double lat, double lng) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
      'format': 'jsonv2',
      'lat': lat.toString(),
      'lon': lng.toString(),
      'zoom': '10',
      'addressdetails': '1',
    });

    try {
      final resp = await http.get(uri, headers: {'User-Agent': 'Projet-Flutter/1.0 (contact: dev@example.com)'}).timeout(const Duration(seconds: 8));
      if (resp.statusCode != 200) return null;
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      return data;
    } catch (e) {
      print('Reverse Nominatim error: $e');
      return null;
    }
  }

  /// Recherche Nominatim par mot-clé limitée à une viewbox
  Future<List<Place>> _searchNominatimKeywords(List<String> keywords, double lat, double lng, {String? countryCode, int limit = 20}) async {
    // calculer viewbox small around coords (approx 0.05 deg ~ 5km)
    final double delta = 0.05;
    final left = lng - delta;
    final top = lat + delta;
    final right = lng + delta;
    final bottom = lat - delta;

    final results = <Place>[];
    for (final kw in keywords) {
      final params = {
        'q': kw,
        'format': 'json',
        'limit': '10',
        'viewbox': '$left,$top,$right,$bottom',
        'bounded': '1',
      };
      if (countryCode != null) params['countrycodes'] = countryCode.toLowerCase();

      final uri = Uri.https('nominatim.openstreetmap.org', '/search', params);
      try {
        final resp = await http.get(uri, headers: {'User-Agent': 'Projet-Flutter/1.0 (contact: dev@example.com)'}).timeout(const Duration(seconds: 8));
        if (resp.statusCode != 200) continue;
        final List data = jsonDecode(resp.body) as List;
        for (final place in data) {
          final plat = double.tryParse(place['lat']?.toString() ?? '') ?? 0.0;
          final plng = double.tryParse(place['lon']?.toString() ?? '') ?? 0.0;
          final osmId = place['osm_id']?.toString() ?? '';
          final osmType = place['osm_type']?.toString() ?? '';
          final name = place['display_name'] ?? kw;

          results.add(Place(
            id: 'nominatim_${osmId}_$osmType',
            name: name,
            address: place['display_name'] ?? '',
            lat: plat,
            lng: plng,
            photoUrl: null,
            weather: null,
            temperature: null,
          ));
          if (results.length >= limit) break;
        }
        if (results.length >= limit) break;
      } catch (e) {
        print('Keyword Nominatim search error for "$kw": $e');
        continue;
      }
    }

    // dedupe by coordinates
    final seen = <String>{};
    final deduped = <Place>[];
    for (final r in results) {
      final key = '${r.lat}:${r.lng}:${r.name}';
      if (seen.contains(key)) continue;
      seen.add(key);
      deduped.add(r);
      if (deduped.length >= limit) break;
    }
    print('Keyword Nominatim aggregated results: ${deduped.length}');
    return deduped;
  }
}


