import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/trip.dart';

class TripService {
  static const _tripsKey = 'trips';

  Future<List<Trip>> loadTrips() async {
    final prefs = await SharedPreferences.getInstance();
    final tripsString = prefs.getString(_tripsKey);
    if (tripsString != null) {
      return Trip.decode(tripsString);
    }
    return [];
  }

  Future<void> saveTrips(List<Trip> trips) async {
    final prefs = await SharedPreferences.getInstance();
    final tripsString = Trip.encode(trips);
    await prefs.setString(_tripsKey, tripsString);
  }
}
