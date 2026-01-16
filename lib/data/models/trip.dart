import 'dart:convert';

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

  // Factory constructor to create a Trip object from a map
  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'],
      title: json['title'],
      location: json['location'],
      date: json['date'],
      imageUrl: json['imageUrl'],
      rating: json['rating'],
      weather: json['weather'],
      temperature: json['temperature'],
      notes: json['notes'],
      gpsCoordinates: json['gpsCoordinates'],
    );
  }

  // Method to convert a Trip object to a map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'location': location,
      'date': date,
      'imageUrl': imageUrl,
      'rating': rating,
      'weather': weather,
      'temperature': temperature,
      'notes': notes,
      'gpsCoordinates': gpsCoordinates,
    };
  }

  // Helper to encode a list of trips to a list of strings
  static String encode(List<Trip> trips) => json.encode(
        trips
            .map<Map<String, dynamic>>((trip) => trip.toJson())
            .toList(),
      );

  // Helper to decode a string into a list of trips
  static List<Trip> decode(String trips) =>
      (json.decode(trips) as List<dynamic>)
          .map<Trip>((item) => Trip.fromJson(item))
          .toList();
}
