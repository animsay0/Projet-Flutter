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


class _Header extends StatelessWidget {
  final Trip trip;
  final VoidCallback onDelete;

  const _Header({required this.trip, required this.onDelete});

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
          onPressed: onDelete,
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
                    Colors.black.withOpacity(0.6),
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
