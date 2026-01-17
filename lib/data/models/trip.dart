import 'dart:convert';

class Trip {
  final int id;
  final String title;
  final String location;
  final String date;
  final List<String> imageUrls;
  final int rating;
  final String weather;
  final String temperature;
  final String? notes;
  final String? gpsCoordinates;

  // Optional: Data from Foursquare place
  final String? placeCategory;
  final double? placePopularity;
  final int? placeTotalRatings;

  Trip({
    required this.id,
    required this.title,
    required this.location,
    required this.date,
    required this.imageUrls,
    required this.rating,
    required this.weather,
    required this.temperature,
    this.notes,
    this.gpsCoordinates,
    this.placeCategory,
    this.placePopularity,
    this.placeTotalRatings,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    List<String> imageUrls = [];
    if (json['imageUrls'] != null) {
      imageUrls = List<String>.from(json['imageUrls']);
    } else if (json['imageUrl'] != null) {
      imageUrls = [json['imageUrl'] as String];
    }

    return Trip(
      id: json['id'],
      title: json['title'],
      location: json['location'],
      date: json['date'],
      imageUrls: imageUrls,
      rating: json['rating'],
      weather: json['weather'],
      temperature: json['temperature'],
      notes: json['notes'],
      gpsCoordinates: json['gpsCoordinates'],
      placeCategory: json['placeCategory'],
      placePopularity: json['placePopularity'],
      placeTotalRatings: json['placeTotalRatings'],
    );
  }

  // Method to convert a Trip object to a map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'location': location,
      'date': date,
      'imageUrls': imageUrls,
      'rating': rating,
      'weather': weather,
      'temperature': temperature,
      'notes': notes,
      'gpsCoordinates': gpsCoordinates,
      'placeCategory': placeCategory,
      'placePopularity': placePopularity,
      'placeTotalRatings': placeTotalRatings,
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
