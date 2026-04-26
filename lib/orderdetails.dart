import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mad/footer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrderDetailsPage extends StatefulWidget {
  final Map<String, dynamic> order;
  const OrderDetailsPage({super.key, required this.order});

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  final supabase = Supabase.instance.client;
  late Map<String, dynamic> currentOrder;

  @override
  void initState() {
    super.initState();
    currentOrder = widget.order;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      // 📡 Real-time sync for THIS specific order
      stream: supabase.from('orders').stream(primaryKey: ['id']).eq('id', currentOrder['id']),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          currentOrder = snapshot.data!.first;
        }

        final List<dynamic> items = currentOrder['items'] ?? [];
        double deliveryFee = double.tryParse(currentOrder['delivery_fee']?.toString() ?? '0') ?? 0.0;
        double grandTotal = double.tryParse(currentOrder['total_amount']?.toString() ?? '0') ?? 0.0;

        double calculatedSubtotal = items.fold(0.0, (sum, item) {
          return sum + ((item['price'] ?? 0) * (item['quantity'] ?? 1));
        });

        // 🛠️ Map statuses to professional labels
        String displayStatus = currentOrder['delivery_status'] ?? "PENDING";
        if (displayStatus == "PENDING") displayStatus = "Ordered";
        if (displayStatus == "APPROVED") displayStatus = "Pending";

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Text("Order Summary", style: GoogleFonts.openSans(fontSize: 22, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("ORDER #${currentOrder['id'] ?? 'N/A'}", style: GoogleFonts.openSans(fontWeight: FontWeight.bold, fontSize: 18)),
                            Text(currentOrder['created_at']?.toString().split('T')[0] ?? 'N/A', style: GoogleFonts.openSans(color: Colors.grey, fontSize: 14)),
                          ],
                        ),
                        const SizedBox(height: 20),

                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(15)),
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
                                    Text(currentOrder['delivery_address'] ?? "Address not provided", style: GoogleFonts.openSans(fontSize: 14)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 25),

                        Row(
                          children: [
                            Expanded(
                              child: _buildStatusChip(
                                label: displayStatus,
                                color: const Color(0xFF1392AB),
                                icon: Icons.local_shipping,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildStatusChip(
                                label: currentOrder['payment_method'] ?? "Paid",
                                color: const Color(0xFF8DC6BC),
                                icon: Icons.payment,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 25),

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
                              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(15)),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(item['image_url'], width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.medication)),
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

                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(color: const Color(0xFF1392AB).withValues(alpha: 0.05), borderRadius: BorderRadius.circular(20)),
                          child: Column(
                            children: [
                              _buildPriceRow("Subtotal", calculatedSubtotal),
                              _buildPriceRow("Delivery Fee", deliveryFee),
                              const Divider(height: 30),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("Grand Total", style: GoogleFonts.openSans(fontSize: 18, fontWeight: FontWeight.bold)),
                                  Text("RM ${grandTotal.toStringAsFixed(2)}", style: GoogleFonts.openSans(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1392AB))),
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
      },
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
