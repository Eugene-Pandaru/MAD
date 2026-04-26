import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mad/cartmanager.dart';
import 'package:mad/footer.dart';
import 'package:mad/utility.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'checkout.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final supabase = Supabase.instance.client;

  // Function to show the removal confirmation dialog
  void _showRemoveDialog(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text("Remove Item?", style: GoogleFonts.openSans(fontWeight: FontWeight.bold)),
          content: Text("Do you want to remove ${CartManager.cartItems[index].name} from your cart?", style: GoogleFonts.openSans()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Close dialog
              child: Text("Cancel", style: GoogleFonts.openSans(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  CartManager.cartItems.removeAt(index);
                });
                Navigator.pop(context);
                Utils.snackbar(context, "Item removed", color: Colors.red);
              },
              child: Text("Remove", style: GoogleFonts.openSans(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // 🔍 Function to check stock from database before adding quantity
  Future<void> _increaseQuantity(int index) async {
    final item = CartManager.cartItems[index];
    
    try {
      // Fetch current stock from database
      final response = await supabase
          .from('products')
          .select('stock_quantity')
          .eq('name', item.name)
          .single();
      
      final int stock = response['stock_quantity'] ?? 0;

      if (item.quantity < stock) {
        setState(() {
          item.quantity++;
        });
      } else {
        if (mounted) {
          Utils.snackbar(context, "Not enough stock available", color: Colors.red);
        }
      }
    } catch (e) {
      if (mounted) {
        Utils.snackbar(context, "Error checking stock: $e", color: Colors.red);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 🟢 Header (Matching home/productlist style)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    "My Cart",
                    style: GoogleFonts.openSans(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: CartManager.cartItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey.shade300),
                          const SizedBox(height: 10),
                          Text("Your cart is empty", style: GoogleFonts.openSans(color: Colors.grey, fontSize: 16)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: CartManager.cartItems.length,
                      padding: const EdgeInsets.only(bottom: 20),
                      itemBuilder: (context, index) {
                        final item = CartManager.cartItems[index];
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: Image.network(
                                  item.imageUrl,
                                  width: 70,
                                  height: 70,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.medication, size: 40),
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.name, 
                                        style: GoogleFonts.openSans(fontWeight: FontWeight.bold, fontSize: 16)),
                                    const SizedBox(height: 5),
                                    Text("RM ${item.price.toStringAsFixed(2)}", 
                                        style: GoogleFonts.openSans(color: const Color(0xFF1392AB), fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  // MINUS BUTTON
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, color: Color(0xFF1392AB)),
                                    onPressed: () {
                                      if (item.quantity > 1) {
                                        setState(() {
                                          item.quantity--;
                                        });
                                      } else {
                                        _showRemoveDialog(index); 
                                      }
                                    },
                                  ),
                                  Text("${item.quantity}", style: GoogleFonts.openSans(fontSize: 16, fontWeight: FontWeight.bold)),
                                  // PLUS BUTTON
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline, color: Color(0xFF1392AB)),
                                    onPressed: () => _increaseQuantity(index), // 👈 Updated to check database
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),

            /// Bottom Summary and Checkout
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Total Amount", style: GoogleFonts.openSans(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                      Text(
                          "RM ${CartManager.getTotalPrice().toStringAsFixed(2)}",
                          style: GoogleFonts.openSans(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF1392AB))
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1392AB),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 0,
                      ),
                      onPressed: CartManager.cartItems.isEmpty ? null : () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const CheckoutPage())
                        );
                      },
                      child: Text("Proceed to Checkout", style: GoogleFonts.openSans(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Footer(),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
