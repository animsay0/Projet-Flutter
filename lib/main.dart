import 'package:flutter/material.dart';
import 'package:projet_flutter/data/models/trip.dart';
import 'package:projet_flutter/services/trip_service.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/search_screen.dart';
import 'ui/screens/add_trip_screen.dart';
import 'ui/screens/map_screen.dart';
import 'ui/widgets/bottom_navigation.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Juno - Mon Carnet de Voyage',
      theme: ThemeData(
        primaryColor: const Color(0xFF008080),
        scaffoldBackgroundColor: const Color(0xFFF9FAFB),
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF008080),
          primary: const Color(0xFF008080),
          secondary: const Color(0xFFFFB000),
        ),
      ),
      home: const MainLayout(),
    );
  }
}

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;
  List<Trip> _trips = [];
  final TripService _tripService = TripService();

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    final trips = await _tripService.loadTrips();
    setState(() {
      _trips = trips;
    });
  }

  Future<void> _addTrip(Trip trip) async {
    setState(() {
      _trips.add(trip);
    });
    await _tripService.saveTrips(_trips);
  }

  Future<void> _deleteTrip(int tripId) async {
    setState(() {
      _trips.removeWhere((trip) => trip.id == tripId);
    });
    await _tripService.saveTrips(_trips);
  }

  void _onTripSaved() {
    setState(() {
      _currentIndex = 0; // Go to home screen
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(trips: _trips, onDeleteTrip: _deleteTrip),
      SearchScreen(onAddTrip: _addTrip),
      AddTripScreen(onAddTrip: _addTrip, onTripSaved: _onTripSaved),
      const MapScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigation(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
      ),
    );
  }
}
