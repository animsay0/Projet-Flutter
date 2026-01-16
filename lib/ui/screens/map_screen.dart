import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:geolocator/geolocator.dart';
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
  ll.LatLng? _deviceLocation;
  bool _isPanelOpen = false;
  BuildContext? _sheetContext;

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
      await _determineAndSetDeviceLocation();
    });
  }

  Future<void> _determineAndSetDeviceLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return; // location services are not enabled

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
      if (!mounted) return;
      setState(() {
        _deviceLocation = ll.LatLng(pos.latitude, pos.longitude);
      });
      // center map on device location
      _mapController.move(_deviceLocation!, 13);
    } catch (_) {
      // ignore errors retrieving location
    }
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

  // Toggleable panel: opens or closes the places panel. When open, `_sheetContext` keeps the sheet context
  void _openPlacesPanel() {
    if (_isPanelOpen) {
      if (_sheetContext != null) Navigator.pop(_sheetContext!);
      return;
    }

    _isPanelOpen = true;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) {
        // store the sheet context to be able to close it programmatically
        _sheetContext = sheetCtx;
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.42,
          minChildSize: 0.2,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${_places.length} lieu${_places.length > 1 ? 'x' : ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: _loadPlaces,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Rafraîchir'),
                          ),
                          const SizedBox(width: 8),
                        ],
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
                                controller: scrollController,
                                itemCount: _places.length,
                                itemBuilder: (context, index) {
                                  final p = _places[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: InkWell(
                                      onTap: () {
                                        // focus the map on this place without closing the panel
                                        _mapController.move(ll.LatLng(p.lat, p.lng), 13);
                                      },
                                      child: Card(
                                        child: Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(p.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                              const SizedBox(height: 6),
                                              Text(p.address, overflow: TextOverflow.ellipsis, maxLines: 3),
                                              const SizedBox(height: 6),
                                              Row(
                                                children: [
                                                  if (p.photoUrl != null)
                                                    ClipRRect(
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
                                                  else
                                                    Container(
                                                      width: 80,
                                                      height: 60,
                                                      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(8)),
                                                      child: const Icon(Icons.place),
                                                    ),
                                                  const Spacer(),
                                                  Row(
                                                    children: [
                                                      IconButton(
                                                        icon: const Icon(Icons.location_on),
                                                        onPressed: () {
                                                          // focus map (but keep panel open)
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
            );
          },
        );
      },
    ).whenComplete(() {
      // sheet closed (by back or user); reset flags
      _isPanelOpen = false;
      _sheetContext = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Try widget.initialLocation first, then route arguments (RouteSettings.arguments), then fallback
    final routeArg = ModalRoute.of(context)?.settings.arguments;
    final ll.LatLng? argLoc = (routeArg is ll.LatLng) ? routeArg : null;
    final center = widget.initialLocation ?? argLoc ?? _deviceLocation ?? (_places.isNotEmpty ? ll.LatLng(_places.first.lat, _places.first.lng) : _defaultCenter);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Carte des sorties"),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        // refresh removed from top actions (now in panel)
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
              MarkerLayer(
                markers: [
                  // markers for saved places
                  ..._places.map((p) => Marker(
                        point: ll.LatLng(p.lat, p.lng),
                        width: 40,
                        height: 40,
                        child: GestureDetector(
                          onTap: () => _showPlaceDetails(p),
                          child: const Icon(Icons.location_on, size: 40, color: Colors.red),
                        ),
                      )),
                  // marker for the initial location (green) if provided
                  if (widget.initialLocation != null)
                    Marker(
                      point: widget.initialLocation!,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.place, size: 40, color: Colors.green),
                    ),
                  // marker for the device location (blue) if available
                  if (_deviceLocation != null)
                    Marker(
                      point: _deviceLocation!,
                      width: 48,
                      height: 48,
                      child: Tooltip(
                        message: 'Vous êtes ici',
                        child: Container(
                          alignment: Alignment.center,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: Colors.blue.withOpacity(0.35), blurRadius: 12, spreadRadius: 4),
                              ],
                            ),
                            child: const Icon(Icons.circle, size: 6, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                 ],
               ),
             ],
           ),

           // Top pill/banner showing number of places and small chip (UI from mock)
           Positioned(
             top: 12,
             left: 12,
             right: 12,
             child: SafeArea(
               child: Card(
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                 elevation: 4,
                 child: Padding(
                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                   child: Row(
                     children: [
                       const Icon(Icons.navigation, color: Colors.blue),
                       const SizedBox(width: 8),
                       Expanded(child: Text('${_places.length} lieu${_places.length > 1 ? 'x' : ''} sur la carte')),
                       const SizedBox(width: 8),
                       TextButton.icon(
                         onPressed: _loadPlaces,
                         icon: const Icon(Icons.refresh),
                         label: const Text('Rafraîchir'),
                       ),
                       const SizedBox(width: 8),
                       TextButton.icon(
                         onPressed: () async {
                           // If device location is unknown, try to obtain it first
                           if (_deviceLocation == null) {
                             await _determineAndSetDeviceLocation();
                           }
                           if (_deviceLocation != null) {
                             // center on device location
                             _mapController.move(_deviceLocation!, 14);
                           } else {
                             // fallback: dezoom to default center
                             _mapController.move(_defaultCenter, 5);
                           }
                         },
                         icon: const Icon(Icons.my_location),
                         label: const Text('Centrer'),
                       ),
                     ],
                   ),
                 ),
               ),
             ),
           ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openPlacesPanel,
        child: const Icon(Icons.place),
      ),
    );
  }
}
