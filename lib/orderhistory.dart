import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mad/footer.dart';
import 'package:mad/utility.dart';

import 'orderdetails.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  final supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    final userId = Utils.currentUser?['id'];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Order History"),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: supabase
                  .from('orders')
                  .select()
                  .eq('user_id', userId)
                  .order('created_at', ascending: false),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                final orders = snapshot.data ?? [];
                if (orders.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long, size: 80, color: Colors.grey),
                        SizedBox(height: 10),
                        Text("No orders found yet.", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    String rawDate = order['created_at'].toString();
                    String formattedDate = rawDate.split('T')[0];

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OrderDetailsPage(order: order),
                            ),
                          );
                        },
                        contentPadding: const EdgeInsets.all(15),
                        leading: CircleAvatar(
                          backgroundColor: Colors.green.shade100,
                          child: const Icon(Icons.local_shipping, color: Colors.green),
                        ),
                        title: Text(
                          "Order #${order['id']}", // Directly show O00001
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 5),
                            Text("Date: $formattedDate"),
                            const SizedBox(height: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                order['status'] ?? "Paid",
                                style: TextStyle(fontSize: 12, color: Colors.orange.shade900),
                              ),
                            ),
                          ],
                        ),
                        trailing: Text(
                          "RM ${double.parse(order['total_amount'].toString()).toStringAsFixed(2)}",
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const Footer(),
        ],
      ),
    );
  }
}
