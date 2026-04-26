import 'package:flutter/material.dart';
import 'package:mad/utility.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mad/orderdetails.dart';

class ManageOrdersPage extends StatefulWidget {
  const ManageOrdersPage({super.key});

  @override
  State<ManageOrdersPage> createState() => _ManageOrdersPageState();
}

class _ManageOrdersPageState extends State<ManageOrdersPage> {
  final supabase = Supabase.instance.client;

  Future<void> _updateStatus(String orderId, String newStatus) async {
    try {
      final Map<String, dynamic> updateData = {
        'delivery_status': newStatus
      };

      if (newStatus == 'CANCELLED') {
        updateData['status'] = 'CANCELLED';
      }

      await supabase.from('orders').update(updateData).eq('id', orderId);
      if (mounted) {
        setState(() {}); 
        Utils.snackbar(context, "Order $newStatus", color: Colors.green);
      }
    } catch (e) {
      if (mounted) Utils.snackbar(context, "Error updating status", color: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text("Order Management", style: GoogleFonts.openSans(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            isScrollable: true,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: "New"),
              Tab(text: "Pending"),
              Tab(text: "Delivered"),
              Tab(text: "Cancelled"),
            ],
          ),
        ),
        body: StreamBuilder<List<Map<String, dynamic>>>(
          stream: supabase.from('orders').stream(primaryKey: ['id']).order('created_at', ascending: false),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final orders = snapshot.data ?? [];

            final newOrders = orders.where((o) => (o['delivery_status'] ?? 'PENDING') == 'PENDING').toList();
            final pendingOrders = orders.where((o) => o['delivery_status'] == 'APPROVED').toList();
            final deliveredOrders = orders.where((o) => o['delivery_status'] == 'DELIVERED').toList();
            final cancelledOrders = orders.where((o) => o['delivery_status'] == 'CANCELLED').toList();

            return TabBarView(
              children: [
                _buildOrderList(newOrders, "New"),
                _buildOrderList(pendingOrders, "Pending"),
                _buildOrderList(deliveredOrders, "Delivered"),
                _buildOrderList(cancelledOrders, "Cancelled"),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildOrderList(List<Map<String, dynamic>> orders, String type) {
    return Column(
      children: [
        // 📊 TOTAL NUMBER DISPLAY (Per Section)
        Container(
          width: double.infinity,
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          child: Row(
            children: [
              const Icon(Icons.receipt_long, color: Colors.blueAccent, size: 20),
              const SizedBox(width: 10),
              Text(
                "Total $type Orders: ${orders.length}",
                style: GoogleFonts.openSans(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: orders.isEmpty
              ? Center(child: Text("No $type orders found.", style: GoogleFonts.openSans(color: Colors.grey)))
              : ListView.builder(
                  itemCount: orders.length,
                  padding: const EdgeInsets.all(10),
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    final String status = order['delivery_status'] ?? 'PENDING';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Order #${order['id']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text("RM ${double.parse(order['total_amount'].toString()).toStringAsFixed(2)}", 
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text("Customer: ${order['user_name']}", style: const TextStyle(color: Colors.grey)),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => OrderDetailsPage(order: order)));
                                  },
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[200], foregroundColor: Colors.black, elevation: 0),
                                  child: const Text("View Details"),
                                ),
                                Row(
                                  children: _buildActionButtons(order, status),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  List<Widget> _buildActionButtons(Map<String, dynamic> order, String status) {
    if (status == 'PENDING') {
      return [
        TextButton(
          onPressed: () => _updateStatus(order['id'], 'CANCELLED'),
          child: const Text("Cancel", style: TextStyle(color: Colors.red)),
        ),
        const SizedBox(width: 5),
        ElevatedButton(
          onPressed: () => _updateStatus(order['id'], 'APPROVED'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: const Text("Accept", style: TextStyle(color: Colors.white)),
        ),
      ];
    } else if (status == 'APPROVED') {
      return [
        ElevatedButton(
          onPressed: () => _updateStatus(order['id'], 'DELIVERED'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
          child: const Text("Send to Delivery", style: TextStyle(color: Colors.white)),
        ),
      ];
    } else if (status == 'DELIVERED') {
      return [
        const Text("Success", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
      ];
    } else {
      return [
        const Text("Cancelled", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
      ];
    }
  }
}