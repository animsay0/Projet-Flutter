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
    Trip(
      id: 3,
      title: "Coucher de soleil à Santorin",
      location: "Santorin",
      date: "20/07/2024",
      imageUrl:
      "https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?q=80&w=1080",
      rating: 5,
      weather: "🌅",
      temperature: "28°C",
      notes:
      "Vue incroyable depuis Oia, ambiance magique et couleurs spectaculaires.",
      gpsCoordinates: "36.3932° N, 25.4615° E",
    ),

    Trip(
      id: 4,
      title: "Balade nocturne à Paris",
      location: "Paris",
      date: "15/06/2024",
      imageUrl:
      "https://images.unsplash.com/photo-1502602898657-3e91760cbb34?q=80&w=1080",
      rating: 4,
      weather: "🌙",
      temperature: "19°C",
      notes:
      "Promenade le long de la Seine avec les monuments illuminés.",
      gpsCoordinates: "48.8566° N, 2.3522° E",
    ),

    Trip(
      id: 5,
      title: "Safari dans le désert",
      location: "Dubaï",
      date: "02/05/2024",
      imageUrl:
      "https://images.unsplash.com/photo-1500534314209-a25ddb2bd429?q=80&w=1080",
      rating: 5,
      weather: "🌞",
      temperature: "35°C",
      notes:
      "Expérience unique dans les dunes avec coucher de soleil et dîner traditionnel.",
      gpsCoordinates: "25.2048° N, 55.2708° E",
    ),

    Trip(
      id: 6,
      title: "Week-end à Rome",
      location: "Rome",
      date: "10/04/2024",
      imageUrl:
      "https://images.unsplash.com/photo-1526481280690-7ead64a0cfe8?q=80&w=1080",
      rating: 4,
      weather: "⛅",
      temperature: "21°C",
      notes:
      "Visite du Colisée, du Vatican et dégustation de spécialités italiennes.",
      gpsCoordinates: "41.9028° N, 12.4964° E",
    ),

  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const _Header(),
      body: Column(
        children: [
          const _Filters(),
          Expanded(child: _TripList(trips: trips)),
        ],
      ),
    );
  }
}

/* ===================== HEADER ===================== */

class _Header extends StatelessWidget implements PreferredSizeWidget {
  const _Header({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF008080),
              Color(0xFF006D6D),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
      ),
      title: const Text(
        "Juno - mon carnet de Voyage",
        style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(80),
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: _StatsRow(),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(150);
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
        // color: const Color(0xFF008080).withOpacity(0.18) ,
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
          // color: Colors.amber,
              color: const Color(0xFFFFB000),
          size: 16,
        ),
      ),
    );
  }
}
