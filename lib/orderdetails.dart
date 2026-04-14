import 'package:flutter/material.dart';
import 'package:mad/footer.dart';

class OrderDetailsPage extends StatelessWidget {
  final Map<String, dynamic> order;
  const OrderDetailsPage({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final List<dynamic> items = order['items'] ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text("Order Summary"), backgroundColor: Colors.green),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- 1. Order ID & Date ---
                  Text("ORDER #${order['id'].toString().substring(0, 8).toUpperCase()}",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Text("Date: ${order['created_at'].toString().split('T')[0]}",
                      style: const TextStyle(color: Colors.grey)),

                  const SizedBox(height: 20),

                  // --- 2. Dual Status Section (Delivery & Payment) ---
                  Row(
                    children: [
                      // Delivery Status Chip
                      _buildStatusChip(
                        label: order['delivery_status'] ?? "PENDING",
                        color: Colors.blue,
                        icon: Icons.local_shipping,
                      ),
                      const SizedBox(width: 10),
                      // Payment Method Chip
                      _buildStatusChip(
                        label: order['payment_method'] ?? "Not Paid",
                        color: Colors.orange,
                        icon: order['payment_method'] == "Card" ? Icons.credit_card : Icons.account_balance,
                      ),
                    ],
                  ),

                  const Divider(height: 40),

                  // --- 3. Items List ---
                  const Text("Items Purchased", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return ListTile(
                        leading: Image.network(item['image_url'] ?? '', width: 40, errorBuilder: (c, e, s) => const Icon(Icons.medication)),
                        title: Text(item['name']),
                        subtitle: Text("Quantity: ${item['quantity']}"),
                        trailing: Text("RM ${(item['price'] * item['quantity']).toStringAsFixed(2)}"),
                      );
                    },
                  ),

                  const Divider(height: 40),

                  // --- 4. Total Summary ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Grand Total", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text("RM ${double.parse(order['total_amount'].toString()).toStringAsFixed(2)}",
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Footer(),
        ],
      ),
    );
  }

  // Helper widget to build nice status badges
  Widget _buildStatusChip({required String label, required Color color, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}