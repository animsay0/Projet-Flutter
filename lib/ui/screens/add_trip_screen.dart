import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:projet_flutter/data/models/place_model.dart';
import 'package:projet_flutter/data/models/trip.dart';

class AddTripScreen extends StatefulWidget {
  final Place? place;
  final Function(Trip)? onAddTrip;

  const AddTripScreen({super.key, this.place, this.onAddTrip});

  @override
  State<AddTripScreen> createState() => _AddTripScreenState();
}

class _AddTripScreenState extends State<AddTripScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _locationController;
  late TextEditingController _notesController;
  late DateTime _selectedDate;
  double _rating = 3.0;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.place?.name);
    _locationController = TextEditingController(text: widget.place?.address);
    _notesController = TextEditingController();
    _selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  void _saveTrip() {
    if (_formKey.currentState!.validate()) {
      final newTrip = Trip(
        id: DateTime.now().millisecondsSinceEpoch, // Unique ID
        title: _titleController.text,
        location: _locationController.text,
        date: DateFormat('dd/MM/yyyy').format(_selectedDate),
        imageUrl: widget.place?.photoUrl ?? "https://via.placeholder.com/1080",
        rating: _rating.toInt(),
        weather: widget.place?.weather ?? "",
        temperature: widget.place?.temperature?.toString() ?? "",
        notes: _notesController.text,
      );
      widget.onAddTrip?.call(newTrip);
      Navigator.of(context).pop(); // Go back to the previous screen
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nouvelle Sortie"),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveTrip,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PlaceHeader(place: widget.place),
              const SizedBox(height: 16),
              _FormCard(
                titleController: _titleController,
                locationController: _locationController,
                notesController: _notesController,
                selectedDate: _selectedDate,
                onDateTap: _pickDate,
              ),
              const SizedBox(height: 16),
              _RatingSlider(rating: _rating, onChanged: (newRating) {
                setState(() => _rating = newRating);
              }),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveTrip,
                  child: const Text("Enregistrer"),
                ),
              )
            ],
          ),
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
      ],
    );
  }
}

class _FormCard extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController locationController;
  final TextEditingController notesController;
  final DateTime selectedDate;
  final VoidCallback onDateTap;

  const _FormCard({
    required this.titleController,
    required this.locationController,
    required this.notesController,
    required this.selectedDate,
    required this.onDateTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: titleController,
              decoration: const InputDecoration(labelText: "Titre"),
              validator: (value) =>
              value!.isEmpty ? "Le titre ne peut pas être vide" : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: locationController,
              decoration: const InputDecoration(labelText: "Lieu"),
              validator: (value) =>
              value!.isEmpty ? "Le lieu ne peut pas être vide" : null,
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text("Date"),
              subtitle: Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
              onTap: onDateTap,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: notesController,
              decoration: const InputDecoration(labelText: "Notes"),
              maxLines: 4,
            ),
          ],
        ),
      ),
    );
  }
}

class _RatingSlider extends StatelessWidget {
  final double rating;
  final ValueChanged<double> onChanged;

  const _RatingSlider({required this.rating, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Note", style: TextStyle(fontWeight: FontWeight.bold)),
            Slider(
              value: rating,
              min: 1,
              max: 5,
              divisions: 4,
              label: rating.toInt().toString(),
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}
