import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mad/utility.dart';
import 'package:mad/cartmanager.dart';
import 'package:mad/cart.dart';
import 'package:mad/productdetails.dart';
import 'package:mad/userprofile.dart';
import 'package:mad/orderhistory.dart';
import 'package:mad/appointmenthistory.dart';
import 'package:mad/home.dart';

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  final supabase = Supabase.instance.client;
  String selectedCategory = "All";

  List<Map<String, dynamic>> allProducts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    try {
      final data = await supabase.from('products').select();
      setState(() {
        allProducts = List<Map<String, dynamic>>.from(data);
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching products: $e");
      setState(() => isLoading = false);
    }
  }

  void _showSuccessDialog(BuildContext context, String productName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 80),
              const SizedBox(height: 20),
              Text(
                "Successfully added into cart",
                textAlign: TextAlign.center,
                style: GoogleFonts.openSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1392AB),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    Navigator.pop(context); // Close Dialog
                  },
                  child: Text("OK", style: GoogleFonts.openSans(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> displayedProducts = allProducts.where((item) {
      return selectedCategory == "All" || item['category'] == selectedCategory;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🟢 Header (Matching home.dart style)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    "Medicine Store",
                    style: GoogleFonts.openSans(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),

            // 🟢 Category Bar (Mint Green style from home.dart)
            SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 15),
                children: ["All", "Medicine", "Vitamin", "Baby Care", "Skin Care"]
                    .map((cat) => Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: ChoiceChip(
                            label: Text(
                              cat,
                              style: GoogleFonts.openSans(
                                color: selectedCategory == cat
                                    ? Colors.white
                                    : Colors.black,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            selected: selectedCategory == cat,
                            selectedColor: const Color(0xFF1392AB),
                            backgroundColor: const Color(0xFF8DC6BC).withValues(alpha: 0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            onSelected: (val) =>
                                setState(() => selectedCategory = cat),
                          ),
                        ))
                    .toList(),
              ),
            ),

            const SizedBox(height: 10),

            // 🟢 Product Grid
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : displayedProducts.isEmpty
                      ? Center(
                          child: Text(
                            "No items found",
                            style: GoogleFonts.openSans(),
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(15),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 15,
                            mainAxisSpacing: 15,
                          ),
                          itemCount: displayedProducts.length,
                          itemBuilder: (context, index) {
                            final item = displayedProducts[index];
                            return InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ProductDetailsPage(product: item),
                                  ),
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: const BorderRadius.vertical(
                                            top: Radius.circular(20)),
                                        child: Container(
                                          width: double.infinity,
                                          color: Colors.white,
                                          child: Image.network(
                                            item['image_url'],
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item['name'],
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.openSans(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                "RM ${item['price']}",
                                                style: GoogleFonts.openSans(
                                                  color: const Color(0xFF1392AB),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              // 🟢 "+" Button to add to cart
                                              GestureDetector(
                                                onTap: () {
                                                  CartManager.addToCart(item);
                                                  _showSuccessDialog(context, item['name']);
                                                },
                                                child: Container(
                                                  padding: const EdgeInsets.all(5),
                                                  decoration: const BoxDecoration(
                                                    color: Color(0xFF1392AB),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    Icons.add,
                                                    color: Colors.white,
                                                    size: 20,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),

      // 🟢 Floating Cart Button (Bottom Right)
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (context) => const CartPage())),
        backgroundColor: const Color(0xFF1392AB),
        child: const Icon(Icons.shopping_cart, color: Colors.white),
      ),

      // 🟢 Bottom Navigation Bar (Matching home.dart)
      bottomNavigationBar: Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            buildNavItem(Icons.home_outlined, "Home", false, onTap: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomePage()));
            }),
            buildNavItem(Icons.medical_services, "Medicine", true),
            
            Transform.translate(
              offset: const Offset(0, -15),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const AppointmentHistoryPage()));
                },
                child: Container(
                  height: 60,
                  width: 60,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1392AB),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.calendar_month, color: Colors.white, size: 30),
                ),
              ),
            ),

            buildNavItem(Icons.receipt_long, "Orders", false, onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const OrderHistoryPage()));
            }),
            buildNavItem(Icons.person_outline, "Profile", false, onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const UserProfilePage()));
            }),
          ],
        ),
      ),
    );
  }

  Widget buildNavItem(IconData icon, String label, bool isActive, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon,
              color: isActive ? const Color(0xFF1392AB) : Colors.grey, size: 28),
          const SizedBox(height: 4),
          Text(label,
              style: GoogleFonts.openSans(
                  color: isActive ? const Color(0xFF1392AB) : Colors.grey,
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}
