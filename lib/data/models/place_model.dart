class Place {
  final String id;
  final String name;
  final String address;
  final double lat;
  final double lng;
  final String? photoUrl;
  final String? weather;
  final double? temperature;

  Place({
    required this.id,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    this.photoUrl,
    this.weather,
    this.temperature,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'lat': lat,
      'lng': lng,
      'photoUrl': photoUrl,
      'weather': weather,
      'temperature': temperature,
    };
  }

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      lat: (json['lat'] is num) ? (json['lat'] as num).toDouble() : double.tryParse(json['lat']?.toString() ?? '') ?? 0.0,
      lng: (json['lng'] is num) ? (json['lng'] as num).toDouble() : double.tryParse(json['lng']?.toString() ?? '') ?? 0.0,
      photoUrl: json['photoUrl']?.toString(),
      weather: json['weather']?.toString(),
      temperature: (json['temperature'] is num) ? (json['temperature'] as num).toDouble() : (json['temperature'] != null ? double.tryParse(json['temperature'].toString()) : null),
    );
  }
}
