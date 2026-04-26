import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mad/cartmanager.dart';
import 'package:mad/utility.dart';
import 'package:mad/productlist.dart';

class ProductDetailsPage extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailsPage({super.key, required this.product});

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  int quantity = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Product Details",
          style: GoogleFonts.openSans(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🖼 Product Image
            Container(
              height: 300,
              width: double.infinity,
              color: Colors.grey.shade50,
              child: Image.network(
                widget.product['image_url'],
                fit: BoxFit.contain,
                errorBuilder: (c, e, s) => const Icon(Icons.image, size: 100, color: Colors.grey),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 📂 Category Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1392AB).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.product['category'] ?? "General",
                      style: GoogleFonts.openSans(
                        color: const Color(0xFF1392AB),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // 🏷 Name and Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.product['name'],
                          style: GoogleFonts.openSans(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        "RM ${widget.product['price']}",
                        style: GoogleFonts.openSans(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1392AB),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 📝 Description Header
                  Text(
                    "Description",
                    style: GoogleFonts.openSans(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.product['description'] ?? "No description available for this product.",
                    style: GoogleFonts.openSans(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
                  ),

                  const SizedBox(height: 30),

                  // 📦 Quantity Selector
                  Text(
                    "Quantity",
                    style: GoogleFonts.openSans(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          if (quantity > 1) setState(() => quantity--);
                        },
                        icon: const Icon(Icons.remove_circle_outline, color: Color(0xFF1392AB), size: 30),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: Text(
                          "$quantity",
                          style: GoogleFonts.openSans(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(() => quantity++),
                        icon: const Icon(Icons.add_circle_outline, color: Color(0xFF1392AB), size: 30),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // 📦 Stock Info (Mock)
                  Row(
                    children: [
                      const Icon(Icons.inventory_2_outlined, color: Colors.grey, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        "In Stock",
                        style: GoogleFonts.openSans(color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // 🛒 Bottom Action Bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: Row(
          children: [
            // Add to Cart Button
            Expanded(
              child: SizedBox(
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    CartManager.addToCart(widget.product, quantity: quantity);
                    
                    // 🛠️ Show modern floating snackbar instead of dialog
                    Utils.snackbar(
                      context, 
                      "Successfully added into cart", 
                      color: Colors.green // 👈 Changed to green
                    );
                    
                    // 🚀 Return user to the product list page
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const ProductListPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1392AB),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 0,
                  ),
                  child: Text(
                    "Add to Cart",
                    style: GoogleFonts.openSans(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
