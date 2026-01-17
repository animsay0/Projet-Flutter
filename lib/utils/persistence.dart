import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/place_model.dart';

class Persistence {
  static const String _keySavedPlaces = 'saved_places_v1';
  static const String _keySeedFlag = 'saved_places_seed_v1';

  // Stream broadcast pour notifier les changements de la liste des lieux
  // On émet la liste complète pour éviter d'avoir à recharger depuis l'UI.
  static final StreamController<List<Place>> _onPlacesChanged = StreamController<List<Place>>.broadcast();
  static Stream<List<Place>> get onPlacesChanged => _onPlacesChanged.stream;

  static void _notifyChange() {
    loadPlaces().then((places) {
      try {
        if (!_onPlacesChanged.isClosed) _onPlacesChanged.add(places);
      } catch (_) {
        // ignore
      }
    }).catchError((_) {
      // ignore errors when notifying
    });
  }

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
    _notifyChange();
  }

  static Future<void> addPlace(Place place) async {
    final places = await loadPlaces();
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
    _notifyChange();
  }

  /// Seed deux lieux d'exemple si la persistence est vide
  static Future<void> seedSamplePlacesIfEmpty() async {
    return;
  }
}
