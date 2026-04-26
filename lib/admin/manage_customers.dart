import 'package:flutter/material.dart';
import 'package:mad/utility.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';

class ManageCustomersPage extends StatefulWidget {
  const ManageCustomersPage({super.key});

  @override
  State<ManageCustomersPage> createState() => _ManageCustomersPageState();
}

class _ManageCustomersPageState extends State<ManageCustomersPage> {
  final supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text("Customer Management", style: GoogleFonts.openSans(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchCustomersWithPoints(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.purple));
          final customers = snapshot.data ?? [];
          
          // 🛠️ Sorting Logic (Highest to Lowest points)
          customers.sort((a, b) => (b['total_points'] as int).compareTo(a['total_points'] as int));

          return SingleChildScrollView(
            child: Column(
              children: [
                // 📊 TOTAL NUMBER DISPLAY
                Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  child: Row(
                    children: [
                      const Icon(Icons.people_alt_outlined, color: Colors.purple, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        "Total Customers: ${customers.length}",
                        style: GoogleFonts.openSans(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                const SizedBox(height: 25),
                Text("Point Distribution (%)", style: GoogleFonts.openSans(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 25),
                
                // 🥧 PIE CHART
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: _buildPieSections(customers),
                    ),
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Divider(thickness: 1, indent: 20, endIndent: 20),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Align(alignment: Alignment.centerLeft, child: Text("Customer Ranking (Highest Pts)", style: GoogleFonts.openSans(fontSize: 16, fontWeight: FontWeight.bold))),
                ),
                const SizedBox(height: 15),

                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: customers.length,
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  itemBuilder: (context, index) {
                    final customer = customers[index];
                    bool isSuspended = customer['is_suspended'] ?? false;
                    int points = customer['total_points'] ?? 0;

                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 10),
                      color: isSuspended ? Colors.red.shade50 : Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.grey[200]!)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isSuspended ? Colors.grey : Colors.purple.withValues(alpha: 0.1),
                          child: Text("${index + 1}", style: TextStyle(color: isSuspended ? Colors.white : Colors.purple, fontWeight: FontWeight.bold)),
                        ),
                        title: Text(customer['nickname'] ?? 'User', style: GoogleFonts.openSans(fontWeight: FontWeight.bold, decoration: isSuspended ? TextDecoration.lineThrough : null)),
                        subtitle: Text("${customer['email']}\nPoints: $points pts"),
                        isThreeLine: true,
                        trailing: ElevatedButton(
                          onPressed: () => _confirmSuspension(customer['id'], isSuspended),
                          style: ElevatedButton.styleFrom(backgroundColor: isSuspended ? Colors.green : Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                          child: Text(isSuspended ? "Restore" : "Suspend", style: const TextStyle(color: Colors.white, fontSize: 10)),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections(List<Map<String, dynamic>> customers) {
    int totalOverallPoints = customers.fold(0, (sum, c) => sum + (c['total_points'] as int));
    if (totalOverallPoints == 0) return [PieChartSectionData(value: 100, color: Colors.grey[300], title: "No Pts", radius: 50)];

    final List<Color> colors = [Colors.purple, Colors.blue, Colors.orange, Colors.teal, Colors.pink];

    return customers.asMap().entries.take(5).map((e) {
      double percentage = (e.value['total_points'] / totalOverallPoints) * 100;
      return PieChartSectionData(
        value: percentage,
        color: colors[e.key % colors.length],
        title: "${percentage.toStringAsFixed(0)}%",
        radius: 55,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _fetchCustomersWithPoints() async {
    final users = await supabase.from('users_profile').select();
    final pointsData = await supabase.from('points').select();

    List<Map<String, dynamic>> results = [];
    for (var user in users) {
      int total = 0;
      for (var p in pointsData) {
        if (p['user_id'] == user['id']) {
          total += (int.tryParse(p['points_amount'].toString()) ?? 0);
        }
      }
      user['total_points'] = total;
      results.add(user);
    }
    return results;
  }

  void _confirmSuspension(String id, bool isSuspended) {
    if (isSuspended) {
      _toggleSuspension(id, true);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Suspend Account?"),
        content: const Text("Are you sure you want to suspend this customer? they will be unable to use the app."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
               Navigator.pop(context);
               _toggleSuspension(id, false);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Suspend", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _toggleSuspension(String id, bool currentStatus) async {
    await supabase.from('users_profile').update({'is_suspended': !currentStatus}).eq('id', id);
    setState(() {});
    Utils.snackbar(context, currentStatus ? "Account Restored" : "Account Suspended", color: currentStatus ? Colors.green : Colors.red);
  }
}
