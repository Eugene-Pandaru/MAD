import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mad/utility.dart'; // Assuming Utils class is here
import 'package:mad/admin/admindashboard.dart'; // For navigating back to dashboard

class StocktakePage extends StatefulWidget {
  final String scannedProductId;

  const StocktakePage({super.key, required this.scannedProductId});

  @override
  State<StocktakePage> createState() => _StocktakePageState();
}

class _StocktakePageState extends State<StocktakePage> {
  final supabase = Supabase.instance.client;
  late Future<Map<String, dynamic>?> _productFuture;
  final TextEditingController _stockInController = TextEditingController();
  int _currentStock = 0;
  String? _productName;

  @override
  void initState() {
    super.initState();
    _productFuture = _fetchProductDetails();
  }

  Future<Map<String, dynamic>?> _fetchProductDetails() async {
    try {
      final response = await supabase
          .from('products')
          .select()
          .eq('id', widget.scannedProductId)
          .single();
      setState(() {
        _currentStock = response['stock_quantity'] ?? 0;
        _productName = response['name'];
      });
      return response;
    } catch (e) {
      if (mounted) {
        Utils.snackbar(context, "Error fetching product: $e", color: Colors.red);
      }
      return null;
    }
  }

  Future<void> _confirmStockIn() async {
    final String stockInText = _stockInController.text;
    if (stockInText.isEmpty) {
      Utils.snackbar(context, "Please enter a quantity to stock in.", color: Colors.orange);
      return;
    }

    final int stockInQuantity = int.tryParse(stockInText) ?? 0;
    if (stockInQuantity <= 0) {
      Utils.snackbar(context, "Please enter a valid positive quantity.", color: Colors.orange);
      return;
    }

    final int newStockQuantity = _currentStock + stockInQuantity;

    try {
      await supabase
          .from('products')
          .update({'stock_quantity': newStockQuantity})
          .eq('id', widget.scannedProductId);

      if (mounted) {
        Utils.snackbar(context, "Stock updated successfully!", color: Colors.green);
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const AdminDashboard()),
          (route) => false,
        ); // Go back to dashboard
      }
    } catch (e) {
      if (mounted) {
        Utils.snackbar(context, "Error updating stock: $e", color: Colors.red);
      }
    }
  }

  void _showReportDialog() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Submit Stocktake Report"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: "Report Title"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: "Description"),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isEmpty) {
                if (mounted) Utils.snackbar(context, "Report title cannot be empty.", color: Colors.orange);
                return;
              }

              try {
                await supabase.from('reports').insert({
                  'title': titleController.text,
                  'description': descriptionController.text,
                });
                if (mounted) {
                  Utils.snackbar(context, "Report submitted successfully!", color: Colors.green);
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const AdminDashboard()),
                    (route) => false,
                  );
                }
              } catch (e) {
                if (mounted) Utils.snackbar(context, "Error submitting report: $e", color: Colors.red);
              }
            },
            child: const Text("Submit"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stocktake', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueAccent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<Map<String, dynamic>?>( // Use FutureBuilder to handle async data fetch
        future: _productFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || snapshot.data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Product not found or an error occurred.'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const AdminDashboard()),
                        (route) => false,
                      ); // Go back to dashboard
                    },
                    child: const Text('Back to Dashboard'),
                  ),
                ],
              ),
            );
          }

          final product = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Product: ${product['name']}',
                  style: GoogleFonts.openSans(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text('ID: ${product['id']}', style: const TextStyle(fontSize: 16)),
                Text('Category: ${product['category']}', style: const TextStyle(fontSize: 16)),
                Text('Current Stock: $_currentStock', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                TextField(
                  controller: _stockInController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Quantity to Stock In',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _confirmStockIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        child: const Text('Confirm Stock In', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _showReportDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        child: const Text('Report Issue', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _stockInController.dispose();
    super.dispose();
  }
}

