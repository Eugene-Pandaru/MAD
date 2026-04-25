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
      appBar: AppBar(title: const Text("Inventory Tracking"), backgroundColor: Colors.orange, foregroundColor: Colors.white),
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
              String expiry = product['expiry_date'] ?? "N/A";
              bool isLow = stock <= 10;

              return Card(
                child: ListTile(
                  title: Text(product['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Current Stock: $stock"),
                      Text("Expiry Date: $expiry", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: Colors.green, size: 30),
                        onPressed: () => _showStockOverlay(context, product, true),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_circle, color: Colors.red, size: 30),
                        onPressed: () => _showStockOverlay(context, product, false),
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

  void _showStockOverlay(BuildContext context, Map<String, dynamic> product, bool isAdd) {
    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isAdd ? "Add Stock" : "Remove Stock"),
        content: TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: isAdd ? "Add amount +" : "Remove amount -",
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              int delta = int.tryParse(amountController.text) ?? 0;
              if (!isAdd) delta = -delta;
              int newStock = (product['stock_quantity'] ?? 0) + delta;
              if (newStock < 0) newStock = 0;

              await supabase.from('products').update({'stock_quantity': newStock}).eq('id', product['id']);
              Navigator.pop(context);
              Utils.snackbar(context, "Stock Updated");
            },
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }
}
