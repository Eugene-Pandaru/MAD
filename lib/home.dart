import 'package:flutter/material.dart';
import 'package:mad/utility.dart';
import 'package:mad/userprofile.dart';
import 'package:mad/points.dart';
import 'package:mad/vouchers.dart';
import 'package:mad/rewards.dart';
import 'package:mad/startpage.dart';
import 'package:mad/pharmacy_map_screen.dart'; // 👈 Import Map
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'orderhistory.dart';
import 'chatbot.dart';
import 'productlist.dart';
import 'appointmenthistory.dart';
import 'productdetails.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final supabase = Supabase.instance.client;
  final PageController _promotionController = PageController();
  final TextEditingController _searchController = TextEditingController();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  int _currentPromoPage = 0;
  List<Map<String, dynamic>> _searchResults = [];
  
  late Future<List<Map<String, dynamic>>> _initialProductsFuture;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _initialProductsFuture = _fetchInitialProducts();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _promotionController.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _onSearchChanged() async {
    final query = _searchController.text;
    if (query.isEmpty) {
      _removeOverlay();
      setState(() {
        _searchResults = [];
      });
      return;
    }

    final data = await supabase
        .from('products')
        .select()
        .ilike('name', '%$query%')
        .limit(5);

    setState(() {
      _searchResults = List<Map<String, dynamic>>.from(data);
    });

    _showOverlay();
  }

  void _showOverlay() {
    _removeOverlay();
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    var size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width - 40,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0.0, 50.0),
          child: Material(
            elevation: 4.0,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 300),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: _searchResults.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(15),
                      child: Text("No products found", style: GoogleFonts.openSans()),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final product = _searchResults[index];
                        return ListTile(
                          leading: Image.network(product['image_url'], width: 40, height: 40, fit: BoxFit.cover),
                          title: Text(product['name'], style: GoogleFonts.openSans(fontSize: 14)),
                          subtitle: Text("RM ${product['price']}", style: GoogleFonts.openSans(fontSize: 12, color: const Color(0xFF1392AB))),
                          onTap: () {
                            _searchController.clear();
                            _removeOverlay();
                            _navigateTo(ProductDetailsPage(product: product));
                          },
                        );
                      },
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _navigateTo(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (context) => page));
    if (mounted) setState(() {}); 
  }

  Future<bool> _showLogoutConfirmation() async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Confirm Logout"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text("No", style: GoogleFonts.openSans(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text("Yes", style: GoogleFonts.openSans(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final String nickname = Utils.currentUser?['nickname'] ?? "User";
    final userId = Utils.currentUser?['id'];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        final bool shouldLogout = await _showLogoutConfirmation();
        if (shouldLogout && mounted) {
           Utils.currentUser = null;
           Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const Startpage()), (route) => false);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 30,
                        backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11'),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Hi, Welcome Back,", style: GoogleFonts.openSans(color: Colors.grey, fontSize: 14)),
                            Text(nickname, style: GoogleFonts.openSans(fontSize: 20, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _navigateTo(const PointsPage()),
                        child: StreamBuilder<List<Map<String, dynamic>>>(
                          stream: supabase.from('points').stream(primaryKey: ['id']).eq('user_id', userId ?? ''),
                          builder: (context, snapshot) {
                            int totalPts = 0;
                            if (snapshot.hasData) {
                              totalPts = snapshot.data!.fold(0, (sum, item) => sum + (int.tryParse(item['points_amount'].toString()) ?? 0));
                            }
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1392AB).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.stars, color: Color(0xFF1392AB), size: 18),
                                  const SizedBox(width: 4),
                                  Text("$totalPts pts", style: GoogleFonts.openSans(fontWeight: FontWeight.bold, color: const Color(0xFF1392AB))),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
      
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: CompositedTransformTarget(
                    link: _layerLink,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: "Search a Product",
                          hintStyle: GoogleFonts.openSans(),
                          border: InputBorder.none,
                          icon: const Icon(Icons.search, color: Colors.grey),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              _removeOverlay();
                            },
                          ),
                        ),
                        style: GoogleFonts.openSans(),
                      ),
                    ),
                  ),
                ),
      
                const SizedBox(height: 25),
      
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    height: 160,
                    child: PageView(
                      controller: _promotionController,
                      onPageChanged: (index) => setState(() => _currentPromoPage = index),
                      children: [
                        buildPromoBanner("5.5 Mega Sale", "Get up to 50% off on selected items!", const Color(0xFF1392AB), 'https://cdn-icons-png.flaticon.com/512/2769/2769257.png'),
                        buildPromoBanner("Baby Care Promo", "Buy 3 Free 1 on all baby essentials.", Colors.teal.shade400, 'https://cdn-icons-png.flaticon.com/512/2361/2361131.png'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(2, (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentPromoPage == index ? const Color(0xFF1392AB) : Colors.grey.shade300,
                      ),
                    )),
                  ),
                ),
      
                const SizedBox(height: 25),
      
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Quick Links", style: GoogleFonts.openSans(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text("See All", style: GoogleFonts.openSans(color: Colors.grey.shade600, fontSize: 14)),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                SizedBox(
                  height: 100,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(left: 20),
                    children: [
                      buildCategoryBox("Location", Icons.location_on, const Color(0xFF8DC6BC), onTap: () {
                         _navigateTo(const PharmacyMapScreen()); // 👈 Link to Map
                      }),
                      buildCategoryBox("Pharmacy Bot", Icons.smart_toy, const Color(0xFF8DC6BC), onTap: () {
                        _navigateTo(const ChatBotPage());
                      }),
                      buildCategoryBox("Rewards", Icons.card_giftcard, const Color(0xFF8DC6BC), onTap: () {
                         _navigateTo(const RewardsPage());
                      }),
                      buildCategoryBox("Vouchers", Icons.confirmation_number, const Color(0xFF8DC6BC), onTap: () {
                         _navigateTo(const VouchersPage());
                      }),
                    ],
                  ),
                ),
      
                const SizedBox(height: 25),
      
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("All Products", style: GoogleFonts.openSans(fontSize: 18, fontWeight: FontWeight.bold)),
                      GestureDetector(
                        onTap: () => _navigateTo(const ProductListPage()),
                        child: Text("See All", style: GoogleFonts.openSans(color: Colors.grey.shade600, fontSize: 14)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
      
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _initialProductsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final products = snapshot.data ?? [];
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final p = products[index];
                        return GestureDetector(
                          onTap: () => _navigateTo(ProductDetailsPage(product: p)),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 15),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(15),
                                  child: Image.network(p['image_url'], width: 80, height: 80, fit: BoxFit.cover),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(p['name'], style: GoogleFonts.openSans(fontSize: 16, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 5),
                                      Text("RM ${p['price']}", style: GoogleFonts.openSans(color: const Color(0xFF1392AB), fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 5),
                                      Text(p['category'] ?? "General", style: GoogleFonts.openSans(color: Colors.grey, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () => _navigateTo(ProductDetailsPage(product: p)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1392AB),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: Text("Buy", style: GoogleFonts.openSans(color: Colors.white, fontSize: 12)),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
        bottomNavigationBar: Container(
          height: 80,
          decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              buildNavItem(Icons.home, "Home", true),
              buildNavItem(Icons.medical_services_outlined, "Medicine", false, onTap: () => _navigateTo(const ProductListPage())),
              Transform.translate(
                offset: const Offset(0, -15),
                child: GestureDetector(
                  onTap: () => _navigateTo(const AppointmentHistoryPage()),
                  child: Container(
                    height: 60,
                    width: 60,
                    decoration: const BoxDecoration(color: Color(0xFF1392AB), shape: BoxShape.circle),
                    child: const Icon(Icons.calendar_month, color: Colors.white, size: 30),
                  ),
                ),
              ),
              buildNavItem(Icons.receipt_long, "Orders", false, onTap: () => _navigateTo(const OrderHistoryPage())),
              buildNavItem(Icons.person_outline, "Profile", false, onTap: () => _navigateTo(const UserProfilePage())),
            ],
          ),
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchInitialProducts() async {
    final response = await supabase.from('products').select().limit(10);
    return List<Map<String, dynamic>>.from(response);
  }

  Widget buildPromoBanner(String title, String subtitle, Color color, String imageUrl) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.openSans(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                SizedBox(width: 180, child: Text(subtitle, style: GoogleFonts.openSans(color: Colors.white70, fontSize: 12))),
              ],
            ),
          ),
          Positioned(right: 10, bottom: 10, child: Image.network(imageUrl, height: 100, errorBuilder: (c, e, s) => const Icon(Icons.shopping_bag, size: 80, color: Colors.white24))),
        ],
      ),
    );
  }

  Widget buildCategoryBox(String label, IconData icon, Color color, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 15),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(15)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 30),
            const SizedBox(height: 8),
            Text(label, style: GoogleFonts.openSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
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
          Icon(icon, color: isActive ? const Color(0xFF1392AB) : Colors.grey, size: 28),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.openSans(color: isActive ? const Color(0xFF1392AB) : Colors.grey, fontSize: 12, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}
