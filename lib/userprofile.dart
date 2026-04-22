import 'package:flutter/material.dart';
import 'package:mad/editprofile.dart';
import 'package:mad/footer.dart';
import 'package:mad/login.dart';
import 'package:mad/orderhistory.dart';
import 'package:mad/points.dart';
import 'package:mad/utility.dart';
import 'package:mad/vouchers.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  @override
  Widget build(BuildContext context) {
    // Get the current user data from Utils
    final user = Utils.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("User Profile"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 30),

                  /// 👤 Profile Header
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.green,
                    child: Icon(Icons.person, size: 60, color: Colors.white),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    user?['nickname'] ?? "Guest",
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    user?['email'] ?? "No Email",
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 30),

                  /// 🛠 Settings List
                  buildProfileItem(
                    icon: Icons.edit,
                    title: "Edit Profile",
                    onTap: () async {
                      // 🔄 Wait for the edit page to close
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const EditProfilePage()),
                      );
                      // 🔄 Rebuild the page with new data
                      setState(() {});
                    },
                  ),
                  buildProfileItem(
                    icon: Icons.receipt_long,
                    title: "My Orders",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const OrderHistoryPage()),
                      );
                    },
                  ),
                  buildProfileItem(
                    icon: Icons.card_giftcard,
                    title: "My Vouchers",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const VouchersPage()),
                      );
                    },
                  ),
                  buildProfileItem(
                    icon: Icons.stars,
                    title: "My Points",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PointsPage()),
                      );
                    },
                  ),
                  const Divider(),
                  buildProfileItem(
                    icon: Icons.logout,
                    title: "Logout",
                    textColor: Colors.red,
                    iconColor: Colors.red,
                    onTap: () {
                      // Clear user data on logout
                      Utils.currentUser = null;

                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginPage()),
                        (route) => false,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          /// 🔻 Footer
          const Footer(),
        ],
      ),
    );
  }

  /// 🔘 Profile List Item Builder
  Widget buildProfileItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Colors.green),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }
}
