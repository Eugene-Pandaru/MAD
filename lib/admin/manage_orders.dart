import 'package:flutter/material.dart';
import 'package:mad/utility.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mad/orderdetails.dart';
import 'package:mad/admin/admindashboard.dart';

class ManageOrdersPage extends StatefulWidget {
  const ManageOrdersPage({super.key});

  @override
  State<ManageOrdersPage> createState() => _ManageOrdersPageState();
}

class _ManageOrdersPageState extends State<ManageOrdersPage> {
  final supabase = Supabase.instance.client;

  Future<void> _updateStatus(Map<String, dynamic> order, String newStatus) async {
    final orderId = order['id'];
    try {
      final Map<String, dynamic> updateData = {
        'delivery_status': newStatus
      };

      if (newStatus == 'CANCELLED') {
        updateData['status'] = 'CANCELLED';
        
        final userId = order['user_id'];
        final double totalAmount = double.tryParse(order['total_amount'].toString()) ?? 0.0;
        final int pointsToDeduct = (totalAmount * 10).floor();

        if (userId != null && pointsToDeduct > 0) {
          await supabase.from('points').insert({
            'user_id': userId,
            'points_amount': -pointsToDeduct,
            'reason': 'Order Cancelled: #$orderId',
          });
        }
      }

      await supabase.from('orders').update(updateData).eq('id', orderId);
      if (mounted) {
        setState(() {}); 
        Utils.snackbar(context, "Order Moved to $newStatus", color: newStatus == 'CANCELLED' ? Colors.orange : Colors.green);
      }
    } catch (e) {
      if (mounted) Utils.snackbar(context, "Error updating status", color: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const AdminDashboard()),
                (route) => false,
              );
            },
          ),
          title: Text("Order Management", style: GoogleFonts.openSans(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: "Requesting"),
              Tab(text: "Packaging"),
              Tab(text: "Delivering"),
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

            final requesting = orders.where((o) => (o['delivery_status'] ?? 'REQUESTING') == 'REQUESTING' || o['delivery_status'] == 'PENDING').toList();
            final packaging = orders.where((o) => o['delivery_status'] == 'PACKAGING' || o['delivery_status'] == 'APPROVED').toList();
            final delivering = orders.where((o) => o['delivery_status'] == 'DELIVERING').toList();
            final delivered = orders.where((o) => o['delivery_status'] == 'DELIVERED').toList();
            final cancelled = orders.where((o) => o['delivery_status'] == 'CANCELLED').toList();

            return TabBarView(
              children: [
                _buildOrderList(requesting, "Requesting"),
                _buildOrderList(packaging, "Packaging"),
                _buildOrderList(delivering, "Delivering"),
                _buildOrderList(delivered, "Delivered"),
                _buildOrderList(cancelled, "Cancelled"),
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
        Container(
          width: double.infinity,
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          child: Row(
            children: [
              const Icon(Icons.receipt_long, color: Colors.blueAccent, size: 20),
              const SizedBox(width: 10),
              Text(
                "Total $type: ${orders.length}",
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
                    final String status = order['delivery_status']?.toString().toUpperCase() ?? 'REQUESTING';

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
                              children: [
                                SizedBox(
                                  height: 32,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(context, MaterialPageRoute(builder: (context) => OrderDetailsPage(order: order)));
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey[200], 
                                      foregroundColor: Colors.black, 
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 10),
                                      textStyle: const TextStyle(fontSize: 11),
                                    ),
                                    child: const Text("Details"),
                                  ),
                                ),
                                const Spacer(),
                                ..._buildActionButtons(order, status),
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
    if (status == 'REQUESTING' || status == 'PENDING') {
      return [
        TextButton(
          onPressed: () => _updateStatus(order, 'CANCELLED'),
          style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8), minimumSize: Size.zero),
          child: const Text("Cancel", style: TextStyle(color: Colors.red, fontSize: 12)),
        ),
        const SizedBox(width: 4),
        SizedBox(
          height: 32,
          child: ElevatedButton(
            onPressed: () => _updateStatus(order, 'PACKAGING'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, padding: const EdgeInsets.symmetric(horizontal: 12)),
            child: const Text("Pack", style: TextStyle(color: Colors.white, fontSize: 11)),
          ),
        ),
      ];
    } else if (status == 'PACKAGING' || status == 'APPROVED') {
      return [
        SizedBox(
          height: 32,
          child: ElevatedButton(
            onPressed: () => _updateStatus(order, 'DELIVERING'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, padding: const EdgeInsets.symmetric(horizontal: 12)),
            child: const Text("Ship", style: TextStyle(color: Colors.white, fontSize: 11)),
          ),
        ),
      ];
    } else if (status == 'DELIVERING') {
      return [
        SizedBox(
          height: 32,
          child: ElevatedButton(
            onPressed: () => _updateStatus(order, 'DELIVERED'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(horizontal: 12)),
            child: const Text("Complete", style: TextStyle(color: Colors.white, fontSize: 11)),
          ),
        ),
      ];
    } else if (status == 'DELIVERED') {
      return [
        const Text("Finished", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
      ];
    } else {
      return [
        const Text("Cancelled", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
      ];
    }
  }
}
