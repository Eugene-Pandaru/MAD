import 'package:flutter/material.dart';
import 'package:mad/utility.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text("Low Stock Alerts (< 20)", style: GoogleFonts.openSans(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase.from('products').stream(primaryKey: ['id']),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.redAccent));
          }

          final allItems = snapshot.data ?? [];
          final lowStockItems = allItems.where((item) => (item['stock_quantity'] ?? 0) < 20).toList();

          // Split into categories
          final medicines = lowStockItems.where((i) => i['category'] == 'Medicine').toList();
          final vitamins = lowStockItems.where((i) => i['category'] == 'Vitamin').toList();
          final babyCare = lowStockItems.where((i) => i['category'] == 'Baby Care').toList();

          return Column(
            children: [
              // 📊 TOTAL NUMBER DISPLAY
              Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      "Total low stock items: ${lowStockItems.length}",
                      style: GoogleFonts.openSans(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              Expanded(
                child: lowStockItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline, size: 80, color: Colors.green[200]),
                            const SizedBox(height: 10),
                            Text("All stock levels are healthy!", style: GoogleFonts.openSans(color: Colors.grey, fontSize: 16)),
                          ],
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.all(15),
                        children: [
                          if (medicines.isNotEmpty) _buildCategorySection("Medicine", medicines, Colors.teal),
                          if (vitamins.isNotEmpty) _buildCategorySection("Vitamin", vitamins, Colors.orange),
                          if (babyCare.isNotEmpty) _buildCategorySection("Baby Care", babyCare, Colors.purple),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategorySection(String title, List<Map<String, dynamic>> items, Color themeColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
          child: Row(
            children: [
              Container(width: 4, height: 20, color: themeColor),
              const SizedBox(width: 10),
              Text(title, style: GoogleFonts.openSans(fontSize: 18, fontWeight: FontWeight.bold, color: themeColor)),
              const Spacer(),
              Text("${items.length} items", style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
        ...items.map((product) {
          int stock = product['stock_quantity'] ?? 0;
          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
              side: BorderSide(color: Colors.red[100]!),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              title: Text(product['name'], style: GoogleFonts.openSans(fontWeight: FontWeight.bold)),
              subtitle: Text("Current Stock: $stock", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
              trailing: IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.green, size: 32),
                onPressed: () => _showAddStockOverlay(context, product),
              ),
            ),
          );
        }).toList(),
        const SizedBox(height: 10),
      ],
    );
  }

  void _showAddStockOverlay(BuildContext context, Map<String, dynamic> product) {
    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Restock: ${product['name']}", style: const TextStyle(fontSize: 18)),
        content: TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: "Add amount +",
            hintText: "e.g. 50",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              int delta = int.tryParse(amountController.text) ?? 0;
              if (delta <= 0) return;
              
              int newStock = (product['stock_quantity'] ?? 0) + delta;

              try {
                await supabase.from('products').update({'stock_quantity': newStock}).eq('id', product['id']);
                if (mounted) {
                  Navigator.pop(context);
                  Utils.snackbar(context, "Stock updated for ${product['name']}", color: Colors.green);
                }
              } catch (e) {
                if (mounted) Utils.snackbar(context, "Update failed", color: Colors.red);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }
}
