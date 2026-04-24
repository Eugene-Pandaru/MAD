import 'package:flutter/material.dart';
import 'package:mad/utility.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ManageOrdersPage extends StatefulWidget {
  const ManageOrdersPage({super.key});

  @override
  State<ManageOrdersPage> createState() => _ManageOrdersPageState();
}

class _ManageOrdersPageState extends State<ManageOrdersPage> {
  final supabase = Supabase.instance.client;

  Future<void> _updateStatus(String orderId, String newStatus) async {
    try {
      await supabase.from('orders').update({'delivery_status': newStatus}).eq('id', orderId);
      if (mounted) Utils.snackbar(context, "Order $newStatus", color: Colors.green);
    } catch (e) {
      if (mounted) Utils.snackbar(context, "Error updating status", color: Colors.red);
    }
  }

  Future<void> _cancelOrder(String orderId) async {
    try {
      await supabase.from('orders').update({'delivery_status': 'CANCELLED'}).eq('id', orderId);
      if (mounted) Utils.snackbar(context, "Order Cancelled", color: Colors.red);
    } catch (e) {
      if (mounted) Utils.snackbar(context, "Error cancelling order", color: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Order Management"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase.from('orders').stream(primaryKey: ['id']).order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final orders = snapshot.data ?? [];

          if (orders.isEmpty) {
            return const Center(child: Text("No orders found."));
          }

          return ListView.builder(
            itemCount: orders.length,
            padding: const EdgeInsets.all(10),
            itemBuilder: (context, index) {
              final order = orders[index];
              final String status = order['delivery_status'] ?? 'PENDING';
              
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: _getStatusColor(status).withOpacity(0.1),
                    child: Icon(Icons.receipt, color: _getStatusColor(status)),
                  ),
                  title: Text("Order #${order['id']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Customer: ${order['user_name']}\nTotal: RM ${order['total_amount']}"),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Address: ${order['delivery_address']}"),
                          const SizedBox(height: 10),
                          const Text("Update Status:", style: TextStyle(fontWeight: FontWeight.bold)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _statusButton(order['id'], "APPROVED", Colors.orange),
                              _statusButton(order['id'], "DELIVERED", Colors.green),
                              ElevatedButton(
                                onPressed: () => _cancelOrder(order['id']),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                child: const Text("CANCEL", style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _statusButton(String id, String label, Color color) {
    return ElevatedButton(
      onPressed: () => _updateStatus(id, label),
      style: ElevatedButton.styleFrom(backgroundColor: color),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 10)),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'DELIVERED': return Colors.green;
      case 'APPROVED': return Colors.orange;
      case 'CANCELLED': return Colors.red;
      default: return Colors.blue;
    }
  }
}
