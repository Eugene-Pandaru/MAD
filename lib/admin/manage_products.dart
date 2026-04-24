import 'package:flutter/material.dart';
import 'package:mad/utility.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
        stream: supabase.from('products').stream(primaryKey: ['id']),
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
                    backgroundImage: product['image_url'] != null ? NetworkImage(product['image_url']) : null,
                    child: product['image_url'] == null ? const Icon(Icons.medication) : null,
                  ),
                  title: Text(product['name']),
                  subtitle: Text("${product['category']} - RM${product['price']}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () {}),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteProduct(product['id'])),
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
    String category = 'Medicine';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Add Product"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: "Name")),
              TextField(controller: priceController, decoration: const InputDecoration(labelText: "Price"), keyboardType: TextInputType.number),
              DropdownButton<String>(
                value: category,
                isExpanded: true,
                items: ['Medicine', 'Vitamin', 'Baby Care'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) => setState(() => category = val!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                await supabase.from('products').insert({
                  'name': nameController.text,
                  'price': double.parse(priceController.text),
                  'category': category,
                });
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }
}
