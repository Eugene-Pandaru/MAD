import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mad/footer.dart';

class PointsPage extends StatelessWidget {
  const PointsPage({super.key});

  @override
  Widget build(BuildContext context) {
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
                    "My Points",
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
                    /// ⭐ TOTAL POINTS CARD
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1392AB),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: const Color(0xFF1392AB).withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 5))],
                      ),
                      child: Column(
                        children: [
                          Text(
                            "Your Balance",
                            style: GoogleFonts.openSans(color: Colors.white, fontSize: 16),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "120 pts",
                            style: GoogleFonts.openSans(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    /// 📊 HOW TO EARN
                    _sectionTitle("How to Earn Points"),
                    _buildInfoTile(Icons.shopping_cart_outlined, "Buy Medicine", "+1 pt per RM1 spent"),
                    _buildInfoTile(Icons.reviews_outlined, "Write Review", "+2 pts per helpful review"),

                    const SizedBox(height: 30),

                    /// ⏳ EXPIRY INFO
                    _sectionTitle("Points Expiry"),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.red.shade100),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.red, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            "30 pts will expire on 30 April 2026",
                            style: GoogleFonts.openSans(color: Colors.red.shade700, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    /// 🧾 HISTORY
                    _sectionTitle("Recent Activity"),
                    _buildHistory("+20 pts", "Medicine Purchase", "5 Apr 2026"),
                    _buildHistory("+10 pts", "Review Submitted", "3 Apr 2026"),
                    _buildHistory("-30 pts", "Redeemed Voucher", "1 Apr 2026"),
                    
                    const SizedBox(height: 40),
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

  Widget _sectionTitle(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 15),
        child: Text(
          text,
          style: GoogleFonts.openSans(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF1392AB)),
        title: Text(title, style: GoogleFonts.openSans(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: GoogleFonts.openSans(fontSize: 12)),
      ),
    );
  }

  Widget _buildHistory(String pts, String title, String date) {
    bool isAdd = pts.startsWith("+");
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        leading: Icon(
          isAdd ? Icons.add_circle_outline : Icons.remove_circle_outline,
          color: isAdd ? const Color(0xFF8DC6BC) : Colors.red,
        ),
        title: Text(title, style: GoogleFonts.openSans(fontWeight: FontWeight.w600)),
        subtitle: Text(date, style: GoogleFonts.openSans(fontSize: 12)),
        trailing: Text(
          pts,
          style: GoogleFonts.openSans(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isAdd ? const Color(0xFF8DC6BC) : Colors.red,
          ),
        ),
      ),
    );
  }
}
