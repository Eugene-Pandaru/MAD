import 'package:flutter/material.dart';
import 'package:mad/utility.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class ManageInventoryPage extends StatefulWidget {
  const ManageInventoryPage({super.key});

  @override
  State<ManageInventoryPage> createState() => _ManageInventoryPageState();
}

class _ManageInventoryPageState extends State<ManageInventoryPage> {
  final supabase = Supabase.instance.client;
  String _selectedCategory = "All";

  final List<String> _categories = ["All", "Medicine", "Vitamin", "Baby Care"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text("Inventory Tracking", style: GoogleFonts.openSans(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          /// 🏷️ Filter Chips Section
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                String cat = _categories[index];
                bool isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: ChoiceChip(
                    label: Text(cat, style: TextStyle(color: isSelected ? Colors.white : Colors.orange)),
                    selected: isSelected,
                    selectedColor: Colors.orange,
                    onSelected: (selected) {
                      setState(() => _selectedCategory = cat);
                    },
                  ),
                );
              },
            ),
          ),

          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: supabase.from('products').stream(primaryKey: ['id']),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.orange));
                
                List<Map<String, dynamic>> items = snapshot.data ?? [];

                // 🛠️ Filter Logic
                if (_selectedCategory != "All") {
                  items = items.where((p) => p['category'] == _selectedCategory).toList();
                }

                // 🛠️ Sorting Logic (Always A-Z)
                items.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));

                return Column(
                  children: [
                    // 📊 TOTAL NUMBER DISPLAY
                    Container(
                      width: double.infinity,
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                      child: Text(
                        "Total Items Listed: ${items.length}",
                        style: GoogleFonts.openSans(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.orange),
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: items.isEmpty
                          ? Center(child: Text("No items found in $_selectedCategory", style: GoogleFonts.openSans(color: Colors.grey)))
                          : ListView.builder(
                              itemCount: items.length,
                              padding: const EdgeInsets.all(15),
                              itemBuilder: (context, index) {
                                final product = items[index];
                                int stock = product['stock_quantity'] ?? 0;
                                String expiry = product['expiry_date'] ?? "N/A";

                                return Card(
                                  elevation: 0,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.grey[200]!)),
                                  child: ListTile(
                                    title: Text(product['name'], style: GoogleFonts.openSans(fontWeight: FontWeight.bold)),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text("Current Stock: $stock", style: TextStyle(color: stock < 20 ? Colors.red : Colors.grey[700], fontWeight: stock < 20 ? FontWeight.bold : FontWeight.normal)),
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
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
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
