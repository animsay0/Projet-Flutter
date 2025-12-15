import 'package:flutter/material.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Carte des sorties"),
        actions: [
          IconButton(
            icon: const Icon(Icons.layers),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          _MapPlaceholder(),
          const Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: _TopInfoCard(),
          ),
          const Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: _SelectedTripCard(),
          ),
        ],
      ),
    );
  }
}

class _MapPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: Text(
          "Carte interactive\n(Google Maps ici)",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}

class _TopInfoCard extends StatelessWidget {
  const _TopInfoCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text("🧭 5 lieux"),
            Chip(label: Text("Standard")),
          ],
        ),
      ),
    );
  }
}

class _SelectedTripCard extends StatelessWidget {
  const _SelectedTripCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Mont Blanc",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text("Chamonix"),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("★★★★★"),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text("Voir"),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
