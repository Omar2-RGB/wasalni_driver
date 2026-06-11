import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'car_setup_screen.dart';
import 'chat_screen.dart';
import 'custom_drawer.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';

class RadarScreen extends StatefulWidget {
  const RadarScreen({super.key});

  @override
  State<RadarScreen> createState() => _RadarScreenState();
}

class _RadarScreenState extends State<RadarScreen> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _myRides = [];
  bool _isOnline = true;
  String? _myDriverId;

  final String googleApiKey = "AIzaSyDl1WIXn9SX8oGMURam3-tQmPle4rvHX7s";
  final Set<Polyline> _polylines = {};
  final PolylinePoints polylinePoints = PolylinePoints();

  // متغير للتحكم ببث الموقع
  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _checkProfileCompletion();
    _initDriver();
  }

  @override
  void dispose() {
    _stopLocationTracking();
    super.dispose();
  }

  Future<void> _checkProfileCompletion() async {
    final prefs = await SharedPreferences.getInstance();
    final driverId = prefs.getString('driver_id');
    
    if (driverId == null) return;

    final profile = await supabase
        .from('driver_profiles')
        .select()
        .eq('user_id', driverId)
        .maybeSingle();

    if (profile == null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const CarSetupScreen()),
      );
    }
  }

  Future<void> _initDriver() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _myDriverId = prefs.getString('driver_id'));
    if (_myDriverId != null) _listenToMyRides();
  }

  void _listenToMyRides() {
    supabase.from('rides')
        .stream(primaryKey: ['id'])
        .eq('driver_id', _myDriverId!)
        .listen((data) {
          if (_isOnline && mounted) {
            setState(() => _myRides = data.where((r) => r['status'] != 'completed' && r['status'] != 'cancelled').toList());
          }
        });
  }

  // --- دوال التتبع اللحظي ---
  Future<void> _startLocationTracking(String rideId) async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // تحديث كل 10 أمتار
      ),
    ).listen((Position position) async {
      if (mounted) {
        await supabase.from('rides').update({
          'driver_lat': position.latitude,
          'driver_lng': position.longitude,
        }).eq('id', rideId);
      }
    });
  }

  void _stopLocationTracking() {
    _positionStream?.cancel();
    _positionStream = null;
  }

  Future<void> _getPolyline(double startLat, double startLng) async {
    LatLng driverLoc = const LatLng(33.51, 36.27); 
    LatLng passengerLoc = LatLng(startLat, startLng);

    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      googleApiKey: googleApiKey,
      request: PolylineRequest(
        origin: PointLatLng(driverLoc.latitude, driverLoc.longitude),
        destination: PointLatLng(passengerLoc.latitude, passengerLoc.longitude),
        mode: TravelMode.driving,
      ),
    );

    if (result.points.isNotEmpty) {
      setState(() {
        _polylines.clear();
        _polylines.add(Polyline(
          polylineId: const PolylineId('route'),
          points: result.points.map((e) => LatLng(e.latitude, e.longitude)).toList(),
          color: const Color(0xFF38BDF8),
          width: 6,
        ));
      });
    }
  }

  Future<void> _updateRideStatus(Map<String, dynamic> ride, String newStatus) async {
    await supabase.from('rides').update({'status': newStatus}).eq('id', ride['id']);
    
    if (newStatus == 'accepted') {
      _getPolyline(ride['start_lat']?.toDouble() ?? 33.51, ride['start_lng']?.toDouble() ?? 36.27);
      _startLocationTracking(ride['id'].toString()); 
    } else if (newStatus == 'completed' || newStatus == 'cancelled') {
      _stopLocationTracking(); 
      setState(() => _polylines.clear());
    }
  }

  // بناء زر المحادثة الخاص بالكابتن
  Widget _buildChatButton(String rideId) {
    return SizedBox(
      width: double.infinity, 
      height: 50, 
      child: OutlinedButton.icon(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen(rideId: rideId, myUserId: _myDriverId!))),
        icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFF38BDF8)),
        label: const Text('مراسلة الراكب 💬', style: TextStyle(color: Color(0xFF38BDF8), fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF38BDF8), width: 2), 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
        ),
      ),
    );
  }

  // منطق التحكم بالأزرار حسب حالة الرحلة
  Widget _buildActionArea(Map<String, dynamic> ride) {
    switch (ride['status']) {
      case 'pending':
        return SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: () => _updateRideStatus(ride, 'accepted'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF38BDF8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            child: const Text('قبول الطلب 🚖', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 16)),
          ),
        );
      case 'accepted':
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () => _updateRideStatus(ride, 'completed'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: const Text('إنهاء الرحلة 🏁', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 16)),
              ),
            ),
            const SizedBox(height: 12),
            _buildChatButton(ride['id'].toString()), // هنا تظهر المحادثة للكابتن بعد القبول
          ],
        );
      default:
        return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1120),
      drawer: const CustomDrawer(),
      appBar: AppBar(backgroundColor: const Color(0xFF0B1120), title: const Text('رادار الرحلات 📡', style: TextStyle(color: Colors.white, fontFamily: 'Cairo')), centerTitle: true),
      body: _myRides.isEmpty ? const Center(child: Text('بانتظار طلبات... 🔍', style: TextStyle(color: Colors.white70, fontFamily: 'Cairo')))
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _myRides.length,
              itemBuilder: (context, index) {
                final ride = _myRides[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(20)),
                  child: Column(
                    children: [
                      if (ride['status'] == 'accepted') 
                        Container(
                          height: 160, 
                          margin: const EdgeInsets.only(bottom: 15),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: GoogleMap(initialCameraPosition: const CameraPosition(target: LatLng(33.51, 36.27), zoom: 13), polylines: _polylines),
                          ),
                        ),
                      Text('الحالة الحالية: ${ride['status']}', style: const TextStyle(color: Colors.white70, fontFamily: 'Cairo', fontSize: 15)),
                      const SizedBox(height: 15),
                      _buildActionArea(ride),
                    ],
                  ),
                );
              },
            ),
    );
  }
}