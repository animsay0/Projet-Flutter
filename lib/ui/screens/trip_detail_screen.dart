import 'dart:io';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../data/models/trip.dart';

class TripDetailScreen extends StatelessWidget {
  final Trip trip;
  final Function(int) onDeleteTrip;

  const TripDetailScreen({
    super.key,
    required this.trip,
    required this.onDeleteTrip,
  });

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
                onDeleteTrip(trip.id);
                Navigator.of(context).pop(); // Close the dialog
                Navigator.of(context).pop(); // Go back to the home screen
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: CustomScrollView(
        slivers: [
          _Header(trip: trip, onDelete: () => _showDeleteConfirmation(context)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _QuickInfo(trip: trip),
                  const SizedBox(height: 16),
                  if (trip.gpsCoordinates != null)
                    _GpsCard(trip: trip),
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


class _Header extends StatefulWidget {
  final Trip trip;
  final VoidCallback onDelete;

  const _Header({required this.trip, required this.onDelete});

  @override
  State<_Header> createState() => _HeaderState();
}

class _HeaderState extends State<_Header> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildImage(String url) {
    if (url.startsWith('http')) {
      return Image.network(url, fit: BoxFit.cover);
    } else {
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
  }

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
          onPressed: widget.onDelete,
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Hero(
              tag: 'trip-${widget.trip.id}',
              child: widget.trip.imageUrls.isNotEmpty
                  ? PageView.builder(
                      controller: _pageController,
                      itemCount: widget.trip.imageUrls.length,
                      itemBuilder: (context, index) {
                        return _buildImage(widget.trip.imageUrls[index]);
                      },
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                    )
                  : _buildPlaceholder(context),
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
              bottom: 80,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.trip.imageUrls.length, (index) {
                  return Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentPage == index
                          ? Colors.white
                          : Colors.white.withAlpha((0.5 * 255).round()),
                    ),
                  );
                }),
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



class _GpsCard extends StatelessWidget {
  final Trip trip;

  const _GpsCard({required this.trip});

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
                  "Coordonnées GPS",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(trip.gpsCoordinates ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      // plus tard → MapScreen
                    },
                    child: const Text("Voir sur la carte"),
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



class _PlaceInfoCard extends StatelessWidget {
  const _PlaceInfoCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFF5F3FF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: SizedBox(
        width: double.infinity,
        child: ConstrainedBox(
          // harmoniser visuellement avec un minHeight mais autoriser l'expansion verticale
          constraints: const BoxConstraints(minHeight: 110),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
