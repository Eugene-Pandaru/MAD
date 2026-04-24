import 'package:flutter/material.dart';
import 'package:mad/myqr.dart';
import 'package:mad/utility.dart';
import 'package:mad/vouchers.dart';
import 'package:mad/points.dart';
import 'package:mad/userprofile.dart';
import 'orderhistory.dart';
import 'chatbot.dart';
import 'productlist.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Widget buildDivider() {
    return Container(height: 40, width: 1, color: Colors.grey.shade300);
  }

  @override
  Widget build(BuildContext context) {
    // Get current user nickname
    final String nickname = Utils.currentUser?['nickname'] ?? "User";

    return Scaffold(

      /// 🟢 AppBar with Logo
      appBar: AppBar(
        backgroundColor: Colors.green,
        centerTitle: true,
        title: Image.asset('assets/logo.png', height: 40),
      ),

      /// 🟢 Body
      body: Column(
        children: [

          /// 🔹 Top Info Card
          Padding(
            padding: const EdgeInsets.all(15),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
              ),
              child: Row(
                children: [

                  /// 🔳 MyQR (WITH RIGHT BORDER)
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(color: Colors.grey.shade500),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MyQRPage(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.qr_code, size: 40),
                          ),
                          const Text("My QR"),
                        ],
                      ),
                    ),
                  ),

                  /// 🔹 Right Side (3 equal items)
                  Expanded(
                    flex: 6,
                    child: Row(
                      children: [

                        /// Voucher
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => VouchersPage(),
                                ),
                              );
                            },

                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.card_giftcard, size: 30),
                                SizedBox(height: 5),
                                Text("5 Vouchers"),
                              ],
                            ),
                          ),
                        ),

                        /// Points
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PointsPage(),
                                ),
                              );
                            },

                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.stars, size: 30),
                                SizedBox(height: 5),
                                Text("120 pts"),
                              ],
                            ),
                          ),
                        ),

                        /// Profile
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const UserProfilePage(),
                                ),
                              );
                            },
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.person, size: 30),
                                SizedBox(height: 5),
                                Text("Profile"),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          /// 🔹 Welcome Message
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Hello, $nickname!",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          const SizedBox(height: 10),

          /// 🔹 Categories
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                InkWell(
                  onTap: () =>
                      Navigator.push(context, MaterialPageRoute(
                          builder: (context) => const ProductListPage())),
                  child: buildCategory(Icons.medical_services, "Product"),
                ),
                buildCategory(Icons.health_and_safety, "Location"),
                InkWell(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatBotPage())),
                  child: buildCategory(Icons.child_care, "Pharmacy Bot"),
                ),
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
              child: Text(
                "Announcement:\n\nWelcome back to NoSakit Pharmacy App, $nickname!",
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),

          const Spacer(), // Pushes everything below to the bottom

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
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                ),
                child: Row(
                  children: [
                    buildNavItem(Icons.home, "Home", true),
                    buildNavItem(Icons.medical_services, "Medicine", false, onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ProductListPage()),
                      );
                    }),

                    const SizedBox(width: 70),

                    buildNavItem(Icons.receipt, "Orders", false, onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (
                            context) => const OrderHistoryPage()),
                      );
                    }),
                    buildNavItem(Icons.person, "Profile", false, onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const UserProfilePage()),
                      );
                    }),
                  ],
                ),
              ),

              ///  Floating ADDDDDDDDD Button
              Positioned(
                top: -30,
                child: GestureDetector(
                  onTap: () {
                    // TODO: Add action
                  },
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.lightBlue.withValues(alpha: 0.4),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add,
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
  Widget buildNavItem(IconData icon, String label, bool isActive,
      {VoidCallback? onTap}) {
    return Expanded(
      child: InkWell( // We wrap it in InkWell to make it clickable
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 26, color: isActive ? Colors.green : Colors.grey),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? Colors.green : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
