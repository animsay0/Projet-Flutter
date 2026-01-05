import 'package:flutter/material.dart';
import 'package:projet_flutter/data/models/place_model.dart';

class AddTripScreen extends StatelessWidget {
  final Place? place;

  const AddTripScreen({super.key, this.place});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nouvelle Sortie"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🖼 PHOTO DU LIEU
            _PlaceHeader(place: place),

            const SizedBox(height: 16),

            _QuickActions(),

            const SizedBox(height: 16),

            _FormCard(place: place),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: sauvegarde
                },
                child: const Text("Enregistrer"),
              ),
            )
          ],
        ),
      ),
    );
  }
}


class _PlaceHeader extends StatelessWidget {
  final Place? place;

  const _PlaceHeader({this.place});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: place?.photoUrl != null
              ? Image.network(
            place!.photoUrl!,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
          )
              : Container(
            height: 200,
            width: double.infinity,
            color: Colors.grey[300],
            child: const Center(
              child: Icon(
                Icons.image_not_supported,
                size: 48,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (place != null) ...[
          Text(
            place!.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            place!.address,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 4),
          if (place!.temperature != null)
            Text(
              "${place!.temperature}°C • ${place!.weather}",
            ),
        ],
      ],
    );
  }
}


class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ActionButton(icon: Icons.camera_alt, label: "Photo"),
        const SizedBox(width: 12),
        _ActionButton(icon: Icons.location_on, label: "GPS"),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ActionButton({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: () {},
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  final Place? place;

  const _FormCard({this.place});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(labelText: "Titre"),
              controller: TextEditingController(text: place?.name),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(labelText: "Lieu"),
              controller: TextEditingController(text: place?.address),
            ),
            const SizedBox(height: 12),
            const TextField(
              decoration: InputDecoration(labelText: "Notes"),
              maxLines: 4,
            ),
          ],
        ),
      ),
    );
  }
}

