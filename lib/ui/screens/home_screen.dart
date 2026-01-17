import 'dart:io';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../data/models/trip.dart';
import 'trip_detail_screen.dart';
import 'add_trip_screen.dart';
import '../../utils/weather_utils.dart';
import '../../utils/app_colors.dart';

class HomeScreen extends StatefulWidget {
  final List<Trip> trips;
  final Function(int) onDeleteTrip;
  final Function(Trip) onUpdateTrip;
  const HomeScreen({super.key, required this.trips, required this.onDeleteTrip, required this.onUpdateTrip});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late List<Trip> _filteredTrips;
  int _selectedRating = 0; // 0 for "Tout"

  @override
  void initState() {
    super.initState();
    _filteredTrips = widget.trips;
  }

  @override
  void didUpdateWidget(HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trips != oldWidget.trips) {
      _applyFilter(_selectedRating);
    }
  }

  void _applyFilter(int rating) {
    setState(() {
      if (rating == 0) {
        _filteredTrips = widget.trips;
      } else {
        _filteredTrips =
            widget.trips.where((trip) => trip.rating == rating).toList();
      }
    });
  }

  void _onFilterChanged(int rating) {
    // If the same filter is tapped again, reset to "Tout"
    if (_selectedRating == rating) {
      _selectedRating = 0;
    } else {
      _selectedRating = rating;
    }
    _applyFilter(_selectedRating);

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _Header(trips: _filteredTrips),
      body: Column(
        children: [
          _Filters(
            selectedRating: _selectedRating,
            onFilterChanged: _onFilterChanged,
          ),
          Expanded(child: _TripList(trips: _filteredTrips, onDeleteTrip: widget.onDeleteTrip, onUpdateTrip: widget.onUpdateTrip)),
        ],
      ),
    );
  }
}

/* ===================== HEADER ===================== */

class _Header extends StatelessWidget implements PreferredSizeWidget {
  final List<Trip> trips;
  const _Header({required this.trips});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.bannerGreen1,
              AppColors.bannerGreen2,
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
          fontSize: 25,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: _StatsRow(trips: trips),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(150);
}

class _StatsRow extends StatelessWidget {
  final List<Trip> trips;
  const _StatsRow({required this.trips});

  @override
  Widget build(BuildContext context) {
    final int sorties = trips.length;
    final double moyenne = trips.isEmpty
        ? 0.0
        : trips.map((t) => t.rating).reduce((a, b) => a + b) / trips.length;
    final int top = trips.where((t) => t.rating == 5).length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _StatCard(title: "Sorties", value: sorties.toString()),
        _StatCard(title: "Moyenne", value: moyenne.toStringAsFixed(1)),
        _StatCard(title: "Top", value: top.toString()),
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
        color: Colors.white.withAlpha((0.2 * 255).round()),
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
  final int selectedRating;
  final ValueChanged<int> onFilterChanged;

  const _Filters({
    required this.selectedRating,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final filters = {
      "Tout": 0,
      "5★": 5,
      "4★": 4,
      "3★": 3,
      "2★": 2,
      "1★": 1,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            const Icon(Icons.filter_list, color: Colors.grey),
            const SizedBox(width: 8),
            const Text("Filtrer:", style: TextStyle(color: Colors.grey)),
            const SizedBox(width: 16),
            ...filters.entries.map((entry) {
              return _FilterChip(
                label: entry.key,
                rating: entry.value,
                isSelected: selectedRating == entry.value,
                onTap: () => onFilterChanged(entry.value),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int rating;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.rating,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color selectedColor = (rating == 0) ? const Color(0xFF333333) : const Color(0xFF006D6D);
    final Color unselectedColor = Colors.grey[200]!;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : unselectedColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/* ===================== TRIP LIST ===================== */

class _TripList extends StatefulWidget {
  final List<Trip> trips;
  final Function(int) onDeleteTrip;
  final Function(Trip) onUpdateTrip;

  const _TripList({required this.trips, required this.onDeleteTrip, required this.onUpdateTrip});

  @override
  State<_TripList> createState() => _TripListState();
}

class _TripListState extends State<_TripList> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _scaleAnim = Tween<double>(begin: 0.9, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trips = widget.trips;
    if (trips.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FadeTransition(
                opacity: _fadeAnim,
                child: ScaleTransition(
                  scale: _scaleAnim,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [AppColors.primaryVioletWithOpacity(0.18), AppColors.accentVioletWithOpacity(0.18)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(38),
                          boxShadow: [BoxShadow(color: const Color.fromRGBO(0, 0, 0, 0.05), blurRadius: 8, spreadRadius: 2)],
                        ),
                        child: const Icon(Icons.place, size: 36, color: AppColors.primaryViolet),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Aucune sortie enregistrée', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Commencez votre première aventure !', style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 24),
              SizedBox(
                width: 220,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter une sortie'),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => AddTripScreen(onAddTrip: (trip) {})));
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: trips.length,
      itemBuilder: (context, index) {
        return _TripCard(trip: trips[index], onDeleteTrip: widget.onDeleteTrip, onUpdateTrip: widget.onUpdateTrip);
      },
    );
  }
}

/* ===================== TRIP CARD ===================== */

class _TripCard extends StatelessWidget {
  final Trip trip;
  final Function(int) onDeleteTrip;
  final Function(Trip) onUpdateTrip;

  const _TripCard({required this.trip, required this.onDeleteTrip, required this.onUpdateTrip});

  Widget _buildImage(BuildContext context, String url) {
    if (url.startsWith('http')) {
      return Image.network(
        url,
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
        errorBuilder: (ctx, err, stack) => _buildPlaceholder(ctx),
      );
    } else if (url.startsWith('data:image/')) {
      try {
        final base64Str = url.split(',')[1];
        final bytes = base64Decode(base64Str);
        return Image.memory(bytes, height: 180, width: double.infinity, fit: BoxFit.cover);
      } catch (_) {
        return _buildPlaceholder(context);
      }
    } else {
      if (kIsWeb) return _buildPlaceholder(context);
      return Image.file(
        File(url),
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, stack) => _buildPlaceholder(ctx),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TripDetailScreen(trip: trip, onDeleteTrip: onDeleteTrip, onUpdateTrip: onUpdateTrip),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        elevation: 4,
        shadowColor: Colors.black.withAlpha((0.1 * 255).round()),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'trip-${trip.id}',
              child: trip.imageUrls.isNotEmpty ? _buildImage(context, trip.imageUrls.first) : _buildPlaceholder(context),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(trip.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text("${trip.location} • ${trip.date}", style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _Stars(rating: trip.rating),
                      const SizedBox(width: 6),
                      Text("(${trip.rating}/5)", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      const Spacer(),
                      if (trip.weather.isNotEmpty)
                        Row(
                          children: [
                            Text(weatherEmoji(trip.weather), style: const TextStyle(fontSize: 18)),
                            const SizedBox(width: 6),
                            Text(trip.temperature),
                          ],
                        ),
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

  Widget _buildPlaceholder(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      height: 180,
      width: double.infinity,
      color: primary.withAlpha((0.1 * 255).round()),
      child: Center(
        child: Icon(
          Icons.landscape_rounded,
          size: 64,
          color: primary.withAlpha((0.4 * 255).round()),
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
          color: const Color(0xFFFFB000),
          size: 16,
        ),
      ),
    );
  }
}
