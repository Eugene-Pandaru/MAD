import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mad/footer.dart';

class OrderDetailsPage extends StatelessWidget {
  final Map<String, dynamic> order;
  const OrderDetailsPage({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final List<dynamic> items = order['items'] ?? [];

    // Fetch values from the order map
    double deliveryFee = double.tryParse(order['delivery_fee']?.toString() ?? '0') ?? 0.0;
    double grandTotal = double.tryParse(order['total_amount']?.toString() ?? '0') ?? 0.0;

    // Calculate subtotal from the items list
    double calculatedSubtotal = items.fold(0.0, (sum, item) {
      return sum + ((item['price'] ?? 0) * (item['quantity'] ?? 1));
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 🟢 Header (Matching home/productlist style)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    "Order Summary",
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- 1. Order ID & Date ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("ORDER #${order['id'] ?? 'N/A'}",
                            style: GoogleFonts.openSans(fontWeight: FontWeight.bold, fontSize: 18)),
                        Text(order['created_at']?.toString().split('T')[0] ?? 'N/A',
                            style: GoogleFonts.openSans(color: Colors.grey, fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // --- 2. Shipping Section ---
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on, color: Color(0xFF1392AB)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Shipping Address", style: GoogleFonts.openSans(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
                                const SizedBox(height: 5),
                                Text(
                                  order['delivery_address'] ?? "Address not provided",
                                  style: GoogleFonts.openSans(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    // --- 3. Dual Status Section ---
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatusChip(
                            label: order['delivery_status'] ?? "PENDING",
                            color: const Color(0xFF1392AB),
                            icon: Icons.local_shipping,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildStatusChip(
                            label: order['payment_method'] ?? "Paid",
                            color: const Color(0xFF8DC6BC),
                            icon: Icons.payment,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 25),

                    // --- 4. Items List ---
                    Text("Items Purchased", style: GoogleFonts.openSans(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),

                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: item['image_url'] != null
                                    ? Image.network(item['image_url'], width: 50, height: 50, fit: BoxFit.cover)
                                    : const Icon(Icons.medication, size: 40),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item['name'] ?? "Unknown", style: GoogleFonts.openSans(fontWeight: FontWeight.bold)),
                                    Text("Qty: ${item['quantity'] ?? 1}", style: GoogleFonts.openSans(fontSize: 12, color: Colors.grey)),
                                  ],
                                ),
                              ),
                              Text("RM ${((item['price'] ?? 0) * (item['quantity'] ?? 1)).toStringAsFixed(2)}", 
                                  style: GoogleFonts.openSans(fontWeight: FontWeight.bold, color: const Color(0xFF1392AB))),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 25),

                    // --- 5. Bill Breakdown ---
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1392AB).withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          _buildPriceRow("Subtotal", calculatedSubtotal),
                          _buildPriceRow("Delivery Fee", deliveryFee),
                          const Divider(height: 30),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Grand Total", style: GoogleFonts.openSans(fontSize: 18, fontWeight: FontWeight.bold)),
                              Text(
                                "RM ${grandTotal.toStringAsFixed(2)}",
                                style: GoogleFonts.openSans(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1392AB)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
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

  Widget _buildPriceRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.openSans(fontSize: 14)),
          Text("RM ${amount.toStringAsFixed(2)}", style: GoogleFonts.openSans(fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildStatusChip({required String label, required Color color, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.openSans(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}
