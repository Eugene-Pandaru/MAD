import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mad/footer.dart';
import 'package:mad/utility.dart';

class VouchersPage extends StatelessWidget {
  const VouchersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 🟢 Header (Matching home style)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    "My Vouchers",
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
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  buildVoucher(
                    context,
                    title: "RM5 OFF Medicine",
                    subtitle: "Min spend RM30",
                    expiry: "Valid until 30 Apr 2026",
                    color: const Color(0xFF1392AB),
                  ),
                  buildVoucher(
                    context,
                    title: "Free Delivery",
                    subtitle: "No minimum spend",
                    expiry: "Valid until 15 Apr 2026",
                    color: Colors.orange,
                  ),
                  buildVoucher(
                    context,
                    title: "Free Consultation",
                    subtitle: "Chat with pharmacist",
                    expiry: "Valid until 20 Apr 2026",
                    color: const Color(0xFF8DC6BC),
                  ),
                  buildVoucher(
                    context,
                    title: "10% OFF Vitamins",
                    subtitle: "Selected items only",
                    expiry: "Valid until 25 Apr 2026",
                    color: Colors.purple,
                  ),
                ],
              ),
            ),
            const Footer(),
          ],
        ),
      ),
    );
  }

  Widget buildVoucher(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String expiry,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.openSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 5),
                Text(subtitle, style: GoogleFonts.openSans(fontSize: 14)),
                const SizedBox(height: 10),
                Text(
                  expiry,
                  style: GoogleFonts.openSans(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Utils.snackbar(context, "$title redeemed", color: color);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text("Redeem", style: GoogleFonts.openSans(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
