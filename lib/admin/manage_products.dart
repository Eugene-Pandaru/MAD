import 'package:flutter/material.dart';
import 'package:mad/utility.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:io';

class ManageProductsPage extends StatefulWidget {
  const ManageProductsPage({super.key});

  @override
  State<ManageProductsPage> createState() => _ManageProductsPageState();
}

class _ManageProductsPageState extends State<ManageProductsPage> {
  final supabase = Supabase.instance.client;
  String _selectedCategory = "All";

  final List<String> _categories = ["All", "Medicine", "Vitamin", "Baby Care"];

  Widget _buildProductImage(String? url) {
    if (url == null || url.isEmpty) return const Icon(Icons.medication, color: Colors.teal);
    if (url.startsWith('http')) {
      return Image.network(url, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.medication, color: Colors.teal));
    }
    // Fallback for old local filenames or assets
    return Image.asset('assets/products/$url', fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.medication, color: Colors.teal));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text("Product Management", style: GoogleFonts.openSans(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
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
                    label: Text(cat, style: TextStyle(color: isSelected ? Colors.white : Colors.teal)),
                    selected: isSelected,
                    selectedColor: Colors.teal,
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
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.teal));
                
                List<Map<String, dynamic>> products = snapshot.data ?? [];

                if (_selectedCategory != "All") {
                  products = products.where((p) => p['category'] == _selectedCategory).toList();
                }

                products.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));

                return Column(
                  children: [
                    Container(
                      width: double.infinity,
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                      child: Text(
                        "Total Products: ${products.length}",
                        style: GoogleFonts.openSans(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.teal),
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: products.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[300]),
                                  const SizedBox(height: 10),
                                  Text("No products found", style: GoogleFonts.openSans(color: Colors.grey)),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: products.length,
                              padding: const EdgeInsets.all(15),
                              itemBuilder: (context, index) {
                                final product = products[index];
                                return Card(
                                  elevation: 0,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.grey[200]!)),
                                  child: Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: ListTile(
                                      leading: Container(
                                        width: 60, height: 60,
                                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.grey[100]),
                                        child: ClipRRect(borderRadius: BorderRadius.circular(10), child: _buildProductImage(product['image_url'])),
                                      ),
                                      title: Text(product['name'], style: GoogleFonts.openSans(fontWeight: FontWeight.bold)),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text("${product['category']}", style: GoogleFonts.openSans(color: Colors.teal, fontSize: 12, fontWeight: FontWeight.w600)),
                                          Text("RM ${double.tryParse(product['price'].toString())?.toStringAsFixed(2) ?? '0.00'} • Stock: ${product['stock_quantity']}", 
                                            style: GoogleFonts.openSans(fontSize: 13, color: Colors.grey[700])),
                                        ],
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.blue), onPressed: () => _showProductDialog(context, product: product)),
                                          IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _confirmDelete(product['id'])),
                                        ],
                                      ),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showProductDialog(context),
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Product?"),
        content: const Text("Are you sure? This action cannot be undone and will remove the product from the catalog."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              try {
                await supabase.from('products').delete().eq('id', id);
                if (mounted) {
                  Navigator.pop(context);
                  Utils.snackbar(context, "Product deleted successfully", color: Colors.red);
                }
              } catch (e) {
                if (mounted) Utils.snackbar(context, "Error deleting product: $e", color: Colors.red);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showProductDialog(BuildContext context, {Map<String, dynamic>? product}) {
    final bool isEdit = product != null;
    final nameController = TextEditingController(text: isEdit ? product['name'] : "");
    final priceController = TextEditingController(text: isEdit ? product['price'].toString() : "");
    final stockController = TextEditingController(text: isEdit ? product['stock_quantity'].toString() : "");
    final descController = TextEditingController(text: isEdit ? product['description'] : ""); 
    DateTime? selectedDate = isEdit && product['expiry_date'] != null ? DateTime.parse(product['expiry_date']) : null;
    String category = isEdit ? product['category'] : 'Medicine';
    String? imageUrl = isEdit ? product['image_url'] : null;
    File? tempPickedFile;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(isEdit ? "Edit Product" : "Add New Product"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final image = await picker.pickImage(source: ImageSource.gallery);
                    if (image != null) setState(() { tempPickedFile = File(image.path); });
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        height: 120, width: double.infinity,
                        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey[300]!)),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: tempPickedFile != null 
                              ? Image.file(tempPickedFile!, fit: BoxFit.cover) 
                              : _buildProductImage(imageUrl),
                        ),
                      ),
                      const CircleAvatar(
                        backgroundColor: Colors.black26,
                        radius: 20,
                        child: Icon(Icons.camera_alt, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                TextField(controller: nameController, decoration: _inputDeco("Product Name")),
                const SizedBox(height: 10),
                TextField(controller: priceController, decoration: _inputDeco("Price (RM)"), keyboardType: TextInputType.number),
                const SizedBox(height: 10),
                TextField(controller: stockController, decoration: _inputDeco("Initial Stock"), keyboardType: TextInputType.number),
                const SizedBox(height: 10),
                TextField(controller: descController, decoration: _inputDeco("Description"), maxLines: 3),
                const SizedBox(height: 15),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(context: context, initialDate: selectedDate ?? DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 3650)));
                    if (picked != null) setState(() => selectedDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(10)),
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(selectedDate == null ? "Select Expiry Date" : DateFormat('yyyy-MM-dd').format(selectedDate!)), const Icon(Icons.calendar_today, size: 20)]),
                  ),
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: category, decoration: _inputDeco("Category"),
                  items: ['Medicine', 'Vitamin', 'Baby Care'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) => setState(() => category = val!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty || priceController.text.isEmpty || stockController.text.isEmpty) { 
                  Utils.snackbar(context, "Fill all required fields", color: Colors.red); 
                  return; 
                }
                
                try {
                  if (tempPickedFile != null) {
                    final fileName = '${DateTime.now().millisecondsSinceEpoch}_product.png';
                    final uploadedUrl = await Utils.uploadImage(
                      file: tempPickedFile!, 
                      bucket: 'product', 
                      fileName: fileName
                    );
                    if (uploadedUrl != null) imageUrl = uploadedUrl;
                  }
                  
                  final data = {
                    'name': nameController.text, 
                    'price': double.tryParse(priceController.text) ?? 0.0, 
                    'stock_quantity': int.tryParse(stockController.text) ?? 0, 
                    'category': category, 
                    'description': descController.text, 
                    'expiry_date': selectedDate != null ? DateFormat('yyyy-MM-dd').format(selectedDate!) : null, 
                    'image_url': imageUrl
                  };
                  
                  if (isEdit) { 
                    await supabase.from('products').update(data).eq('id', product['id']); 
                    Utils.snackbar(context, "Product updated", color: Colors.green);
                  } else { 
                    await supabase.from('products').insert(data); 
                    Utils.snackbar(context, "Product added", color: Colors.green);
                  }
                  Navigator.pop(context);
                } catch (e) {
                   Utils.snackbar(context, "Error: $e", color: Colors.red);
                }
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String label) => InputDecoration(
    labelText: label,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
  );
}
