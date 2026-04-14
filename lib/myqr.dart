import 'package:flutter/material.dart';

class MyQRPage extends StatelessWidget {
  const MyQRPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My QR"),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            /// 🪪 MEMBER CARD
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.4),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "NoSakit Pharmacy",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Member: Jin Han",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 5),
                  Text(
                    "Member ID: NS123456",
                    style: TextStyle(color: Colors.white70),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Gold Member",
                    style: TextStyle(color: Colors.amber),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            /// 🔳 QR CODE (FAKE IMAGE)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  Image.asset(
                    'assets/myqr.jpeg', // 🔥 add any QR image
                    height: 180,
                  ),
                  const SizedBox(height: 10),
                  const Text("Scan at counter"),
                ],
              ),
            ),

            const SizedBox(height: 25),

            /// ⭐ POINTS
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: const [
                  Text("Total Points",
                      style: TextStyle(fontSize: 14)),
                  SizedBox(height: 5),
                  Text(
                    "120 pts",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// 💊 HEALTH REMINDER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: const [
                  Icon(Icons.access_time, color: Colors.red),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Reminder: Take Paracetamol at 8:00 PM",
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// 🧾 LAST PURCHASE
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text("Last Purchase",
                      style:
                      TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 5),
                  Text("Vitamin C - RM25.00"),
                  Text("Date: 5 April 2026"),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// 💡 HEALTH TIP
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                "💡 Tip: Drink plenty of water when taking medication.",
              ),
            ),
          ],
        ),
      ),
    );
  }
}