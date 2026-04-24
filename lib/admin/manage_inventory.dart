import 'package:flutter/material.dart';
import 'package:mad/utility.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ManageInventoryPage extends StatefulWidget {
  const ManageInventoryPage({super.key});

  @override
  State<ManageInventoryPage> createState() => _ManageInventoryPageState();
}

class _ManageInventoryPageState extends State<ManageInventoryPage> {
  final supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Inventory Management"), backgroundColor: Colors.orange, foregroundColor: Colors.white),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase.from('products').stream(primaryKey: ['id']),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final items = snapshot.data ?? [];

          return ListView.builder(
            itemCount: items.length,
            padding: const EdgeInsets.all(10),
            itemBuilder: (context, index) {
              final product = items[index];
              int stock = product['stock_quantity'] ?? 0;
              bool isLow = stock <= 10;

              return Card(
                child: ListTile(
                  title: Text(product['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Expiry: ${product['expiry_date'] ?? 'N/A'}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isLow ? Colors.red : Colors.green,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text("Stock: $stock", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: Colors.blue),
                        onPressed: () => _adjustStock(product['id'], stock, 10),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: () => _adjustStock(product['id'], stock, -10),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _adjustStock(String id, int current, int delta) async {
    int newStock = current + delta;
    if (newStock < 0) newStock = 0;
    await supabase.from('products').update({'stock_quantity': newStock}).eq('id', id);
    Utils.snackbar(context, "Stock updated to $newStock");
  }
}
