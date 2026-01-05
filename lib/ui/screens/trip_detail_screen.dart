import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:projet_flutter/ui/screens/map_screen.dart';
import '../../data/models/trip.dart';

class TripDetailScreen extends StatefulWidget {
  final Trip trip;

  const TripDetailScreen({
    super.key,
    required this.trip,
  });

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _photos = [];

  Future<void> _pickImageFromCamera() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (file != null) {
      setState(() => _photos.add(file));
    }
  }

  Future<void> _pickImageFromGallery() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file != null) {
      setState(() => _photos.add(file));
    }
  }

  Future<void> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permission de localisation refusée')));
      return;
    }

    final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    // Ouvrir la MapScreen centrée sur la position courante
    Navigator.push(context, MaterialPageRoute(builder: (_) => MapScreen(initialLocation: ll.LatLng(pos.latitude, pos.longitude))));
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: CustomScrollView(
        slivers: [
          _Header(trip: trip),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _QuickInfo(trip: trip),
                  const SizedBox(height: 16),
                  if (trip.gpsCoordinates != null)
                    _GpsCard(trip: trip),
                  const SizedBox(height: 16),

                  // CAMERA & GALLERY ACTIONS
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Photos & localisation', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Row(children: [
                            ElevatedButton.icon(
                              onPressed: _pickImageFromCamera,
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('Prendre photo'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: _pickImageFromGallery,
                              icon: const Icon(Icons.photo_library),
                              label: const Text('Choisir'),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: _getCurrentLocation,
                              icon: const Icon(Icons.my_location),
                              label: const Text('Ma position'),
                            ),
                          ]),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 90,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemBuilder: (_, i) {
                                final file = _photos[i];
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(File(file.path), width: 120, height: 80, fit: BoxFit.cover),
                                );
                              },
                              separatorBuilder: (_, __) => const SizedBox(width: 8),
                              itemCount: _photos.length,
                            ),
                          )
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  _WeatherCard(trip: trip),
                  if (trip.notes != null) ...[
                    const SizedBox(height: 16),
                    _NotesCard(notes: trip.notes!),
                  ],
                  const SizedBox(height: 16),
                  const _PlaceInfoCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _Header extends StatelessWidget {
  final Trip trip;

  const _Header({required this.trip});

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      color: Theme.of(context).primaryColor.withOpacity(0.1),
      child: Center(
        child: Icon(
          Icons.landscape_rounded,
          size: 100,
          color: Theme.of(context).primaryColor.withOpacity(0.4),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      backgroundColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.favorite_border, color: Colors.white),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.share, color: Colors.white),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.white),
          onPressed: () {},
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Hero(
              tag: 'trip-${trip.id}',
              child: Image.network(
                trip.imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return _buildPlaceholder(context);
                },
                errorBuilder: (context, __, ___) =>
                    _buildPlaceholder(context),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color.fromRGBO(0, 0, 0, 0.6),
                    Colors.transparent,
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trip.title,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _Stars(rating: trip.rating),
                      const SizedBox(width: 8),
                      Text(
                        "(${trip.rating}/5)",
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const Spacer(),
                      _WeatherBadge(
                        weather: trip.weather,
                        temperature: trip.temperature,
                      ),
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}



class _Stars extends StatelessWidget {
  final int rating;

  const _Stars({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        5,
            (index) => Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 20,
        ),
      ),
    );
  }
}

class _WeatherBadge extends StatelessWidget {
  final String weather;
  final String temperature;

  const _WeatherBadge({
    required this.weather,
    required this.temperature,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        "$weather $temperature",
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}


class _QuickInfo extends StatelessWidget {
  final Trip trip;

  const _QuickInfo({required this.trip});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _InfoTile(
          icon: Icons.place,
          label: "Lieu",
          value: trip.location,
        ),
        const SizedBox(width: 12),
        _InfoTile(
          icon: Icons.calendar_today,
          label: "Date",
          value: trip.date,
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: const Color(0xFF4F46E5)),
              const SizedBox(height: 8),
              Text(label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



class _GpsCard extends StatelessWidget {
  final Trip trip;

  const _GpsCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Coordonnées GPS",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(trip.gpsCoordinates!),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  // plus tard → MapScreen
                },
                child: const Text("Voir sur la carte"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}



class _WeatherCard extends StatelessWidget {
  final Trip trip;

  const _WeatherCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFFF7ED),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Text(trip.weather, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${trip.temperature} • Météo du jour",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Source: OpenWeatherMap",
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}



class _NotesCard extends StatelessWidget {
  final String notes;

  const _NotesCard({required this.notes});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Mes Notes",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(notes),
          ],
        ),
      ),
    );
  }
}



class _PlaceInfoCard extends StatelessWidget {
  const _PlaceInfoCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFF5F3FF),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              "Informations du lieu",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text("Type : Site naturel"),
            Text("Popularité : ★★★★★"),
            Text("Avis : 3890+ avis"),
            SizedBox(height: 8),
            Text(
              "Données Foursquare Places API",
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF4F46E5),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
