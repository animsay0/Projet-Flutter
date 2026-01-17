import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:projet_flutter/data/models/place_model.dart';
import 'package:projet_flutter/data/models/trip.dart';
import 'package:projet_flutter/ui/screens/map_screen.dart';
import '../../utils/persistence.dart';

class AddTripScreen extends StatefulWidget {
  final Place? place;
  final Function(Trip) onAddTrip;
  final VoidCallback? onTripSaved;
  final Trip? trip; // optional trip for edit mode
  final Function(Trip)? onUpdateTrip; // optional update callback for backward compatibility

  const AddTripScreen({
    super.key,
    this.place,
    required this.onAddTrip,
    this.onTripSaved,
    this.trip,
    this.onUpdateTrip,
  });

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
  final ImagePicker _picker = ImagePicker();
  // store both original paths (when available) and processed bytes for display
  final List<String> _photoPaths = [];
  final List<Uint8List> _photoBytes = [];
  Uint8List? _coverBytes;
  ll.LatLng? _pickedPosition;

  // helper: process picked image (crop to 4:3 center, resize to max width)
  Future<Uint8List?> _processPickedImage(XFile file) async {
    try {
      final bytes = await file.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;

      // crop to 4:3 centered
      final targetAspect = 4 / 3;
      int cropWidth = decoded.width;
      int cropHeight = decoded.height;
      final currentAspect = decoded.width / decoded.height;
      if (currentAspect > targetAspect) {
        // image too wide -> reduce width
        cropWidth = (decoded.height * targetAspect).round();
      } else {
        // image too tall -> reduce height
        cropHeight = (decoded.width / targetAspect).round();
      }
      final cropX = ((decoded.width - cropWidth) / 2).round();
      final cropY = ((decoded.height - cropHeight) / 2).round();
      final cropped = img.copyCrop(decoded, x: cropX, y: cropY, width: cropWidth, height: cropHeight);

      // resize to max width 1200 for storage (keeps aspect)
      final resized = img.copyResize(cropped, width: 1200);

      // re-encode to JPEG with reasonable quality
      final out = img.encodeJpg(resized, quality: 85);
      return Uint8List.fromList(out);
    } catch (e) {
      // ignore and return raw bytes as fallback
      try {
        return await file.readAsBytes();
      } catch (_) {
        return null;
      }
    }
  }

  // Simplify long place/address strings returned by APIs.
  // Strategy: split by comma, then join leading segments until maxChars is reached.
  String _simplifyPlaceString(String s, {int maxChars = 50}) {
    if (s.trim().length <= maxChars) return s.trim();
    final parts = s.split(',').map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return s.trim().substring(0, maxChars - 3).trim() + '...';
    String result = parts[0];
    for (var i = 1; i < parts.length; i++) {
      final next = parts[i];
      if (result.length + 2 + next.length <= maxChars) {
        result = '$result, $next';
      } else {
        final remaining = maxChars - result.length - 5; // leave space for ', ' and '...'
        if (remaining > 5) {
          final truncated = next.substring(0, remaining).trim();
          result = '$result, ${truncated}...';
        }
        break;
      }
    }
    if (result.length > maxChars) result = result.substring(0, maxChars - 3).trim() + '...';
    return result;
  }

  // Ensure saved strings are within limits (truncate if necessary).
  String _truncateForSave(String s, int maxChars) {
    if (s.length <= maxChars) return s;
    return s.substring(0, maxChars - 3).trim() + '...';
  }

  @override
  void initState() {
    super.initState();
    // Pré-remplir les champs avec une version simplifiée pour éviter des chaînes trop longues
    final String? initialTitle = widget.trip?.title ?? (widget.place?.name != null ? _simplifyPlaceString(widget.place!.name) : null);
    final String? initialLocation = widget.trip?.location ?? (widget.place?.address != null ? _simplifyPlaceString(widget.place!.address, maxChars: 70) : null);

    _titleController = TextEditingController(text: initialTitle);
    _locationController = TextEditingController(text: initialLocation);
    _notesController = TextEditingController(text: widget.trip?.notes ?? '');
    _selectedDate = widget.trip != null ? DateFormat('dd/MM/yyyy').parse(widget.trip!.date) : DateTime.now();
    _rating = widget.trip?.rating.toDouble() ?? 3.0;

    // If editing and trip has images, load them into _photoBytes/_coverBytes depending on ordering
    if (widget.trip != null && widget.trip!.imageUrls.isNotEmpty) {
      // treat first image as cover, remaining as photos
      final first = widget.trip!.imageUrls.first;
      if (first.startsWith('data:image/')) {
        try {
          final bytes = base64Decode(first.split(',')[1]);
          _coverBytes = bytes;
        } catch (_) {}
      }
      final rest = widget.trip!.imageUrls.skip(1);
      for (final url in rest) {
        if (url.startsWith('data:image/')) {
          try {
            final bytes = base64Decode(url.split(',')[1]);
            _photoBytes.add(bytes);
            _photoPaths.add('');
          } catch (_) {}
        }
      }
    }
    // No local cover bytes initially; if widget.place has a network photo it will be shown by PlaceHeader
  }

  Future<void> _pickCoverImage(ImageSource source) async {
    final XFile? file = await _picker.pickImage(source: source, imageQuality: 80);
    if (file == null) return;
    final processed = await _processPickedImage(file);
    if (processed == null) return;
    if (!mounted) return;
    setState(() {
      _coverBytes = processed;
      // cover path intentionally not stored locally (not used currently)
    });
  }

  void _showCoverOptions() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Prendre une photo de couverture'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickCoverImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choisir depuis la galerie'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickCoverImage(ImageSource.gallery);
                },
              ),
              if (_coverBytes != null || widget.place?.photoUrl != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('Supprimer la photo de couverture', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() { _coverBytes = null; });
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveTrip() async {
    if (_formKey.currentState!.validate()) {
      // Persist processed images as data URIs so they're portable across platforms
      final List<String> imageUrls = [];
      // cover first if present
      if (_coverBytes != null) {
        imageUrls.add('data:image/jpeg;base64,${base64Encode(_coverBytes!)}');
      }
      // then other photos
      imageUrls.addAll(_photoBytes.map((b) => 'data:image/jpeg;base64,${base64Encode(b)}'));
      // if there are still no images but the place has a photoUrl, keep compatibility with previous behavior
      if (imageUrls.isEmpty && widget.place?.photoUrl != null) {
        imageUrls.add(widget.place!.photoUrl!);
      } else if (widget.place?.photoUrl != null && imageUrls.isNotEmpty) {
        // preserve previous behavior of appending the place photo when other images exist
        imageUrls.add(widget.place!.photoUrl!);
      }

      // Ensure saved fields are capped
      final savedTitle = _truncateForSave(_titleController.text.trim(), 60);
      final savedLocation = _truncateForSave(_locationController.text.trim(), 100);

      final newTrip = Trip(
        id: widget.trip?.id ?? DateTime.now().millisecondsSinceEpoch, // preserve id when editing
        title: savedTitle,
        location: savedLocation,
        date: DateFormat('dd/MM/yyyy').format(_selectedDate),
        imageUrls: imageUrls,
        rating: _rating.toInt(),
        weather: widget.place?.weather ?? widget.trip?.weather ?? "",
        temperature: widget.place?.temperature?.toString() ?? widget.trip?.temperature ?? "",
        notes: _notesController.text,
        gpsCoordinates: _pickedPosition != null
            ? '${_pickedPosition!.latitude},${_pickedPosition!.longitude}'
            : widget.trip?.gpsCoordinates,
      );

      if (widget.trip != null) {
        // edit mode: prefer returning the updated trip to the caller
        if (Navigator.canPop(context)) Navigator.of(context).pop<Trip>(newTrip);
        widget.onUpdateTrip?.call(newTrip);
        return;
      }

      widget.onAddTrip(newTrip);

      // If possible, also add the place to saved places so it appears on the map
      bool hasCoords = false;
      Place? placeToSave;
      // consider coordinates valid if not near (0,0)
      bool coordsValid(double lat, double lng) => lat.abs() > 1e-5 && lng.abs() > 1e-5;

      if (widget.place != null && coordsValid(widget.place!.lat, widget.place!.lng)) {
        hasCoords = true;
        placeToSave = widget.place;
      } else if (_pickedPosition != null) {
        hasCoords = true;
        placeToSave = Place(
          id: 'manual_${DateTime.now().millisecondsSinceEpoch}',
          name: savedTitle,
          address: savedLocation,
          lat: _pickedPosition!.latitude,
          lng: _pickedPosition!.longitude,
          photoUrl: widget.place?.photoUrl,
          weather: widget.place?.weather,
          temperature: widget.place?.temperature,
        );
      }

      if (hasCoords && placeToSave != null) {
        try {
          await Persistence.addPlace(placeToSave);
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lieu sauvegardé et ajouté à la carte')));
        } catch (e) {
          // ignore persistence errors but inform user
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lieu sauvegardé mais impossible de l\'ajouter à la carte: $e')));
        }
      } else {
        // saved trip but no coords available -> inform user it won't appear on the map
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sortie enregistrée (coordonnées absentes — non affichée sur la carte)')));
      }

      // reset form fields after successful save
      _titleController.clear();
      _locationController.clear();
      _notesController.clear();
      setState(() {
        _selectedDate = DateTime.now();
        _rating = 3.0;
        _photoBytes.clear();
        _photoPaths.clear();
        _pickedPosition = null;
      });

      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      } else {
        widget.onTripSaved?.call();
      }
    }
  }

  Future<void> _pickImageAndProcess(ImageSource source) async {
    final XFile? file = await _picker.pickImage(source: source, imageQuality: 80);
    if (file == null) return;
    final processed = await _processPickedImage(file);
    if (processed == null) return;
    if (!mounted) return;
    setState(() {
      _photoBytes.add(processed);
      if (!kIsWeb && file.path.isNotEmpty) {
        _photoPaths.add(file.path);
      } else {
        _photoPaths.add('');
      }
    });
  }

  void _removePhoto(int index) {
    if (index < 0 || index >= _photoBytes.length) return;
    setState(() {
      _photoBytes.removeAt(index);
      if (index < _photoPaths.length) _photoPaths.removeAt(index);
    });
  }

  // Try to get device current location (with permission handling)
  Future<ll.LatLng?> _getDeviceLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permission de localisation refusée')));
        return null;
      }
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      if (!mounted) return null;
      return ll.LatLng(pos.latitude, pos.longitude);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Impossible d\'obtenir la position: $e')));
      return null;
    }
  }

  // Open MapScreen centered on the best available location (place coords, pickedPosition or device location)
  Future<void> _openMap() async {
    ll.LatLng? loc;
    if (widget.place?.lat != null && widget.place?.lng != null) {
      loc = ll.LatLng(widget.place!.lat, widget.place!.lng);
    } else if (_pickedPosition != null) {
      loc = _pickedPosition;
    } else {
      loc = await _getDeviceLocation();
      if (!mounted) return;
      if (loc != null) setState(() => _pickedPosition = loc);
    }

    if (loc != null) {
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => MapScreen(initialLocation: loc)));
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aucune position disponible')));
    }
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (!mounted) return;
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.trip != null ? "Modifier la sortie" : "Nouvelle Sortie"),
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
              // pass coverBytes and callback to header so user can pick/replace cover image
              _PlaceHeader(place: widget.place, coverBytes: _coverBytes, onPickCover: _showCoverOptions),
              const SizedBox(height: 16),
              _FormCard(
                titleController: _titleController,
                locationController: _locationController,
                notesController: _notesController,
                selectedDate: _selectedDate,
                onDateTap: _pickDate,
              ),
              const SizedBox(height: 16),
              // Photos & location actions for add screen
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Photos & localisation', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(children: [
                        ElevatedButton.icon(onPressed: () => _pickImageAndProcess(ImageSource.camera), icon: const Icon(Icons.camera_alt), label: const Text('Prendre')),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(onPressed: () => _pickImageAndProcess(ImageSource.gallery), icon: const Icon(Icons.photo_library), label: const Text('Galerie')),
                        const SizedBox(width: 8),
                        // bouton 'Localiser' retiré de cette section volontairement
                      ]),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 90,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (_, i) {
                            final bytes = _photoBytes[i];
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => _PhotoViewer(images: _photoBytes, initialIndex: i)));
                              },
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.memory(bytes, width: 120, height: 80, fit: BoxFit.cover),
                                  ),
                                  Positioned(
                                    top: -6,
                                    right: -6,
                                    child: IconButton(
                                      icon: const Icon(Icons.close, size: 18, color: Colors.white),
                                      padding: EdgeInsets.zero,
                                      onPressed: () => _removePhoto(i),
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemCount: _photoBytes.length,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(children: [
                        ElevatedButton.icon(
                          onPressed: _openMap,
                          icon: const Icon(Icons.map),
                          label: const Text('Voir sur la carte'),
                        ),
                      ])
                    ],                  ),
                ),
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
                  child: Text(widget.trip != null ? "Mettre à jour" : "Enregistrer"),
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
  final Uint8List? coverBytes;
  final VoidCallback onPickCover;

  const _PlaceHeader({this.place, this.coverBytes, required this.onPickCover});

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      height: 200,
      width: double.infinity,
      color: Theme.of(context).primaryColor.withAlpha((0.1 * 255).round()),
      child: Center(
        child: Icon(
          Icons.landscape_rounded,
          size: 64,
          color: Theme.of(context).primaryColor.withAlpha((0.4 * 255).round()),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onPickCover,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: coverBytes != null
                ? Image.memory(
                    coverBytes!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => _buildPlaceholder(context),
                  )
                : place?.photoUrl != null
                    ? Image.network(
                        place!.photoUrl!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) => _buildPlaceholder(context),
                      )
                    : _buildPlaceholder(context),
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
              maxLength: 60,
              decoration: const InputDecoration(labelText: "Titre", counterText: ''),
              validator: (value) => value!.isEmpty ? "Le titre ne peut pas être vide" : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: locationController,
              maxLength: 100,
              decoration: const InputDecoration(labelText: "Lieu", counterText: ''),
              validator: (value) => value!.isEmpty ? "Le lieu ne peut pas être vide" : null,
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
              label: "${rating.toInt()}⭐",
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

// Full screen photo viewer (swipeable)
class _PhotoViewer extends StatefulWidget {
  final List<Uint8List> images;
  final int initialIndex;

  const _PhotoViewer({required this.images, this.initialIndex = 0});

  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.images.length,
        itemBuilder: (context, i) {
          return InteractiveViewer(
            child: Center(child: Image.memory(widget.images[i], fit: BoxFit.contain)),
          );
        },
      ),
    );
  }
}
