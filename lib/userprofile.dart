import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mad/editprofile.dart';
import 'package:mad/footer.dart';
import 'package:mad/startpage.dart';
import 'package:mad/orderhistory.dart';
import 'package:mad/points.dart';
import 'package:mad/utility.dart';
import 'package:mad/vouchers.dart';
import 'package:mad/redemption.dart'; // 👈 Import Redemption

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  @override
  Widget build(BuildContext context) {
    final user = Utils.currentUser;

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
                    "Profile",
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    /// 👤 Profile Header Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: const Color(0xFF1392AB).withValues(alpha: 0.1),
                            child: const Icon(Icons.person, size: 50, color: Color(0xFF1392AB)),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user?['nickname'] ?? "Guest",
                                  style: GoogleFonts.openSans(fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  user?['email'] ?? "No Email",
                                  style: GoogleFonts.openSans(fontSize: 14, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    /// 🛠 Settings List
                    _buildProfileItem(
                      icon: Icons.edit_outlined,
                      title: "Edit Profile",
                      onTap: () async {
                        await Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfilePage()));
                        setState(() {});
                      },
                    ),
                    _buildProfileItem(
                      icon: Icons.receipt_long_outlined,
                      title: "My Orders",
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const OrderHistoryPage()));
                      },
                    ),
                    _buildProfileItem(
                      icon: Icons.redeem_outlined, // 👈 New Redemption Item
                      title: "Redemption",
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const RedemptionPage()));
                      },
                    ),
                    _buildProfileItem(
                      icon: Icons.confirmation_number_outlined,
                      title: "My Vouchers",
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const VouchersPage()));
                      },
                    ),
                    _buildProfileItem(
                      icon: Icons.stars_outlined,
                      title: "My Points",
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const PointsPage()));
                      },
                    ),
                    const Divider(height: 40),
                    _buildProfileItem(
                      icon: Icons.logout,
                      title: "Logout",
                      textColor: Colors.red,
                      iconColor: Colors.red,
                      onTap: () {
                        Utils.currentUser = null;
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const Startpage()),
                          (route) => false,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const Footer(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? const Color(0xFF1392AB)),
        title: Text(
          title,
          style: GoogleFonts.openSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }
}
