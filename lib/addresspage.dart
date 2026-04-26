import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:google_fonts/google_fonts.dart';
import 'package:mad/utility.dart'; // 👈 Added import

class AddressPage extends StatefulWidget {
  const AddressPage({super.key});

  @override
  State<AddressPage> createState() => _AddressPageState();
}

class _AddressPageState extends State<AddressPage> {
  // Default to KL if GPS isn't ready
  LatLng _currentPoint = const LatLng(3.1390, 101.6869);
  String _addressLabel = "Select a location on the map";

  final MapController _mapController = MapController();
  final Location _location = Location();
  bool _isGettingLocation = false; // To show a loading spinner

  // Function to convert LatLng numbers to a real Address name
  Future<void> _getAddressFromLatLng(LatLng point) async {
    try {
      List<geo.Placemark> placemarks = await geo.placemarkFromCoordinates(point.latitude, point.longitude);
      if (placemarks.isNotEmpty) {
        geo.Placemark place = placemarks[0];
        setState(() {
          _addressLabel = "${place.name}, ${place.street}, ${place.locality}, ${place.postalCode}";
        });
      }
    } catch (e) {
      setState(() {
        _addressLabel = "Lat: ${point.latitude.toStringAsFixed(4)}, Lng: ${point.longitude.toStringAsFixed(4)}";
      });
    }
  }

  // --- THE GPS FUNCTION ---
  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);

    try {
      // 1. Check Service
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          setState(() => _isGettingLocation = false);
          return;
        }
      }

      // 2. Check Permission
      PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          setState(() => _isGettingLocation = false);
          return;
        }
      }

      // 3. Get Location
      await _location.changeSettings(accuracy: LocationAccuracy.balanced);
      final data = await _location.getLocation().timeout(const Duration(seconds: 20));

      if (data.latitude != null && data.longitude != null) {
        LatLng newPoint = LatLng(data.latitude!, data.longitude!);

        setState(() {
          _currentPoint = newPoint;
          _isGettingLocation = false;
        });

        // Move the map camera immediately
        _mapController.move(newPoint, 17.0);

        // Try to get the text address
        _getAddressFromLatLng(newPoint);
      }
    } catch (e) {
      setState(() => _isGettingLocation = false);
      if (mounted) {
        // 🛠️ Updated to use modern floating snackbar from Utils
        Utils.snackbar(context, "GPS Error: $e", color: Colors.red);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Select Location", style: GoogleFonts.openSans(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF1392AB),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // 1. MAP SECTION
          Expanded(
            flex: 3,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentPoint,
                initialZoom: 15,
                onTap: (tapPos, point) {
                  setState(() => _currentPoint = point);
                  _getAddressFromLatLng(point);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.mad',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentPoint,
                      width: 60,
                      height: 60,
                      child: const Icon(Icons.location_on, color: Colors.red, size: 45),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 2. DETAILS SECTION
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isGettingLocation ? null : _getCurrentLocation,
                      icon: _isGettingLocation
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.my_location),
                      label: Text(_isGettingLocation ? "Locating..." : "Use Current Location", style: GoogleFonts.openSans(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1392AB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text("SELECTED ADDRESS:", style: GoogleFonts.openSans(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 10),
                  Text(
                    _addressLabel,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.openSans(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, _addressLabel),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1392AB),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: Text("Select This Location", style: GoogleFonts.openSans(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
