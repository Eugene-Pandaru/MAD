import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mad/footer.dart';
import 'package:mad/utility.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RedemptionPage extends StatelessWidget {
  const RedemptionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final userId = Utils.currentUser?['id'];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 🟢 Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    "My Redemptions",
                    style: GoogleFonts.openSans(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: supabase
                    .from('user_rewards')
                    .stream(primaryKey: ['id'])
                    .eq('user_id', userId ?? ''),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF1392AB)));
                  }

                  final redemptions = snapshot.data ?? [];
                  if (redemptions.isEmpty) {
                    return Center(child: Text("You haven't redeemed any rewards yet.", style: GoogleFonts.openSans(color: Colors.grey)));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: redemptions.length,
                    itemBuilder: (context, index) {
                      final item = redemptions[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8DC6BC).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF8DC6BC).withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['reward_name'] ?? "Reward", style: GoogleFonts.openSans(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text("Redeemed on: ${item['created_at'].toString().split('T')[0]}", style: GoogleFonts.openSans(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                              decoration: BoxDecoration(color: const Color(0xFF1392AB), borderRadius: BorderRadius.circular(10)),
                              child: Text(
                                item['redemption_code'] ?? "CODE",
                                style: GoogleFonts.openSans(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
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
}
