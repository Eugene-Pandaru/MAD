import 'package:flutter/material.dart';
import 'package:mad/utility.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ManageProductsPage extends StatefulWidget {
  const ManageProductsPage({super.key});

  @override
  State<ManageProductsPage> createState() => _ManageProductsPageState();
}

class _ManageProductsPageState extends State<ManageProductsPage> {
  final supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Product Management"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase.from('products').stream(primaryKey: ['id']).order('created_at'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final products = snapshot.data ?? [];

          return ListView.builder(
            itemCount: products.length,
            padding: const EdgeInsets.all(10),
            itemBuilder: (context, index) {
              final product = products[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    // 🖼️ Print out image from assets based on name in database
                    backgroundImage: AssetImage('assets/${product['image_url']}'),
                    onBackgroundImageError: (_, __) => const Icon(Icons.broken_image),
                  ),
                  title: Text(product['name']),
                  subtitle: Text("${product['category']} - RM${product['price']} (Stock: ${product['stock_quantity']})"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showEditProductDialog(context, product),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteProduct(product['id']),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddProductDialog(context),
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _deleteProduct(String id) async {
    await supabase.from('products').delete().eq('id', id);
    Utils.snackbar(context, "Product deleted");
  }

  void _showAddProductDialog(BuildContext context) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final stockController = TextEditingController();
    String category = 'Medicine';
    XFile? pickedImage;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Add New Product"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: "Name")),
                TextField(controller: priceController, decoration: const InputDecoration(labelText: "Price"), keyboardType: TextInputType.number),
                TextField(controller: stockController, decoration: const InputDecoration(labelText: "Stock Quantity"), keyboardType: TextInputType.number),
                const SizedBox(height: 10),
                DropdownButton<String>(
                  value: category,
                  isExpanded: true,
                  items: ['Medicine', 'Vitamin', 'Baby Care'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) => setState(() => category = val!),
                ),
                const SizedBox(height: 15),
                ElevatedButton.icon(
                  onPressed: () async {
                    final picker = ImagePicker();
                    pickedImage = await picker.pickImage(source: ImageSource.gallery);
                    setState(() {});
                  },
                  icon: const Icon(Icons.image),
                  label: Text(pickedImage == null ? "Import Product Image" : "Image Attached: ${pickedImage!.name}"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                // 🚀 Logic: Save record to DB with image name
                String imageName = pickedImage != null ? pickedImage!.name : "default_product.png";
                
                await supabase.from('products').insert({
                  'name': nameController.text,
                  'price': double.parse(priceController.text),
                  'stock_quantity': int.parse(stockController.text),
                  'category': category,
                  'image_url': imageName,
                });
                
                Navigator.pop(context);
                Utils.snackbar(context, "Product Saved to Inventory");
              },
              child: const Text("Save Product"),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProductDialog(BuildContext context, Map<String, dynamic> product) {
     // Implementation for Edit
  }
}
