import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:geocoding/geocoding.dart' as geo;

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
    print("!!! DEBUG: Starting GPS Request...");

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

      // 3. Get Location with a faster setting
      // We use changeSettings to tell it we don't need "Military Grade" accuracy
      await _location.changeSettings(accuracy: LocationAccuracy.balanced);

      // We add a timeout so it doesn't hang forever
      final data = await _location.getLocation().timeout(const Duration(seconds: 10));

      print("!!! DEBUG: GPS Coordinates received: ${data.latitude}, ${data.longitude}");

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
      print("!!! DEBUG: GPS ERROR: $e");
      setState(() => _isGettingLocation = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("GPS Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Delivery Location"), backgroundColor: Colors.green),
      body: Column(
        children: [
          // 1. MAP SECTION
          Expanded(
            flex: 3,
            child: FlutterMap(
              mapController: _mapController, // LINK THE CONTROLLER
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
                    child: ElevatedButton.icon(
                      onPressed: _isGettingLocation ? null : _getCurrentLocation,
                      icon: _isGettingLocation
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.gps_fixed),
                      label: Text(_isGettingLocation ? "Searching GPS..." : "Use Current GPS Location"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text("DELIVER TO:", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(
                    _addressLabel,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, _addressLabel),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: const Text("Confirm Address", style: TextStyle(color: Colors.white, fontSize: 16)),
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