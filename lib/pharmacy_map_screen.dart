//kh

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mad/utility.dart';
import 'package:geolocator/geolocator.dart';

class PharmacyMapScreen extends StatefulWidget {
  const PharmacyMapScreen({super.key});

  @override
  State<PharmacyMapScreen> createState() => _PharmacyMapScreenState();
}

class _PharmacyMapScreenState extends State<PharmacyMapScreen> {
  final supabase = Supabase.instance.client;
  final MapController _mapController = MapController();
  
  final LatLng _center = const LatLng(3.1390, 101.6869);
  List<Map<String, dynamic>> _branches = [];
  bool _isLoading = true;
  Map<String, dynamic>? _selectedBranch;

  @override
  void initState() {
    super.initState();
    _fetchPharmacyLocations();
  }

  Future<void> _fetchPharmacyLocations() async {
    try {
      final data = await supabase.from('location').select();
      if (mounted) {
        setState(() {
          _branches = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _gotoCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Utils.snackbar(context, "Location services are disabled.", color: Colors.red);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Utils.snackbar(context, "Location permissions are denied.", color: Colors.red);
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        Utils.snackbar(context, "Location permissions are permanently denied.", color: Colors.red);
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      _mapController.move(LatLng(position.latitude, position.longitude), 15.0);
    } catch (e) {
      debugPrint("Error getting location: $e");
    }
  }

  String _getBranchImageUrl(String branchName) {
    // Construct the public URL for the branch image from Supabase Storage
    final String bucketUrl = "https://ilywlqeofnxhssnezpgw.supabase.co/storage/v1/object/public/pharmacyLocation/";
    
    if (branchName.contains("Setapak")) return "${bucketUrl}Setapak.png";
    if (branchName.contains("Cheras")) return "${bucketUrl}Cheras.png";
    if (branchName.contains("PJ")) return "${bucketUrl}PJ.png";
    
    // Default placeholder if name doesn't match
    return "https://via.placeholder.com/400x200?text=No+Image+Available";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Our Branches", style: GoogleFonts.openSans(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1392AB),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1392AB)))
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _center,
                    initialZoom: 11.0,
                    onTap: (_, __) => setState(() => _selectedBranch = null),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.mad',
                    ),
                    MarkerLayer(
                      markers: _branches.map((loc) {
                        return Marker(
                          point: LatLng(
                            double.parse(loc['latitude'].toString()),
                            double.parse(loc['longitude'].toString()),
                          ),
                          width: 50,
                          height: 50,
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _selectedBranch = loc);
                              _mapController.move(
                                LatLng(double.parse(loc['latitude'].toString()), double.parse(loc['longitude'].toString())),
                                15.0,
                              );
                            },
                            child: Icon(
                              Icons.location_on,
                              color: _selectedBranch?['id'] == loc['id'] ? Colors.blue : Colors.red,
                              size: 40,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                
                // Top Left Current Location Button
                Positioned(
                  top: 20,
                  left: 20,
                  child: FloatingActionButton(
                    mini: true,
                    backgroundColor: Colors.white,
                    onPressed: _gotoCurrentLocation,
                    child: const Icon(Icons.my_location, color: Color(0xFF1392AB)),
                  ),
                ),

                if (_selectedBranch != null) _buildBranchPreview(),
              ],
            ),
    );
  }

  Widget _buildBranchPreview() {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Card(
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      _getBranchImageUrl(_selectedBranch!['name']),
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 60, height: 60, color: Colors.grey[200],
                        child: const Icon(Icons.store, color: Color(0xFF1392AB)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_selectedBranch!['name'], style: GoogleFonts.openSans(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(_selectedBranch!['address'], maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showBranchDetails(_selectedBranch!),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1392AB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text("View More"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBranchDetails(Map<String, dynamic> branch) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.network(
                  _getBranchImageUrl(branch['name']),
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 200, width: double.infinity, color: Colors.grey[200],
                    child: const Icon(Icons.image, size: 80, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(branch['name'], style: GoogleFonts.openSans(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _detailRow(Icons.location_on, "Address", branch['address']),
              _detailRow(Icons.access_time, "Opening Hours", branch['opening_hours'] ?? "09:00 AM - 10:00 PM"),
              _detailRow(Icons.phone, "Contact", branch['phone'] ?? "+60 123456789"),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 10),
              Text("Description", style: GoogleFonts.openSans(fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Text(branch['description'] ?? "Our pharmacy provides high-quality healthcare services and authentic medicines. Our pharmacists are always here to help you.", style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF1392AB), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                Text(value, style: const TextStyle(fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
