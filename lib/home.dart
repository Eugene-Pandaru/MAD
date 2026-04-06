import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /// 🟢 AppBar with Logo
      appBar: AppBar(
        backgroundColor: Colors.green,
        centerTitle: true,
        title: Image.asset(
          'assets/logo.png',
          height: 40,
        ),
      ),

      /// 🟢 Body
      body: Column(
        children: [

          /// 🔹 Top Info Row
          Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [

                /// QR (smaller)
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      IconButton(
                        onPressed: () {
                          // TODO: Show QR
                        },
                        icon: const Icon(Icons.qr_code, size: 40),
                      ),
                      const Text("My QR"),
                    ],
                  ),
                ),

                /// Voucher
                Expanded(
                  flex: 3,
                  child: Column(
                    children: const [
                      Icon(Icons.card_giftcard, size: 30),
                      SizedBox(height: 5),
                      Text("0 Vouchers"),
                    ],
                  ),
                ),

                /// Points
                Expanded(
                  flex: 3,
                  child: Column(
                    children: const [
                      Icon(Icons.stars, size: 30),
                      SizedBox(height: 5),
                      Text("0 pts"),
                    ],
                  ),
                ),

                /// 👤 User Icon (right side)
                IconButton(
                  onPressed: () {
                    // TODO: Profile
                  },
                  icon: const Icon(Icons.person, size: 30),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          /// 🔹 Category Buttons (4 circles)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [

                buildCategory(Icons.medical_services, "Medicine"),
                buildCategory(Icons.health_and_safety, "Vitamin"),
                buildCategory(Icons.child_care, "Baby Care"),
                buildCategory(Icons.card_giftcard, "Rewards"),
              ],
            ),
          ),

          const SizedBox(height: 20),

          /// 🔹 Announcement
          Padding(
            padding: const EdgeInsets.all(15),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                "Announcement:\n\nWelcome to NoSakit Pharmacy App!",
                style: TextStyle(fontSize: 14),
              ),
            ),
          ),

          /// 🔹 E-Consultation Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Consultation
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: const Text("E-Consultation"),
              ),
            ),
          ),

          const Spacer(),

          /// 🔻 Bottom Navigation (Custom)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [

                buildNavItem(Icons.home, "Home", true),
                buildNavItem(Icons.medical_services, "Medicine", false),

                /// 🔴 Emergency Button
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(12),
                  child: const Icon(Icons.warning, color: Colors.white),
                ),

                buildNavItem(Icons.receipt, "Orders", false),
                buildNavItem(Icons.person, "Profile", false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🔘 Category Builder
  Widget buildCategory(IconData icon, String label) {
    return Column(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: Colors.green.shade100,
          child: Icon(icon, color: Colors.green),
        ),
        const SizedBox(height: 5),
        Text(label),
      ],
    );
  }

  /// 🔘 Bottom Nav Item
  Widget buildNavItem(IconData icon, String label, bool isActive) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: isActive ? Colors.green : Colors.grey,
        ),
        Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.green : Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}