import 'package:flutter/material.dart';

class PointsPage extends StatelessWidget {
  const PointsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Points"),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            /// ⭐ TOTAL POINTS CARD
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange, Colors.deepOrange],
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: const [
                  Text(
                    "Your Points",
                    style: TextStyle(color: Colors.white),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "120 pts",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            /// 📊 HOW TO EARN
            sectionTitle("How to Earn Points"),
            buildInfoTile(Icons.shopping_cart, "Buy Medicine", "+1 pt per RM1"),
            buildInfoTile(Icons.reviews, "Write Review", "+2 pts"),

            const SizedBox(height: 25),

            /// ⏳ EXPIRY INFO
            sectionTitle("Points Expiry"),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                "⚠️ 30 pts will expire on 30 April 2026",
              ),
            ),

            const SizedBox(height: 25),

            /// 🧾 HISTORY
            sectionTitle("Recent Activity"),
            buildHistory("+20 pts", "Medicine Purchase", "5 Apr 2026"),
            buildHistory("+10 pts", "Review Submitted", "3 Apr 2026"),
            buildHistory("-30 pts", "Redeemed Voucher", "1 Apr 2026"),

            const SizedBox(height: 25),

            /// 🔗 NAV TO REWARDS (NOT REDUNDANT)
            ElevatedButton(
              onPressed: () {
                // TODO: Navigate to Rewards page (your category page)
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text("Go to Rewards"),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔹 Section Title
  Widget sectionTitle(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  /// 🔹 Info Tile
  Widget buildInfoTile(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon, color: Colors.green),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }

  /// 🔹 History Row
  Widget buildHistory(String pts, String title, String date) {
    return ListTile(
      leading: Icon(
        pts.startsWith("+") ? Icons.add_circle : Icons.remove_circle,
        color: pts.startsWith("+") ? Colors.green : Colors.red,
      ),
      title: Text(title),
      subtitle: Text(date),
      trailing: Text(
        pts,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: pts.startsWith("+") ? Colors.green : Colors.red,
        ),
      ),
    );
  }
}