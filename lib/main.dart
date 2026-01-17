import 'package:flutter/material.dart';
import 'package:projet_flutter/data/models/trip.dart';
import 'package:projet_flutter/services/trip_service.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/search_screen.dart';
import 'ui/screens/add_trip_screen.dart';
import 'ui/screens/map_screen.dart';
import 'ui/widgets/bottom_navigation.dart';
import 'utils/app_colors.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Use centralized colors
    const primaryViolet = AppColors.primaryViolet;
    const accent = AppColors.accentViolet;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryViolet,
      primary: primaryViolet,
      secondary: const Color(0xFFFFB000),
      surface: AppColors.background,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Juno - Mon Carnet de Voyage',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        primaryColor: primaryViolet,
        scaffoldBackgroundColor: const Color(0xFFF9FAFB),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.transparent,
          centerTitle: false,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: primaryViolet,
          elevation: 6,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: primaryViolet,
          unselectedItemColor: Colors.grey[500],
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

  Future<void> _updateTrip(Trip updatedTrip) async {
    setState(() {
      final index = _trips.indexWhere((trip) => trip.id == updatedTrip.id);
      if (index != -1) {
        _trips[index] = updatedTrip;
      }
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
      HomeScreen(trips: _trips, onDeleteTrip: _deleteTrip, onUpdateTrip: _updateTrip),
      SearchScreen(onAddTrip: _addTrip),
      AddTripScreen(onAddTrip: _addTrip, onTripSaved: _onTripSaved),
      MapScreen(),
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
