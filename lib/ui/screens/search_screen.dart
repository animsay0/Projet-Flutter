import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:projet_flutter/data/models/trip.dart';
import '../../data/models/place_model.dart';
import '../../services/place_service.dart';
import '../../utils/persistence.dart';
import 'add_trip_screen.dart';

class SearchScreen extends StatefulWidget {
  final Function(Trip) onAddTrip;
  const SearchScreen({super.key, required this.onAddTrip});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final PlaceService _placeService = PlaceService();
  String? _selectedCountry;
  int _searchRadius = 2000; // en mètres
  bool _isNearbyMode = false; // si true, afficher le sélecteur de rayon

  bool _isLoading = false;
  List<Place> _results = [];

  // Token incremental pour invalider les enrichissements si une nouvelle recherche démarre
  int _searchToken = 0;

  // Debounce
  Timer? _debounce;

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _search();
    });
  }

  Future<void> _search({double? lat, double? lng}) async {
    // toute recherche manuelle annule le mode 'près de moi' (ne pas appliquer le radius global)
    if (_isNearbyMode) setState(() => _isNearbyMode = false);
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    final int currentToken = ++_searchToken;

    try {
      final places = await _placeService.searchPlaces(
        query,
        countryCode: _selectedCountry,
        lat: lat,
        lng: lng,
      );

      // Afficher d'abord les résultats bruts
      setState(() {
        _results = places;
      });

      // Enrichir un nombre limité de places en tâche de fond pour limiter les appels concurrents
      final maxEnrich = min(places.length, 6); // limiter à 6 enrichissements simultanés
      for (var i = 0; i < maxEnrich; i++) {
        final original = places[i];

        // Ajouter un petit délai pour éviter une rafale d'appels
        Future.delayed(Duration(milliseconds: 150 * i), () {
          _placeService.enrichPlace(original).then((enriched) {
            if (!mounted || currentToken != _searchToken) return;

            setState(() {
              final index = _results.indexWhere((p) => p.id == enriched.id);
              if (index != -1) {
                _results[index] = enriched;
              }
            });
          }).catchError((e) {
            // Ne pas bloquer l'UI si l'enrichissement échoue
            print('Erreur enrichissement lieu ${original.id}: $e');
          });
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur lors de la recherche : $e")),
        );
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _searchNearby() async {
    // activer le mode Nearby pour afficher le sélecteur et indiquer le contexte
    if (!_isNearbyMode) setState(() => _isNearbyMode = true);
    bool serviceEnabled;
    LocationPermission permission;

    setState(() => _isLoading = true);

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Activer la localisation pour utiliser "Près de moi"')),
      );
      setState(() => _isLoading = false);
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Autorisation localisation refusée')),
        );
        setState(() => _isLoading = false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Autorisation localisation définitivement refusée')),
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

      // Utiliser Nominatim reverse geocoding pour obtenir le nom du lieu ou ville
      final query = _controller.text.trim().isEmpty ? 'place' : _controller.text.trim();

      // Pour l'instant on appelle searchPlaces simplement (Foursquare/Nominatim fallback) —
      // certaines APIs acceptent lat/lng, mais notre searchPlaces actuel n'envoie pas lat/lng.
      // Si tu veux que la recherche utilise la position, on peut ajuster `searchPlaces` pour accepter lat/lng
      // Ici on fait une simple recherche globale et on informera l'utilisateur.

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Position: ${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}')),
      );

      // Optionnel: pré-remplir le champ recherche
      //_controller.text = query;

      // Appeler la méthode dédiée searchNearby pour récupérer des POI locaux (Overpass puis Nominatim)
      final places = await _placeService.searchNearby(pos.latitude, pos.longitude, countryCode: _selectedCountry, radius: _searchRadius);

      // Afficher les résultats bruts
      if (mounted) {
        setState(() {
          _results = places;
        });
      }

      // Enrichir progressivement (limité) - réutiliser la logique d'enrichissement
      final int currentToken = ++_searchToken;
      final maxEnrich = min(places.length, 6);
      for (var i = 0; i < maxEnrich; i++) {
        final original = places[i];
        Future.delayed(Duration(milliseconds: 150 * i), () {
          _placeService.enrichPlace(original).then((enriched) {
            if (!mounted || currentToken != _searchToken) return;
            setState(() {
              final index = _results.indexWhere((p) => p.id == enriched.id);
              if (index != -1) {
                _results[index] = enriched;
              }
            });
          }).catchError((e) {
            print('Erreur enrichissement lieu ${original.id}: $e');
          });
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur localisation: $e')),
      );
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _selectPlace(Place place) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddTripScreen(place: place, onAddTrip: widget.onAddTrip),
      ),
    );
  }

  Future<void> _savePlace(Place place) async {
    await Persistence.addPlace(place);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lieu sauvegardé')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // plus épuré : pas d'ombre et titre discret
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: const Text("Rechercher un lieu"),
      ),
      body: Column(
        children: [
          _SearchBar(
            controller: _controller,
            onSearch: _search,
            onChanged: _onSearchChanged,
            selectedCountry: _selectedCountry,
            onCountryChanged: (value) {
              setState(() {
                _selectedCountry = value;
              });
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _NearbyButton(
              onPressed: _searchNearby,
            ),
          ),
          // n'afficher le sélecteur de rayon que si l'utilisateur a choisi 'Lieux à proximité'
          if (_isNearbyMode)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _RadiusSelector(
                radius: _searchRadius,
                onChanged: (r) => setState(() => _searchRadius = r),
              ),
            ),
          const _ApiInfoCard(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _ResultsList(
                    results: _results,
                    onTap: _selectPlace,
                    onSave: _savePlace,
                  ),
          ),
        ],
      ),
    );
  }
}

/* ===================== SEARCH BAR ===================== */

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSearch;
  final void Function()? onChanged;
  final String? selectedCountry;
  final ValueChanged<String?> onCountryChanged;

  const _SearchBar({
    required this.controller,
    required this.onSearch,
    required this.onChanged,
    required this.selectedCountry,
    required this.onCountryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recherche : TextField épuré avec icônes
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: (_) => onChanged?.call(),
                  onSubmitted: (_) => onSearch(),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: "Nom du lieu...",
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: controller.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              controller.clear();
                              onChanged?.call();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Bouton search compact
              SizedBox(
                height: 44,
                width: 44,
                child: ElevatedButton(
                  onPressed: onSearch,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Icon(Icons.search),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Chips pour sélectionner France / Monde (plus discret que SegmentedButton)
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('France'),
                selected: selectedCountry == 'FR',
                onSelected: (s) => onCountryChanged(s ? 'FR' : null),
              ),
              ChoiceChip(
                label: const Text('Monde'),
                selected: selectedCountry == null,
                onSelected: (s) => onCountryChanged(s ? null : 'FR'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


/* ===================== NEARBY BUTTON ===================== */

class _NearbyButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _NearbyButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.location_on),
        label: const Text("Près de moi"),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}

/* ===================== API INFO ===================== */

class _ApiInfoCard extends StatelessWidget {
  const _ApiInfoCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.cloud, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Recherche Foursquare • météo OpenWeatherMap',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }
}

/* ===================== RESULTS LIST ===================== */

class _ResultsList extends StatelessWidget {
  final List<Place> results;
  final Function(Place) onTap;
  final Function(Place) onSave;

  const _ResultsList({
    required this.results,
    required this.onTap,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.search_off, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text("Aucun résultat", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: results.length,
      itemBuilder: (context, index) {
        return _PlaceCard(
          place: results[index],
          onTap: onTap,
          onSave: onSave,
        );
      },
    );
  }
}

/* ===================== PLACE CARD ===================== */

class _PlaceCard extends StatelessWidget {
  final Place place;
  final Function(Place) onTap;
  final Function(Place) onSave;

  const _PlaceCard({
    required this.place,
    required this.onTap,
    required this.onSave,
  });

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.place,
        color: Theme.of(context).primaryColor.withOpacity(0.4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Construire le sous-titre de façon conditionnelle
    String subtitle = place.address;
    final List<String> meta = [];
    if (place.weather != null && place.weather!.isNotEmpty) meta.add(place.weather!);
    if (place.temperature != null) meta.add('${place.temperature!.round()}°C');
    if (meta.isNotEmpty) subtitle = '$subtitle\n${meta.join(' • ')}';

    final bool isThreeLine = subtitle.contains('\n');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onTap(place),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Image
              if (place.photoUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: place.photoUrl!,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 64,
                      height: 64,
                      color: Colors.grey[200],
                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 64,
                      height: 64,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image_not_supported),
                    ),
                  ),
                )
              else
                _buildPlaceholder(context),
              const SizedBox(width: 12),
              // Texte
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(place.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Text(subtitle, style: TextStyle(color: Colors.grey[700]), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Actions
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.bookmark_border),
                    onPressed: () => onSave(place),
                    tooltip: 'Sauvegarder',
                  ),
                  const SizedBox(height: 4),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RadiusSelector extends StatelessWidget {
  final int radius;
  final ValueChanged<int> onChanged;

  const _RadiusSelector({required this.radius, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final options = const [500, 2000, 5000];
    return Row(
      children: [
        const Icon(Icons.tune, size: 18, color: Colors.grey),
        const SizedBox(width: 8),
        Text('Rayon', style: TextStyle(color: Colors.grey[700])),
        const SizedBox(width: 12),
        DropdownButton<int>(
          value: radius,
          items: options
              .map((r) => DropdownMenuItem(value: r, child: Text(r >= 1000 ? '${r ~/ 1000} km' : '${r} m')))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
        const Spacer(),
        Text('${radius >= 1000 ? '${radius ~/ 1000} km' : '${radius} m'}', style: TextStyle(color: Colors.grey[600])),
      ],
    );
  }
}
