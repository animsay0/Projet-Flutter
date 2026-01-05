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

  Trip copyWith({
    int? id,
    String? title,
    String? location,
    String? date,
    String? imageUrl,
    int? rating,
    String? weather,
    String? temperature,
    String? notes,
    String? gpsCoordinates,
  }) {
    return Trip(
      id: id ?? this.id,
      title: title ?? this.title,
      location: location ?? this.location,
      date: date ?? this.date,
      imageUrl: imageUrl ?? this.imageUrl,
      rating: rating ?? this.rating,
      weather: weather ?? this.weather,
      temperature: temperature ?? this.temperature,
      notes: notes ?? this.notes,
      gpsCoordinates: gpsCoordinates ?? this.gpsCoordinates,
    );
  }
}
