import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mad/footer.dart';
import 'package:mad/utility.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PointsPage extends StatefulWidget {
  const PointsPage({super.key});

  @override
  State<PointsPage> createState() => _PointsPageState();
}

class _PointsPageState extends State<PointsPage> {
  final supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    final userId = Utils.currentUser?['id'];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text("My Points", style: GoogleFonts.openSans(fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
            ),

            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: supabase.from('points').stream(primaryKey: ['id']).eq('user_id', userId ?? ''),
                builder: (context, snapshot) {
                  int totalPts = 0;
                  List<Map<String, dynamic>> history = [];

                  if (snapshot.hasData) {
                    history = List<Map<String, dynamic>>.from(snapshot.data!);
                    history.sort((a, b) => b['created_at'].compareTo(a['created_at']));
                    totalPts = history.fold(0, (sum, item) => sum + (int.tryParse(item['points_amount'].toString()) ?? 0));
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(30),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1392AB),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: const Color(0xFF1392AB).withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 5))],
                          ),
                          child: Column(
                            children: [
                              Text("Your Points", style: GoogleFonts.openSans(color: Colors.white, fontSize: 16)),
                              const SizedBox(height: 10),
                              Text("$totalPts pts", style: GoogleFonts.openSans(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white)),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  "Earn Rate: RM 1.00 = 10 pts",
                                  style: GoogleFonts.openSans(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                        _sectionTitle("Recent Activity"),
                        if (history.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Text("No points records found for this user.", style: GoogleFonts.openSans(color: Colors.grey)),
                          )
                        else
                          ...history.map((item) {
                            int amount = int.tryParse(item['points_amount'].toString()) ?? 0;
                            String prefix = amount >= 0 ? "+" : "";
                            String date = item['created_at'].toString().split('T')[0];
                            return _buildHistoryRow("$prefix$amount pts", item['reason'] ?? "Activity", date);
                          }),
                        const SizedBox(height: 40),
                      ],
                    ),
                  );
                },
              ),
            ),
            const Footer(),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Align(alignment: Alignment.centerLeft, child: Padding(padding: const EdgeInsets.only(bottom: 15), child: Text(text, style: GoogleFonts.openSans(fontWeight: FontWeight.bold, fontSize: 18))));
  }

  Widget _buildHistoryRow(String pts, String title, String date) {
    bool isAdd = pts.startsWith("+");
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: Icon(isAdd ? Icons.add_circle_outline : Icons.remove_circle_outline, color: isAdd ? Colors.green : Colors.red),
        title: Text(title, style: GoogleFonts.openSans(fontWeight: FontWeight.w600)),
        subtitle: Text(date, style: GoogleFonts.openSans(fontSize: 12)),
        trailing: Text(pts, style: GoogleFonts.openSans(fontWeight: FontWeight.bold, fontSize: 16, color: isAdd ? Colors.green : Colors.red)),
      ),
    );
  }
}
