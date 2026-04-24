//kh

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HealthDashboard extends StatefulWidget {
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

  // 1. READ - Get address from Supabase
  Future<void> _fetchAddress() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    final data = await supabase.from('profiles').select('address').eq('id', userId).single();
    setState(() {
      _currentAddress = data['address'] ?? "No address set";
      _addressController.text = _currentAddress;
    });
  }

  // 2. UPDATE - Save address to Supabase (Member 3 CRUD requirement)
  Future<void> _saveAddress() async {
    final userId = supabase.auth.currentUser?.id;
    await supabase.from('profiles').upsert({
      'id': userId,
      'address': _addressController.text,
    });
    setState(() {
      _currentAddress = _addressController.text;
      _isEditing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Address updated successfully!")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Health Dashboard"), backgroundColor: Colors.green),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text("Medicine Adherence Rate", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            /// 📊 CHART (Requirement: Visualization)
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(value: 70, color: Colors.green, title: "Taken", radius: 50),
                    PieChartSectionData(value: 30, color: Colors.red, title: "Missed", radius: 50),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),
            const Divider(),

            /// 🏠 ADDRESS MANAGEMENT (Requirement: Save and manage user address)
            ListTile(
              leading: const Icon(Icons.location_on, color: Colors.green),
              title: const Text("Saved Home Address"),
              subtitle: _isEditing
                  ? TextField(controller: _addressController)
                  : Text(_currentAddress),
              trailing: IconButton(
                icon: Icon(_isEditing ? Icons.check : Icons.edit, color: Colors.blue),
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
              TextButton(onPressed: () => setState(() => _isEditing = false), child: const Text("Cancel"))
          ],
        ),
      ),
    );
  }
}