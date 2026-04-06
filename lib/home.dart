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

                /// QR
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      IconButton(
                        onPressed: () {},
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

                /// Profile Icon
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.person, size: 30),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          /// 🔹 Categories
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

          /// 🔹 E-Consultation
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: const Text("E-Consultation"),
              ),
            ),
          ),

          const Spacer(),

          /// 🔻 Bottom Navigation (FINAL FIXED)
          Stack(
            alignment: Alignment.bottomCenter,
            clipBehavior: Clip.none,
            children: [

              /// 🟢 Footer Bar
              Container(
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: const Border(
                    top: BorderSide(color: Colors.grey, width: 0.5),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  children: [

                    buildNavItem(Icons.home, "Home", true),
                    buildNavItem(Icons.medical_services, "Medicine", false),

                    const SizedBox(width: 70),

                    buildNavItem(Icons.receipt, "Orders", false),
                    buildNavItem(Icons.person, "Profile", false),
                  ],
                ),
              ),

              /// 🔴 Floating Emergency Button
              Positioned(
                top: -30,
                child: GestureDetector(
                  onTap: () {
                    // TODO: Emergency action
                  },
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.4),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.warning,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 🔘 Category Button
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
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 26,
            color: isActive ? Colors.green : Colors.grey,
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight:
              isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? Colors.green : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}