import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:latlong2/latlong.dart' as ll;
import '../../data/models/place_model.dart';
import '../../utils/persistence.dart';

class MapScreen extends StatefulWidget {
  final ll.LatLng? initialLocation;
  const MapScreen({super.key, this.initialLocation});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  List<Place> _places = [];
  bool _isLoading = true;

  final MapController _mapController = MapController();

  // Coordonnée par défaut (France centre)
  static const ll.LatLng _defaultCenter = ll.LatLng(46.5, 2.5);

  @override
  void initState() {
    super.initState();
    // Seed sample places if empty, then load
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Persistence.seedSamplePlacesIfEmpty();
      await _loadPlaces();
    });
  }

  Future<void> _loadPlaces() async {
    setState(() => _isLoading = true);
    final places = await Persistence.loadPlaces();
    setState(() {
      _places = places; // plus de fallback en mémoire
      _isLoading = false;
    });
  }

  void _showPlaceDetails(Place place) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(place.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(place.address),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      await Persistence.removePlace(place.id);
                      Navigator.pop(context);
                      await _loadPlaces();
                    },
                    child: const Text('Supprimer'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Fermer'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Try widget.initialLocation first, then route arguments (RouteSettings.arguments), then fallback
    final routeArg = ModalRoute.of(context)?.settings.arguments;
    final ll.LatLng? argLoc = (routeArg is ll.LatLng) ? routeArg : null;
    final center = widget.initialLocation ?? argLoc ?? (_places.isNotEmpty ? ll.LatLng(_places.first.lat, _places.first.lng) : _defaultCenter);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Carte des sorties"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPlaces,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Carte toujours visible en fond
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: _places.isNotEmpty ? 12 : 5,
              onTap: (_, __) {},
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.example.projet_flutter',
              ),
              if (_places.isNotEmpty)
                MarkerLayer(
                  markers: _places.map((p) {
                    return Marker(
                      point: ll.LatLng(p.lat, p.lng),
                      width: 40,
                      height: 40,
                      child: GestureDetector(
                        onTap: () => _showPlaceDetails(p),
                        child: const Icon(Icons.location_on, size: 40, color: Colors.red),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),

          // Panneau en bas avec les lieux (toujours visible au-dessus de la carte)
          Positioned(
            left: 12,
            right: 12,
            bottom: 16,
            child: SizedBox(
              height: 220,
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${_places.length} lieu${_places.length > 1 ? 'x' : ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          TextButton.icon(
                            onPressed: _loadPlaces,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Rafraîchir'),
                          ),
                          if (widget.initialLocation != null)
                            TextButton.icon(
                              onPressed: () {
                                _mapController.move(widget.initialLocation!, 14);
                              },
                              icon: const Icon(Icons.my_location),
                              label: const Text('Centrer'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      Expanded(
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : _places.isEmpty
                                ? const Center(child: Text('Aucun lieu enregistré'))
                                : ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _places.length,
                                    itemBuilder: (context, index) {
                                      final p = _places[index];
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 8),
                                        child: SizedBox(
                                          width: 260,
                                          child: Card(
                                            child: Padding(
                                              padding: const EdgeInsets.all(8),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(p.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                                  const SizedBox(height: 6),
                                                  Expanded(child: Text(p.address, overflow: TextOverflow.ellipsis, maxLines: 4)),
                                                  const SizedBox(height: 6),
                                                  // Nouvelle ligne: petite vignette de l'image si disponible
                                                  Row(
                                                    children: [
                                                      p.photoUrl != null
                                                          ? ClipRRect(
                                                              borderRadius: BorderRadius.circular(8),
                                                              child: CachedNetworkImage(
                                                                imageUrl: p.photoUrl!,
                                                                width: 80,
                                                                height: 60,
                                                                fit: BoxFit.cover,
                                                                placeholder: (context, url) => Container(
                                                                  width: 80,
                                                                  height: 60,
                                                                  color: Colors.grey[200],
                                                                  child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                                                ),
                                                                errorWidget: (context, url, error) => Container(
                                                                  width: 80,
                                                                  height: 60,
                                                                  color: Colors.grey[300],
                                                                  child: const Icon(Icons.image_not_supported),
                                                                ),
                                                              ),
                                                            )
                                                           : Container(
                                                               width: 80,
                                                               height: 60,
                                                               decoration: BoxDecoration(
                                                                 color: Colors.grey[300],
                                                                 borderRadius: BorderRadius.circular(8),
                                                               ),
                                                               child: const Icon(Icons.place),
                                                             ),
                                                      const Spacer(),
                                                      Row(
                                                        children: [
                                                          IconButton(
                                                            icon: const Icon(Icons.location_on),
                                                            onPressed: () {
                                                              // recentrer la carte sur ce lieu
                                                              _mapController.move(ll.LatLng(p.lat, p.lng), 13);
                                                            },
                                                          ),
                                                          IconButton(
                                                            icon: const Icon(Icons.delete),
                                                            onPressed: () async {
                                                              await Persistence.removePlace(p.id);
                                                              await _loadPlaces();
                                                            },
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
