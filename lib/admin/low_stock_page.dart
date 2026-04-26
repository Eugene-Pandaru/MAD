import 'package:flutter/material.dart';
import 'package:mad/utility.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LowStockPage extends StatefulWidget {
  const LowStockPage({super.key});

  @override
  State<LowStockPage> createState() => _LowStockPageState();
}

class _LowStockPageState extends State<LowStockPage> {
  final supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Low Stock Alerts (< 20)"),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        // 🔍 Only fetch products with stock < 20
        stream: supabase.from('products').stream(primaryKey: ['id']).eq('category', 'Medicine'), // Filter logic below
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          
          // Manual filtering since .stream().lt() is tricky in some versions of supabase_flutter
          final allItems = snapshot.data ?? [];
          final items = allItems.where((item) => (item['stock_quantity'] ?? 0) < 20).toList();

          if (items.isEmpty) {
            return const Center(child: Text("No low stock items found."));
          }

          return ListView.builder(
            itemCount: items.length,
            padding: const EdgeInsets.all(10),
            itemBuilder: (context, index) {
              final product = items[index];
              int stock = product['stock_quantity'] ?? 0;

              return Card(
                child: ListTile(
                  title: Text(product['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Current Stock: $stock", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  trailing: IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.green, size: 35),
                    onPressed: () => _showAddStockOverlay(context, product),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddStockOverlay(BuildContext context, Map<String, dynamic> product) {
    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Restock Item"),
        content: TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: "Add amount +",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              int delta = int.tryParse(amountController.text) ?? 0;
              if (delta <= 0) return;
              
              int newStock = (product['stock_quantity'] ?? 0) + delta;

              await supabase.from('products').update({'stock_quantity': newStock}).eq('id', product['id']);
              Navigator.pop(context);
              Utils.snackbar(context, "Stock Updated Successfully");
            },
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }
}
