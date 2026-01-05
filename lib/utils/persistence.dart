import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/place_model.dart';

class Persistence {
  static const String _keySavedPlaces = 'saved_places_v1';
  static const String _keySeedFlag = 'saved_places_seed_v1';

  static Future<List<Place>> loadPlaces() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keySavedPlaces);
    if (raw == null) return [];
    try {
      final List data = jsonDecode(raw) as List;
      return data.map<Place>((e) => Place.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (e) {
      print('Erreur parsing saved places: $e');
      return [];
    }
  }

  static Future<void> savePlaces(List<Place> places) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(places.map((p) => p.toJson()).toList());
    await prefs.setString(_keySavedPlaces, raw);
  }

  static Future<void> addPlace(Place place) async {
    final places = await loadPlaces();
    // ne pas dupliquer
    if (places.any((p) => p.id == place.id)) return;
    places.add(place);
    await savePlaces(places);
  }

  static Future<void> removePlace(String id) async {
    final places = await loadPlaces();
    places.removeWhere((p) => p.id == id);
    await savePlaces(places);
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySavedPlaces);
    await prefs.remove(_keySeedFlag);
  }

  /// Seed deux lieux d'exemple si la persistence est vide (utilisé une seule fois)
  static Future<void> seedSamplePlacesIfEmpty() async {
    final prefs = await SharedPreferences.getInstance();
    final seeded = prefs.getBool(_keySeedFlag) ?? false;
    final existing = await loadPlaces();
    if (seeded || existing.isNotEmpty) return;

    final samples = [
      Place(
        id: 'sample_mont_blanc',
        name: 'Mont Blanc',
        address: 'Chamonix',
        lat: 45.8326,
        lng: 6.8652,
        photoUrl: 'https://images.unsplash.com/photo-1713959989861-2425c95e9777?q=80&w=1080',
        weather: '☀️',
        temperature: 18.0,
      ),
      Place(
        id: 'sample_annecy',
        name: 'Lac d\'Annecy',
        address: 'Annecy',
        lat: 45.8992,
        lng: 6.1296,
        photoUrl: 'https://images.unsplash.com/photo-1501785888041-af3ef285b470?q=80&w=1080',
        weather: '🌤️',
        temperature: 22.0,
      ),
    ];

    await savePlaces(samples);
    await prefs.setBool(_keySeedFlag, true);
  }
}
