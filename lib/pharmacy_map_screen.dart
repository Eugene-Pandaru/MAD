import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mad/utility.dart';

class PharmacyMapScreen extends StatefulWidget {
  const PharmacyMapScreen({super.key});

  @override
  State<PharmacyMapScreen> createState() => _PharmacyMapScreenState();
}

class _PharmacyMapScreenState extends State<PharmacyMapScreen> {
  final supabase = Supabase.instance.client;
  final MapController _mapController = MapController();
  
  // Center of Malaysia/KL
  final LatLng _center = const LatLng(3.1390, 101.6869);
  List<Marker> _markers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPharmacyLocations();
  }

  Future<void> _fetchPharmacyLocations() async {
    try {
      final data = await supabase.from('location').select();
      final List<Map<String, dynamic>> locations = List<Map<String, dynamic>>.from(data);

      if (mounted) {
        setState(() {
          _markers = locations.map((loc) {
            return Marker(
              point: LatLng(
                double.parse(loc['latitude'].toString()),
                double.parse(loc['longitude'].toString()),
              ),
              width: 50,
              height: 50,
              child: GestureDetector(
                onTap: () {
                  Utils.snackbar(context, "${loc['name']}\n${loc['address']}", color: const Color(0xFF1392AB));
                },
                child: const Icon(Icons.location_on, color: Colors.red, size: 40),
              ),
            );
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Our Branches", style: GoogleFonts.openSans(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1392AB),
        foregroundColor: Colors.white,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1392AB)))
          : FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _center,
                initialZoom: 11.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.mad',
                ),
                MarkerLayer(markers: _markers),
              ],
            ),
    );
  }
}
