import 'package:flutter/material.dart';
import '../../data/models/trip.dart';
import 'trip_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Mock data (temporaire)
  List<Trip> get trips => [
    Trip(
      id: 1,
      title: "Randonnée Mont Blanc",
      location: "Chamonix",
      date: "12/12/2024",
      imageUrl:
      "https://images.unsplash.com/photo-1713959989861-2425c95e9777?q=80&w=1080",
      rating: 5,
      weather: "☀️",
      temperature: "18°C",
      notes:
      "Une journée magnifique avec une vue exceptionnelle sur le Mont Blanc.",
      gpsCoordinates: "45.8326° N, 6.8652° E",
    ),
    Trip(
      id: 2,
      title: "Lac d’Annecy",
      location: "Annecy",
      date: "05/08/2024",
      imageUrl:
      "https://images.unsplash.com/photo-1501785888041-af3ef285b470?q=80&w=1080",
      rating: 4,
      weather: "🌤️",
      temperature: "22°C",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const _Header(),
          const _Filters(),
          Expanded(child: _TripList(trips: trips)),
        ],
      ),
    );
  }
}

/* ===================== HEADER ===================== */

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF4F46E5),
            Color(0xFF6366F1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "Carnet de Voyage",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 16),
          _StatsRow(),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: const [
        _StatCard(title: "Sorties", value: "2"),
        _StatCard(title: "Moyenne", value: "4.5"),
        _StatCard(title: "Top", value: "2"),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;

  const _StatCard({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            title,
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

/* ===================== FILTERS ===================== */

class _Filters extends StatelessWidget {
  const _Filters();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: const [
          _FilterChip(label: "Tout"),
          _FilterChip(label: "5★+"),
          _FilterChip(label: "4★+"),
          _FilterChip(label: "3★+"),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;

  const _FilterChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(label: Text(label)),
    );
  }
}

/* ===================== TRIP LIST ===================== */

class _TripList extends StatelessWidget {
  final List<Trip> trips;

  const _TripList({required this.trips});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: trips.length,
      itemBuilder: (context, index) {
        return _TripCard(trip: trips[index]);
      },
    );
  }
}

/* ===================== TRIP CARD ===================== */

class _TripCard extends StatelessWidget {
  final Trip trip;

  const _TripCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TripDetailScreen(trip: trip),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'trip-${trip.id}',
              child: Image.network(
                trip.imageUrl,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 180,
                    color: Colors.grey[300],
                    child: const Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (_, __, ___) => Container(
                  height: 180,
                  color: Colors.grey[300],
                  child: const Icon(Icons.image_not_supported),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trip.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text("${trip.location} • ${trip.date}"),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _Stars(rating: trip.rating),
                      const SizedBox(width: 6),
                      Text(
                        "(${trip.rating}/5)",
                        style: const TextStyle(fontSize: 12),
                      ),
                      const Spacer(),
                      Text("${trip.weather} ${trip.temperature}"),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ===================== STARS ===================== */

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
          size: 16,
        ),
      ),
    );
  }
}
