import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mad/footer.dart';
import 'package:mad/utility.dart';
import 'package:mad/redemption.dart'; // 👈 Import RedemptionPage
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';

class RewardsPage extends StatefulWidget {
  const RewardsPage({super.key});

  @override
  State<RewardsPage> createState() => _RewardsPageState();
}

class _RewardsPageState extends State<RewardsPage> {
  final supabase = Supabase.instance.client;
  int userTotalPts = 0;

  String _generateCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    return String.fromCharCodes(Iterable.generate(6, (_) => chars.codeUnitAt(Random().nextInt(chars.length))));
  }

  Future<void> _redeemReward(Map<String, dynamic> reward) async {
    final userId = Utils.currentUser?['id'];
    int required = reward['points_required'] ?? 0;

    try {
      // 1. Insert negative points record
      await supabase.from('points').insert({
        'user_id': userId,
        'points_amount': -required,
        'reason': "Redeemed ${reward['name']}",
      });

      // 2. Create user_rewards record
      await supabase.from('user_rewards').insert({
        'user_id': userId,
        'reward_name': reward['name'],
        'redemption_code': _generateCode(),
      });

      if (mounted) {
        Utils.snackbar(context, "Successfully redeemed ${reward['name']}!", color: Colors.green);
        // 🚀 Redirect to Redemption Page immediately
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const RedemptionPage()));
      }
    } catch (e) {
      if (mounted) Utils.snackbar(context, "Redemption failed. Please try again.", color: Colors.red);
    }
  }

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
                  Text("Rewards", style: GoogleFonts.openSans(fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
            ),

            StreamBuilder<List<Map<String, dynamic>>>(
              stream: supabase.from('points').stream(primaryKey: ['id']).eq('user_id', userId ?? ''),
              builder: (context, snapshot) {
                userTotalPts = 0;
                if (snapshot.hasData) {
                  userTotalPts = snapshot.data!.fold(0, (sum, item) => sum + (int.tryParse(item['points_amount'].toString()) ?? 0));
                }
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(color: const Color(0xFF1392AB), borderRadius: BorderRadius.circular(20)),
                  child: Column(
                    children: [
                      Text("Your Total Points", style: GoogleFonts.openSans(color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 5),
                      Text("$userTotalPts pts", style: GoogleFonts.openSans(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              },
            ),

            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: supabase.from('rewards').stream(primaryKey: ['id']).order('points_required'),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  final rewards = snapshot.data ?? [];

                  return ListView.builder(
                    itemCount: rewards.length,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemBuilder: (context, index) {
                      final r = rewards[index];
                      int required = r['points_required'] ?? 0;
                      bool canRedeem = userTotalPts >= required;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            const CircleAvatar(backgroundColor: Colors.orange, child: Icon(Icons.card_giftcard, color: Colors.white)),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(r['name'] ?? "Reward", style: GoogleFonts.openSans(fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text("${r['description']}", style: GoogleFonts.openSans(fontSize: 12, color: Colors.grey)),
                                  const SizedBox(height: 5),
                                  Text("Requires: $required pts", style: GoogleFonts.openSans(fontSize: 12, color: const Color(0xFF1392AB), fontWeight: FontWeight.bold)),
                                  if (!canRedeem)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 5),
                                      child: Text(
                                        "Unable to redeem. You need more ${required - userTotalPts} pts",
                                        style: GoogleFonts.openSans(fontSize: 11, color: Colors.red, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: canRedeem ? () => _redeemReward(r) : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: canRedeem ? const Color(0xFF1392AB) : Colors.grey.shade300,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: Text("Claim", style: GoogleFonts.openSans(color: Colors.white, fontSize: 12)),
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
