import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mad/utility.dart';
import 'package:mad/cartmanager.dart';
import 'package:mad/cart.dart';
import 'package:mad/productdetails.dart';
import 'package:mad/home.dart';
import 'package:mad/orderhistory.dart';
import 'package:mad/appointmenthistory.dart';
import 'package:mad/userprofile.dart';

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  final supabase = Supabase.instance.client;
  final ScrollController _scrollController = ScrollController();
  
  String selectedCategory = "All";
  List<Map<String, dynamic>> allProducts = [];
  bool isLoading = false;
  
  // Pagination State
  int currentPage = 0;
  final int pageSize = 20;
  bool hasMore = true;

  @override
  void initState() {
    super.initState();
    fetchProducts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!isLoading && hasMore) {
        fetchProducts();
      }
    }
  }

  Future<void> fetchProducts({bool reset = false}) async {
    if (reset) {
      setState(() {
        allProducts = [];
        currentPage = 0;
        hasMore = true;
      });
    }

    setState(() => isLoading = true);

    try {
      var query = supabase.from('products').select();
      
      if (selectedCategory != "All") {
        query = query.eq('category', selectedCategory);
      }

      final data = await query.range(currentPage * pageSize, (currentPage + 1) * pageSize - 1);
      
      final List<Map<String, dynamic>> fetchedProducts = List<Map<String, dynamic>>.from(data);

      setState(() {
        allProducts.addAll(fetchedProducts);
        isLoading = false;
        currentPage++;
        if (fetchedProducts.length < pageSize) {
          hasMore = false;
        }
      });
    } catch (e) {
      debugPrint("Error fetching products: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🟢 Header
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

            // 🟢 Category Bar
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
                            onSelected: (val) {
                              if (val) {
                                setState(() => selectedCategory = cat);
                                fetchProducts(reset: true);
                              }
                            },
                          ),
                        ))
                    .toList(),
              ),
            ),

            const SizedBox(height: 10),

            // 🟢 Product Grid
            Expanded(
              child: allProducts.isEmpty && isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF1392AB)))
                  : allProducts.isEmpty
                      ? Center(
                          child: Text(
                            "No items found",
                            style: GoogleFonts.openSans(),
                          ),
                        )
                      : GridView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(15),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 15,
                            mainAxisSpacing: 15,
                          ),
                          itemCount: allProducts.length + (hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == allProducts.length) {
                              return const Center(child: CircularProgressIndicator(color: Color(0xFF1392AB)));
                            }

                            final item = allProducts[index];
                            double price = double.tryParse(item['price'].toString()) ?? 0.0;
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
                                            errorBuilder: (c, e, s) => const Icon(Icons.image, size: 50),
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
                                                "RM ${price.toStringAsFixed(2)}",
                                                style: GoogleFonts.openSans(
                                                  color: const Color(0xFF1392AB),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              // 🟢 Updated "+" Button
                                              GestureDetector(
                                                onTap: () {
                                                  CartManager.addToCart(item);
                                                  // ✅ FIXED: Using modern floating snackbar
                                                  Utils.snackbar(
                                                    context, 
                                                    "Successfully added into cart",
                                                      color: Colors.green // 👈 Changed to green
                                                  );
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

      // 🟢 Floating Cart Button
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (context) => const CartPage())),
        backgroundColor: const Color(0xFF1392AB),
        child: const Icon(Icons.shopping_cart, color: Colors.white),
      ),

      // 🟢 Bottom Navigation Bar
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
