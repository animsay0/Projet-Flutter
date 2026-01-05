import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
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

  Future<void> _search() async {
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
      );

      // Afficher d'abord les résultats bruts
      setState(() {
        _results = places;
      });

      // Enrichir chaque place en tâche de fond et mettre à jour progressivement
      for (var i = 0; i < places.length; i++) {
        final original = places[i];

        // Lancer l'enrichissement sans attendre les autres
        _placeService.enrichPlace(original).then((enriched) {
          // Si un nouveau token a été émis, ignorer cette mise à jour
          if (!mounted || currentToken != _searchToken) return;

          setState(() {
            // Remplacer l'élément correspondant (si présent)
            final index = _results.indexWhere((p) => p.id == enriched.id);
            if (index != -1) {
              _results[index] = enriched;
            }
          });
        }).catchError((e) {
          // Ne pas bloquer l'UI si l'enrichissement échoue
          print('Erreur enrichissement lieu ${original.id}: $e');
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

      // Optionnel: on peut pré-remplir le champ recherche et lancer la recherche
      _controller.text = query;
      await _search();
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
          _NearbyButton(
            onPressed: _searchNearby,
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
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: (_) => onChanged?.call(),
                  onSubmitted: (_) => onSearch(),
                  decoration: InputDecoration(
                    hintText: "Nom du lieu...",
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: onSearch,
                child: const Text("OK"),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SegmentedButton<String?>(
            segments: const [
              ButtonSegment(
                value: 'FR',
                label: Text("France"),
                icon: Icon(Icons.flag),
              ),
              ButtonSegment(
                value: null,
                label: Text("Monde"),
                icon: Icon(Icons.public),
              ),
            ],
            selected: {selectedCountry},
            onSelectionChanged: (value) {
              onCountryChanged(value.first);
            },
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.location_on),
          label: const Text("Lieux à proximité"),
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
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.cloud, size: 18),
          const SizedBox(width: 8),
          const Expanded(child: Text('Recherche Foursquare + météo OpenWeatherMap')),
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
      return const Center(
        child: Text("Aucun résultat"),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
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
      color: Theme.of(context).primaryColor.withOpacity(0.1),
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
      child: ListTile(
        onTap: () => onTap(place),
        leading: place.photoUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  place.photoUrl!,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildPlaceholder(context),
                ),
              )
            : _buildPlaceholder(context),
        title: Text(place.name),
        subtitle: Text(subtitle),
        isThreeLine: isThreeLine,
        trailing: IconButton(
          icon: const Icon(Icons.bookmark_border),
          onPressed: () => onSave(place),
          tooltip: "Sauvegarder le lieu",
        ),
      ),
    );
  }
}
