import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mad/utility.dart';
import 'package:mad/admin/admindashboard.dart';

class StocktakePage extends StatefulWidget {
  final String scannedProductId;

  const StocktakePage({super.key, required this.scannedProductId});

  @override
  State<StocktakePage> createState() => _StocktakePageState();
}

class _StocktakePageState extends State<StocktakePage> {
  final supabase = Supabase.instance.client;
  late Future<List<Map<String, dynamic>>> _productsFuture;

  // Specific IDs and their corresponding stock-in amounts: 30, 30, 20, 20, 30
  final Map<String, int> _stockAmounts = {
    'P00005': 30,
    'P00006': 30,
    'P00007': 20,
    'P00011': 20,
    'P00012': 30,
  };

  @override
  void initState() {
    super.initState();
    _productsFuture = _fetchProducts();
  }

  Future<List<Map<String, dynamic>>> _fetchProducts() async {
    try {
      final response = await supabase
          .from('products')
          .select()
          .inFilter('id', _stockAmounts.keys.toList());
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint("Error fetching products: $e");
      return [];
    }
  }

  Future<void> _confirmStockIn(List<Map<String, dynamic>> products) async {
    try {
      for (var product in products) {
        final String id = product['id'];
        final int currentStock = product['stock_quantity'] ?? 0;
        final int addAmount = _stockAmounts[id] ?? 0;
        final int newStock = currentStock + addAmount;
        
        await supabase
            .from('products')
            .update({'stock_quantity': newStock})
            .eq('id', id);
      }

      if (mounted) {
        Utils.snackbar(context, "Inventory updated successfully! Stocks have been added.", color: Colors.green);
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const AdminDashboard()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) Utils.snackbar(context, "Update failed: $e", color: Colors.red);
    }
  }

  void _showReportDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Inventory Incident Report", style: GoogleFonts.openSans(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: "Incident Title", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: "Details", border: OutlineInputBorder()),
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Discard")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
            onPressed: () async {
              if (titleController.text.trim().isEmpty) {
                Utils.snackbar(context, "Title required", color: Colors.orange);
                return;
              }
              try {
                await supabase.from('reports').insert({
                  'title': titleController.text,
                  'description': descController.text,
                });
                if (mounted) {
                  Navigator.pop(context);
                  Utils.snackbar(context, "Report Logged Successfully", color: Colors.green);
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const AdminDashboard()),
                    (route) => false,
                  );
                }
              } catch (e) {
                if (mounted) Utils.snackbar(context, "Failed to submit report", color: Colors.red);
              }
            },
            child: const Text("Submit Report"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final products = snapshot.data ?? [];
          if (products.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text("No inventory items matched the scan result."),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Back"),
                  )
                ],
              ),
            );
          }

          double totalGrandAmount = 0;
          int totalUnits = 0;
          for (var p in products) {
            final double price = double.tryParse(p['price'].toString()) ?? 0;
            final int add = _stockAmounts[p['id']] ?? 0;
            totalGrandAmount += (price * add);
            totalUnits += add;
          }

          return CustomScrollView(
            slivers: [
              SliverAppBar.large(
                expandedHeight: 180,
                pinned: true,
                backgroundColor: Colors.blueAccent,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text("Stocktake Report", 
                    style: GoogleFonts.openSans(fontWeight: FontWeight.bold, color: Colors.white)),
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.blueAccent, Colors.indigo],
                      ),
                    ),
                    child: const Icon(Icons.assignment, size: 100, color: Colors.white24),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.summarize_outlined, color: Colors.blueAccent),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text("Stock-In Details", 
                              style: GoogleFonts.openSans(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                          ),
                        ],
                      ),
                      const Divider(),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final p = products[index];
                    final String id = p['id'];
                    final String name = p['name'];
                    final String? imageUrl = p['image_url'];
                    final double price = double.tryParse(p['price'].toString()) ?? 0;
                    final int add = _stockAmounts[id] ?? 0;
                    final double itemTotal = price * add;

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: imageUrl != null && imageUrl.isNotEmpty
                                  ? Image.network(imageUrl, width: 70, height: 70, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.image_not_supported, size: 70))
                                  : const Icon(Icons.image, size: 70),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: GoogleFonts.openSans(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 2, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 4),
                                  Text("ID: $id", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text("RM ${price.toStringAsFixed(2)} x $add", style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                                      ),
                                      const SizedBox(width: 4),
                                      Text("RM ${itemTotal.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text("Current: ${p['stock_quantity']} → New: ${p['stock_quantity'] + add}", style: TextStyle(fontSize: 12, color: Colors.green[700])),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: products.length,
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blueAccent.withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(child: Text("Total Stock-In Volume:", style: TextStyle(fontWeight: FontWeight.w600))),
                            Text("$totalUnits units"),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text("Total Estimated Value:", style: GoogleFonts.openSans(fontWeight: FontWeight.bold, fontSize: 16))),
                            Text("RM ${totalGrandAmount.toStringAsFixed(2)}", style: GoogleFonts.openSans(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.blueAccent)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _confirmStockIn(products),
                          icon: const Icon(Icons.check_circle_outline, size: 18),
                          label: const Text("Confirm", overflow: TextOverflow.ellipsis),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _showReportDialog,
                          icon: const Icon(Icons.report_problem_outlined, size: 18),
                          label: const Text("Report", overflow: TextOverflow.ellipsis),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange[800],
                            side: BorderSide(color: Colors.orange[800]!),
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            ],
          );
        },
      ),
    );
  }
}