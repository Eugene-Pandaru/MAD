import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mad/footer.dart';
import 'package:mad/utility.dart';
import 'package:mad/productlist.dart'; // 👈 Import ProductListPage
import 'package:supabase_flutter/supabase_flutter.dart';

class VouchersPage extends StatelessWidget {
  const VouchersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

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
                    "Available Vouchers",
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
              child: StreamBuilder<List<Map<String, dynamic>>>(
                // 🔍 Fetch all global vouchers
                stream: supabase.from('vouchers').stream(primaryKey: ['id']).order('created_at'),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF1392AB)));
                  }
                  
                  final vouchers = snapshot.data ?? [];
                  
                  if (vouchers.isEmpty) {
                    return Center(
                      child: Text("No vouchers available right now.", style: GoogleFonts.openSans(color: Colors.grey)),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: vouchers.length,
                    itemBuilder: (context, index) {
                      final v = vouchers[index];
                      String cat = v['category'] ?? 'DISCOUNT';
                      String type = v['discount_type'] ?? 'FIXED';
                      double amt = double.tryParse(v['discount_amount']?.toString() ?? '0') ?? 0;
                      
                      String title = "";
                      if (cat == 'SHIPPING') {
                        title = "Free Shipping (Up to RM${amt.toStringAsFixed(0)})";
                      } else {
                        title = type == 'PERCENTAGE' ? "${amt.toStringAsFixed(0)}% OFF Total" : "RM${amt.toStringAsFixed(0)} Discount";
                      }

                      return buildVoucherCard(
                        context,
                        title: title,
                        subtitle: v['description'] ?? "Use code: ${v['code']}",
                        code: v['code'] ?? "",
                        expiry: "Valid until: ${v['expiry_date'] ?? 'N/A'}",
                        color: cat == 'SHIPPING' ? Colors.orange : const Color(0xFF1392AB),
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

  Widget buildVoucherCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String code,
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
                Text(title, style: GoogleFonts.openSans(fontSize: 17, fontWeight: FontWeight.bold, color: color)),
                const SizedBox(height: 5),
                Text(subtitle, style: GoogleFonts.openSans(fontSize: 13, color: Colors.black87)),
                const SizedBox(height: 10),
                Text(expiry, style: GoogleFonts.openSans(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          Column(
            children: [
              Text(code, style: GoogleFonts.openSans(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 5),
              ElevatedButton(
                onPressed: () {
                   Utils.snackbar(context, "Voucher Applied! Browse products to use it.", color: color);
                   // 🚀 Navigate to Product List
                   Navigator.push(context, MaterialPageRoute(builder: (context) => const ProductListPage()));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text("Apply", style: GoogleFonts.openSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)), // 👈 Renamed
              ),
            ],
          ),
        ],
      ),
    );
  }
}
