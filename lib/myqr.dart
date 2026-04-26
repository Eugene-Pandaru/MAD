import 'package:flutter/material.dart';
import 'package:mad/utility.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class MyQRPage extends StatelessWidget {
  const MyQRPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Utils.currentUser;
    final supabase = Supabase.instance.client;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("My QR Member", style: GoogleFonts.openSans(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1392AB),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            /// 🪪 MEMBER CARD
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1392AB), Color(0xFF107A8A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1392AB).withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "NoSakit Pharmacy",
                    style: TextStyle(color: Colors.white, fontSize: 16, letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    user?['nickname'] ?? "Guest User",
                    style: GoogleFonts.openSans(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Member ID: ${user?['id']}",
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 15),
                  const Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      "Gold Member",
                      style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            /// 🔳 QR CODE
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)
                ],
              ),
              child: Column(
                children: [
                  Image.asset(
                    'assets/myqr.jpeg',
                    height: 200,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "Scan at counter to collect points",
                    style: GoogleFonts.openSans(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            /// ⭐ POINTS
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: supabase.from('points').stream(primaryKey: ['id']).eq('user_id', user?['id'] ?? ''),
              builder: (context, snapshot) {
                int totalPts = 0;
                if (snapshot.hasData) {
                  totalPts = snapshot.data!.fold(0, (sum, item) => sum + (int.tryParse(item['points_amount'].toString()) ?? 0));
                }
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.orange.shade100),
                  ),
                  child: Column(
                    children: [
                      const Text("Current Points Balance", style: TextStyle(fontSize: 14, color: Colors.orange)),
                      const SizedBox(height: 8),
                      Text(
                        "$totalPts pts",
                        style: GoogleFonts.openSans(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            /// 💊 HEALTH TIP
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF8DC6BC).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFF8DC6BC).withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline, color: Color(0xFF1392AB)),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      "💡 Tip: Maintain a balanced diet and stay hydrated for better results with your medication.",
                      style: GoogleFonts.openSans(fontSize: 13, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
