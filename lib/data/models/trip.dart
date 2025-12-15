class Trip {
  final int id;
  final String title;
  final String location;
  final String date;
  final String imageUrl;
  final int rating;
  final String weather;
  final String temperature;
  final String? notes;
  final String? gpsCoordinates;

  Trip({
    required this.id,
    required this.title,
    required this.location,
    required this.date,
    required this.imageUrl,
    required this.rating,
    required this.weather,
    required this.temperature,
    this.notes,
    this.gpsCoordinates,
  });
}
