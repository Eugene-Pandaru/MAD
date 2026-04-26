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
    int stock = widget.product['stock_quantity'] ?? 0;

    // 🛒 Calculate how many of this product are already in the cart
    int cartIndex = CartManager.cartItems.indexWhere((item) => item.name == widget.product['name']);
    int cartQuantity = cartIndex != -1 ? CartManager.cartItems[cartIndex].quantity : 0;

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
                        "RM ${double.tryParse(widget.product['price'].toString())?.toStringAsFixed(2) ?? '0.00'}",
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
                        onPressed: () {
                          // 🛡️ CHECK AGAINST DATABASE STOCK + CART QUANTITY
                          if ((quantity + cartQuantity) < stock) {
                            setState(() => quantity++);
                          } else {
                            Utils.snackbar(context, "Not enough stock", color: Colors.red);
                          }
                        },
                        icon: const Icon(Icons.add_circle_outline, color: Color(0xFF1392AB), size: 30),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // 📦 Stock Info
                  Row(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined, 
                        color: (stock - cartQuantity) > 0 ? Colors.grey : Colors.red, 
                        size: 20
                      ),
                      const SizedBox(width: 8),
                      Text(
                        (stock - cartQuantity) > 0 ? "In Stock" : "Out of Stock",
                        style: GoogleFonts.openSans(
                          color: (stock - cartQuantity) > 0 ? Colors.green : Colors.red, 
                          fontWeight: FontWeight.bold
                        ),
                      ),
                      if (stock > 0) ...[
                        const SizedBox(width: 10),
                        Text("(${stock - cartQuantity} available)", style: GoogleFonts.openSans(color: Colors.grey, fontSize: 12)),
                      ]
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
                  onPressed: (stock - cartQuantity) <= 0 
                  ? () => Utils.snackbar(context, "Item Not Available Now", color: Colors.red)
                  : () {
                    // One final check before adding to cart
                    if ((quantity + cartQuantity) > stock) {
                       Utils.snackbar(context, "Not enough stock", color: Colors.red);
                       return;
                    }

                    CartManager.addToCart(widget.product, quantity: quantity);
                    
                    Utils.snackbar(
                      context, 
                      "Successfully added into cart", 
                      color: Colors.green
                    );
                    
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const ProductListPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (stock - cartQuantity) > 0 ? const Color(0xFF1392AB) : Colors.grey,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 0,
                  ),
                  child: Text(
                    (stock - cartQuantity) > 0 ? "Add to Cart" : "Out of Stock",
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
