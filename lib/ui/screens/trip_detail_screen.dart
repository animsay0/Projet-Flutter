import 'dart:io';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../data/models/trip.dart';
import 'add_trip_screen.dart';

class TripDetailScreen extends StatefulWidget {
  final Trip trip;
  final Function(int) onDeleteTrip;
  final Function(Trip) onUpdateTrip; // new callback to propagate updates

  const TripDetailScreen({
    super.key,
    required this.trip,
    required this.onDeleteTrip,
    required this.onUpdateTrip,
  });

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  late Trip _trip;

  @override
  void initState() {
    super.initState();
    _trip = widget.trip;
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Supprimer la sortie ?"),
          content: const Text("Cette action est irréversible."),
          actions: <Widget>[
            TextButton(
              child: const Text("Annuler"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text("Supprimer", style: TextStyle(color: Colors.red)),
              onPressed: () {
                widget.onDeleteTrip(_trip.id);
                Navigator.of(context).pop(); // Close the dialog
                Navigator.of(context).pop(); // Go back to the home screen
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _openEdit() async {
    // Push AddTripScreen in 'edit' mode by passing the existing trip and a onUpdateTrip callback
    final result = await Navigator.of(context).push<Trip>(
      MaterialPageRoute(builder: (_) => AddTripScreen(
        trip: _trip,
        onAddTrip: (_) {}, // keep compatibility; not used in edit mode
        onUpdateTrip: (updated) {}, // not used here; we'll catch result via pop
      )),
    );

    // If the edit screen returned an updated Trip, update local state and propagate
    if (result != null) {
      setState(() {
        _trip = result;
      });
      widget.onUpdateTrip(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: CustomScrollView(
        slivers: [
          _Header(trip: _trip, onDelete: () => _showDeleteConfirmation(context), onEdit: _openEdit),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _QuickInfo(trip: _trip),
                  const SizedBox(height: 16),
                  if (_trip.imageUrls.isNotEmpty) _PhotosCard(imageUrls: _trip.imageUrls),
                  const SizedBox(height: 16),
                  // Weather card: only show if we have weather information
                  if (_trip.weather.isNotEmpty) _WeatherCard(trip: _trip),
                  if (_trip.notes != null) ...[
                    const SizedBox(height: 16),
                    _NotesCard(notes: _trip.notes!),
                  ],
                  const SizedBox(height: 16),
                  // Place info removed
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _Header extends StatefulWidget {
  final Trip trip;
  final VoidCallback onDelete;
  final VoidCallback? onEdit;

  const _Header({required this.trip, required this.onDelete, this.onEdit});

  @override
  State<_Header> createState() => _HeaderState();
}

class _HeaderState extends State<_Header> {
  // PageView carousel removed: we only show a single cover image now.

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      color: Theme.of(context).primaryColor.withAlpha((0.1 * 255).round()),
      child: Center(
        child: Icon(
          Icons.landscape_rounded,
          size: 100,
          color: Theme.of(context).primaryColor.withAlpha((0.4 * 255).round()),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget imageWidget() {
      final url = widget.trip.imageUrls.isNotEmpty ? widget.trip.imageUrls.first : '';
      if (url.isEmpty) return _buildPlaceholder(context);
      if (url.startsWith('http')) return Image.network(url, fit: BoxFit.cover);
      if (url.startsWith('data:image/')) {
        try {
          final bytes = base64Decode(url.split(',')[1]);
          return Image.memory(bytes, fit: BoxFit.cover);
        } catch (_) {
          return _buildPlaceholder(context);
        }
      }
      if (kIsWeb) return _buildPlaceholder(context);
      return Image.file(File(url), fit: BoxFit.cover);
    }

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
        // Edit button added
        if (widget.onEdit != null)
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: widget.onEdit,
          ),
        IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.white),
          onPressed: widget.onDelete,
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Hero(
              tag: 'trip-${widget.trip.id}',
              child: imageWidget(),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withAlpha((0.6 * 255).round()),
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
                    widget.trip.title,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _Stars(rating: widget.trip.rating),
                      const SizedBox(width: 8),
                      Text(
                        "(${widget.trip.rating}/5)",
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const Spacer(),
                      // Show weather badge only if we have weather info
                      if (widget.trip.weather.isNotEmpty)
                        _WeatherBadge(
                          weather: widget.trip.weather,
                          temperature: widget.trip.temperature,
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
    // Utiliser IntrinsicHeight pour que les tuiles prennent la même hauteur
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
      ),
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
        // style unifié pour toutes les cards : coins arrondis et ombre discrète
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 1,
        child: ConstrainedBox(
          // garder une hauteur minimum mais autoriser l'expansion si le contenu dépasse
          constraints: const BoxConstraints(minHeight: 110),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // centrer verticalement le contenu
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: const Color(0xFF4F46E5)),
                const SizedBox(height: 8),
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 6),
                // permettre l'expansion verticale mais tronquer raisonnablement
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: SizedBox(
        width: double.infinity,
        child: ConstrainedBox(
          // hauteur minimum, autoriser l'expansion si nécessaire
          constraints: const BoxConstraints(minHeight: 110),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(trip.weather, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${trip.temperature} • Météo du jour",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Source: OpenWeatherMap",
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: SizedBox(
        width: double.infinity,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 110),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Mes Notes",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(notes, maxLines: 3, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


// New widget: shows thumbnails of trip images and opens full-screen viewer on tap
class _PhotosCard extends StatelessWidget {
  final List<String> imageUrls;

  const _PhotosCard({required this.imageUrls});

  Widget _buildThumb(BuildContext context, String url) {
    Widget imgWidget;
    if (url.startsWith('http')) {
      imgWidget = Image.network(url, width: 120, height: 90, fit: BoxFit.cover);
    } else if (url.startsWith('data:image/')) {
      try {
        final bytes = base64Decode(url.split(',')[1]);
        imgWidget = Image.memory(bytes, width: 120, height: 90, fit: BoxFit.cover);
      } catch (_) {
        imgWidget = Container(width: 120, height: 90, color: Colors.grey[300]);
      }
    } else {
      if (kIsWeb) {
        imgWidget = Container(width: 120, height: 90, color: Colors.grey[300]);
      } else {
        imgWidget = Image.file(File(url), width: 120, height: 90, fit: BoxFit.cover);
      }
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: imgWidget,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Photos', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: imageUrls.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final url = imageUrls[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => _FullScreenPhotoViewer(images: imageUrls, initialIndex: index)));
                    },
                    child: _buildThumb(context, url),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Full screen viewer for trip images
class _FullScreenPhotoViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _FullScreenPhotoViewer({required this.images, this.initialIndex = 0});

  @override
  State<_FullScreenPhotoViewer> createState() => _FullScreenPhotoViewerState();
}

class _FullScreenPhotoViewerState extends State<_FullScreenPhotoViewer> {
  late PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildImageWidget(String url) {
    if (url.startsWith('http')) return InteractiveViewer(child: Image.network(url, fit: BoxFit.contain));
    if (url.startsWith('data:image/')) {
      try {
        final bytes = base64Decode(url.split(',')[1]);
        return InteractiveViewer(child: Image.memory(bytes, fit: BoxFit.contain));
      } catch (_) {
        return const Center(child: Icon(Icons.broken_image, size: 48));
      }
    }
    if (kIsWeb) return const Center(child: Icon(Icons.broken_image, size: 48));
    return InteractiveViewer(child: Image.file(File(url), fit: BoxFit.contain));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.images.length,
        itemBuilder: (context, i) {
          return Center(child: _buildImageWidget(widget.images[i]));
        },
      ),
    );
  }
}
