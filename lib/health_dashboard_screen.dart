import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mad/utility.dart';
import 'package:mad/notification_service.dart'; // 👈 Import Notification
import 'package:supabase_flutter/supabase_flutter.dart';

class HealthDashboard extends StatefulWidget {
  const HealthDashboard({super.key});

  @override
  State<HealthDashboard> createState() => _HealthDashboardState();
}

class _HealthDashboardState extends State<HealthDashboard> {
  final supabase = Supabase.instance.client;
  final TextEditingController _addressController = TextEditingController();
  bool _isEditing = false;
  String _currentAddress = "Loading...";

  @override
  void initState() {
    super.initState();
    _fetchAddress();
  }

  Future<void> _fetchAddress() async {
    final userId = Utils.currentUser?['id'];
    if (userId == null) return;

    try {
      final data = await supabase
          .from('users_profile')
          .select('address')
          .eq('id', userId)
          .maybeSingle();

      if (data != null && mounted) {
        setState(() {
          _currentAddress = data['address'] ?? "No address set";
          _addressController.text = _currentAddress;
        });
      }
    } catch (e) {
      debugPrint("Error fetching address: $e");
    }
  }

  Future<void> _saveAddress() async {
    final userId = Utils.currentUser?['id'];
    if (userId == null) return;

    try {
      await supabase.from('users_profile').update({
        'address': _addressController.text,
      }).eq('id', userId);

      if (Utils.currentUser != null) {
        Utils.currentUser!['address'] = _addressController.text;
      }

      setState(() {
        _currentAddress = _addressController.text;
        _isEditing = false;
      });
      if (mounted) {
        Utils.snackbar(context, "Address updated successfully!", color: Colors.green);
      }
    } catch (e) {
      if (mounted) {
        Utils.snackbar(context, "Failed to update address", color: Colors.red);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Health Dashboard", style: GoogleFonts.openSans(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1392AB), // 🛠️ Blue Header
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text("Medicine Adherence Rate", style: GoogleFonts.openSans(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            /// 📊 CHART
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(value: 70, color: const Color(0xFF1392AB), title: "70%", radius: 50, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    PieChartSectionData(value: 30, color: Colors.red, title: "30%", radius: 50, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),
            const Divider(),

            /// 🏠 ADDRESS MANAGEMENT
            ListTile(
              leading: const Icon(Icons.location_on, color: Color(0xFF1392AB)),
              title: Text("Saved Home Address", style: GoogleFonts.openSans(fontWeight: FontWeight.bold)),
              subtitle: _isEditing
                  ? TextField(controller: _addressController, decoration: const InputDecoration(hintText: "Enter your address"))
                  : Text(_currentAddress, style: GoogleFonts.openSans()),
              trailing: IconButton(
                icon: Icon(_isEditing ? Icons.check : Icons.edit, color: const Color(0xFF1392AB)),
                onPressed: () {
                  if (_isEditing) {
                    _saveAddress();
                  } else {
                    setState(() => _isEditing = true);
                  }
                },
              ),
            ),

            if (_isEditing)
              TextButton(onPressed: () => setState(() => _isEditing = false), child: const Text("Cancel")),

            const SizedBox(height: 40),
            
            /// 🔔 NOTIFICATION TEST
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await NotificationService().scheduleNotification(1, "Health Reminder", "Don't forget to take your medicine!");
                  if (mounted) Utils.snackbar(context, "Notification Scheduled (10s)", color: const Color(0xFF1392AB));
                },
                icon: const Icon(Icons.notifications_active),
                label: const Text("Test Health Notification"),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1392AB), foregroundColor: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
