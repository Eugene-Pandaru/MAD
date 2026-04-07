import 'package:flutter/material.dart';
import 'package:mad/utility.dart';

class VouchersPage extends StatelessWidget {
  const VouchersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Vouchers"),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),

      body: ListView(
        padding: const EdgeInsets.all(15),
        children: [
          buildVoucher(
            context,
            title: "RM5 OFF Medicine",
            subtitle: "Min spend RM30",
            expiry: "Valid until 30 Apr 2026",
            color: Colors.green,
          ),

          buildVoucher(
            context,
            title: "Free Delivery",
            subtitle: "No minimum spend",
            expiry: "Valid until 15 Apr 2026",
            color: Colors.blue,
          ),

          buildVoucher(
            context,
            title: "Free Consultation",
            subtitle: "Chat with pharmacist",
            expiry: "Valid until 20 Apr 2026",
            color: Colors.orange,
          ),

          buildVoucher(
            context,
            title: "10% OFF Vitamins",
            subtitle: "Selected items only",
            expiry: "Valid until 25 Apr 2026",
            color: Colors.purple,
          ),

          buildVoucher(
            context,
            title: "RM10 OFF First Order",
            subtitle: "New user only",
            expiry: "Valid until 30 Apr 2026",
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  /// 🎟️ Voucher Card
  Widget buildVoucher(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String expiry,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          /// 🎟️ Left Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 5),
                Text(subtitle),
                const SizedBox(height: 5),
                Text(
                  expiry,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),

          /// 🔘 Redeem Button
          ElevatedButton(
            onPressed: () {
              Utils.snackbar(
                context,
                "$title redeemed",
                color: Colors.green,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: color),
            child: const Text("Redeem"),
          ),
        ],
      ),
    );
  }
}
