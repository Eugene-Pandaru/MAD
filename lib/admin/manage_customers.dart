import 'package:flutter/material.dart';
import 'package:mad/utility.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';

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
      appBar: AppBar(
        title: const Text("Customer Management"),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchCustomersWithPoints(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final customers = snapshot.data ?? [];

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                const Text("Customer Loyalty (Points)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                
                // 📊 CHART FIX
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    height: 200,
                    child: BarChart(
                      BarChartData(
                        barGroups: customers.asMap().entries.map((e) {
                          return BarChartGroupData(x: e.key, barRods: [
                            BarChartRodData(toY: (e.value['total_points'] ?? 0).toDouble(), color: Colors.purple, width: 15)
                          ]);
                        }).toList(),
                        titlesData: FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        gridData: FlGridData(show: false),
                      ),
                    ),
                  ),
                ),

                const Divider(height: 40),

                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: customers.length,
                  padding: const EdgeInsets.all(10),
                  itemBuilder: (context, index) {
                    final customer = customers[index];
                    bool isSuspended = customer['is_suspended'] ?? false;

                    return Card(
                      color: isSuspended ? Colors.red.shade50 : Colors.white,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isSuspended ? Colors.red : Colors.purple,
                          child: const Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text(customer['nickname'] ?? 'User', style: TextStyle(fontWeight: FontWeight.bold, decoration: isSuspended ? TextDecoration.lineThrough : null)),
                        subtitle: Text("${customer['email']}\nPoints: ${customer['total_points'] ?? 0} pts"),
                        isThreeLine: true,
                        trailing: ElevatedButton(
                          onPressed: () => _toggleSuspension(customer['id'], isSuspended),
                          style: ElevatedButton.styleFrom(backgroundColor: isSuspended ? Colors.green : Colors.red),
                          child: Text(isSuspended ? "Unsuspend" : "Suspend", style: const TextStyle(color: Colors.white, fontSize: 10)),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchCustomersWithPoints() async {
    final users = await supabase.from('users_profile').select();
    final pointsData = await supabase.from('points').select();

    List<Map<String, dynamic>> results = [];
    for (var user in users) {
      int total = 0;
      for (var p in pointsData) {
        if (p['user_id'] == user['id']) {
          total += (p['points_amount'] as int);
        }
      }
      user['total_points'] = total;
      results.add(user);
    }
    return results;
  }

  void _toggleSuspension(String id, bool currentStatus) async {
    await supabase.from('users_profile').update({'is_suspended': !currentStatus}).eq('id', id);
    setState(() {});
    Utils.snackbar(context, currentStatus ? "Account Restored" : "Account Suspended", color: currentStatus ? Colors.green : Colors.red);
  }
}
