import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mad/cartmanager.dart';
import 'package:mad/utility.dart';

class ProductDetailsPage extends StatelessWidget {
  final Map<String, dynamic> product;

  const ProductDetailsPage({super.key, required this.product});

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
                product['image_url'],
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
                      product['category'] ?? "General",
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
                          product['name'],
                          style: GoogleFonts.openSans(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        "RM ${product['price']}",
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
                    product['description'] ?? "No description available for this product.",
                    style: GoogleFonts.openSans(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
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
            // Favorite Button
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(Icons.favorite_border, color: Colors.grey),
            ),
            const SizedBox(width: 20),
            
            // Add to Cart Button
            Expanded(
              child: SizedBox(
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    CartManager.addToCart(product);
                    Utils.snackbar(context, "Added ${product['name']} to cart");
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
