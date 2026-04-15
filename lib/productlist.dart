import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Import Supabase
import 'package:mad/utility.dart';
import 'package:mad/cartmanager.dart';
import 'package:mad/cart.dart';
import 'package:mad/footer.dart';

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  final supabase = Supabase.instance.client;

  String selectedCategory = "All";
  bool isSortedAlphabetical = false;

  // This will store the data from Supabase
  List<Map<String, dynamic>> allProducts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProducts(); // Load data when page opens
  }

  Future<void> fetchProducts() async {
    try {
      final data = await supabase.from('products').select();
      setState(() {
        allProducts = List<Map<String, dynamic>>.from(data);
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching products: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Apply Filtering
    List<Map<String, dynamic>> displayedProducts = allProducts.where((item) {
      return selectedCategory == "All" || item['category'] == selectedCategory;
    }).toList();

    // Apply Sorting
    if (isSortedAlphabetical) {
      displayedProducts.sort((a, b) => a['name'].compareTo(b['name']));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Pharmacy Store"),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: Icon(isSortedAlphabetical ? Icons.sort_by_alpha : Icons.filter_list),
            onPressed: () => setState(() => isSortedAlphabetical = !isSortedAlphabetical),
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CartPage())),
          )
        ],
      ),
      body: Column(
        children: [
          // Category Bar
          SizedBox(
            height: 60,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(10),
              children: ["All", "Medicine", "Vitamin", "Baby Care"].map((cat) => Padding(
                padding: const EdgeInsets.only(right: 10),
                child: ChoiceChip(
                  label: Text(cat),
                  selected: selectedCategory == cat,
                  onSelected: (val) => setState(() => selectedCategory = cat),
                ),
              )).toList(),
            ),
          ),

          // Product Grid
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : displayedProducts.isEmpty
                ? const Center(child: Text("No items found"))
                : GridView.builder(
              padding: const EdgeInsets.all(15),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.7,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10
              ),
              itemCount: displayedProducts.length,
              itemBuilder: (context, index) {
                final item = displayedProducts[index];
                return Card(
                  child: Column(
                    children: [
                      Expanded(child: Image.network(item['image_url'])),
                      Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text("RM ${item['price']}", style: const TextStyle(color: Colors.orange)),
                      ElevatedButton(
                        onPressed: () {
                          CartManager.addToCart(item);
                          Utils.snackbar(context, "Added ${item['name']}");
                        },
                        child: const Text("Add"),
                      )
                    ],
                  ),
                );
              },
            ),
          ),
          const Footer(),
        ],
      ),
    );
  }
}