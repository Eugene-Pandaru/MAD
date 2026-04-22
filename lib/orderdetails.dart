import 'package:flutter/material.dart';
import 'package:mad/footer.dart';

class OrderDetailsPage extends StatelessWidget {
  final Map<String, dynamic> order;
  const OrderDetailsPage({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final List<dynamic> items = order['items'] ?? [];

    // 1. Fetch values from the order map
    double deliveryFee = double.tryParse(order['delivery_fee']?.toString() ?? '0') ?? 0.0;
    double grandTotal = double.tryParse(order['total_amount']?.toString() ?? '0') ?? 0.0;

    // 2. Calculate subtotal from the items list
    double calculatedSubtotal = items.fold(0.0, (sum, item) {
      return sum + ((item['price'] ?? 0) * (item['quantity'] ?? 1));
    });

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
                  Text("ORDER #${order['id'] ?? 'N/A'}",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Text("Date: ${order['created_at']?.toString().split('T')[0] ?? 'N/A'}",
                      style: const TextStyle(color: Colors.grey)),

                  const SizedBox(height: 20),

                  const Text("Shipping To:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
                  const SizedBox(height: 5),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on, size: 18, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          order['delivery_address'] ?? "Address not provided",
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 40),

                  // --- 2. Dual Status Section ---
                  Row(
                    children: [
                      _buildStatusChip(
                        label: order['delivery_status'] ?? "PENDING",
                        color: Colors.blue,
                        icon: Icons.local_shipping,
                      ),
                      const SizedBox(width: 10),
                      _buildStatusChip(
                        label: order['payment_method'] ?? "Paid",
                        color: Colors.orange,
                        icon: (order['payment_method']?.toString().contains("Card") ?? false)
                            ? Icons.credit_card
                            : Icons.account_balance,
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
                        leading: SizedBox(
                          width: 40,
                          child: item['image_url'] != null && item['image_url'].toString().isNotEmpty
                              ? Image.network(item['image_url'], fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.medication))
                              : const Icon(Icons.medication),
                        ),
                        title: Text(item['name'] ?? "Unknown Item"),
                        subtitle: Text("Quantity: ${item['quantity'] ?? 1}"),
                        trailing: Text("RM ${((item['price'] ?? 0) * (item['quantity'] ?? 1)).toStringAsFixed(2)}"),
                      );
                    },
                  ),

                  const Divider(height: 40),

                  // --- 4. Bill Breakdown ---
                  _buildPriceRow("Subtotal", calculatedSubtotal),
                  _buildPriceRow("Delivery Fee", deliveryFee),

                  const SizedBox(height: 10),
                  const Divider(thickness: 1.5),

                  // --- 5. Grand Total ---
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Grand Total", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(
                          "RM ${grandTotal.toStringAsFixed(2)}",
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                      ],
                    ),
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

  // Helper widget to build the price lines
  Widget _buildPriceRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.black87)),
          Text("RM ${amount.toStringAsFixed(2)}", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildStatusChip({required String label, required Color color, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}