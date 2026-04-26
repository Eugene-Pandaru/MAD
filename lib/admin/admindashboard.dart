import 'package:flutter/material.dart';
import 'package:mad/utility.dart';
import 'package:mad/startpage.dart';
import 'package:mad/admin/manage_products.dart';
import 'package:mad/admin/manage_orders.dart';
import 'package:mad/admin/manage_inventory.dart';
import 'package:mad/admin/manage_customers.dart';
import 'package:mad/admin/manage_admins.dart';
import 'package:mad/admin/admin_profile.dart';
import 'package:mad/admin/low_stock_page.dart';
import 'package:mad/admin/expiry_page.dart';
import 'package:mad/admin/manage_vouchers.dart';
import 'package:mad/admin/manage_rewards.dart';
import 'package:mad/admin/manage_pharmacists.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  void _onTabChange(int index) {
    setState(() {
      _selectedIndex = index;
    });
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
    final String role = Utils.currentUser?['roles'] ?? "Admin";
    final String title = (role == 'Superadmin') ? "SuperAdmin" : "Admin Dashboard";
    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom != 0;

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
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                final bool shouldLogout = await _showLogoutConfirmation();
                if (shouldLogout && mounted) {
                   Utils.currentUser = null;
                   Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const Startpage()), (route) => false);
                }
              },
            ),
          ],
        ),
        
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            DashboardHome(onTabChange: _onTabChange),
            const ManageOrdersPage(),
            const ManageInventoryPage(),
            AdminProfilePage(
              key: ValueKey("${Utils.currentUser?['id']}_${Utils.currentUser?['profile_url']}_${Utils.currentUser?['full_name']}"),
              onUpdate: () => setState(() {}),
            ),
          ],
        ),

        bottomNavigationBar: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 8.0,
          child: SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.dashboard, "Home", 0),
                _buildNavItem(Icons.receipt_long, "Orders", 1),
                const SizedBox(width: 40), 
                _buildNavItem(Icons.inventory, "Stock", 2),
                _buildNavItem(Icons.person, "Profile", 3),
              ],
            ),
          ),
        ),

        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: isKeyboardOpen ? null : FloatingActionButton(
          backgroundColor: Colors.blueAccent,
          onPressed: () => Utils.snackbar(context, "Scanning Barcode..."),
          child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 30),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    bool isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSelected ? Colors.blueAccent : Colors.grey),
          Text(label, style: TextStyle(color: isSelected ? Colors.blueAccent : Colors.grey, fontSize: 10)),
        ],
      ),
    );
  }
}

class DashboardHome extends StatelessWidget {
  final Function(int) onTabChange;
  const DashboardHome({super.key, required this.onTabChange});

  @override
  Widget build(BuildContext context) {
    final bool isSuperAdmin = Utils.currentUser?['roles'] == 'Superadmin';
    final supabase = Supabase.instance.client;

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase.from('products').stream(primaryKey: ['id']),
      builder: (context, snapshot) {
        int lowStockCount = 0;
        int expiryCount = 0;

        if (snapshot.hasData) {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final threeMonthsLimit = today.add(const Duration(days: 90));
          
          lowStockCount = snapshot.data!.where((p) => (p['stock_quantity'] ?? 0) < 20).length;
          
          expiryCount = snapshot.data!.where((p) {
             if (p['expiry_date'] == null) return false;
             try {
               DateTime exp = DateTime.parse(p['expiry_date']);
               DateTime expDate = DateTime(exp.year, exp.month, exp.day);
               return expDate.isBefore(threeMonthsLimit) && (expDate.isAfter(today) || expDate.isAtSameMomentAs(today));
             } catch (e) {
               return false;
             }
          }).length;
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Quick Insights", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              Row(
                children: [
                  _buildInsightCard(context, "Low Stock", lowStockCount.toString(), Icons.warning_amber, Colors.red, const LowStockPage()),
                  const SizedBox(width: 15),
                  _buildInsightCard(context, "Expiry Item", expiryCount.toString(), Icons.event_busy, Colors.orange, const ExpiryPage()),
                ],
              ),
              const SizedBox(height: 30),
              const Text("Management Modules", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.85,
                children: [
                  _buildModuleCard(context, "Products", Icons.medication, Colors.teal, const ManageProductsPage()),
                  _buildModuleCard(context, "Inventory", Icons.inventory_2, Colors.blueGrey, const ManageInventoryPage()),
                  _buildModuleCard(context, "Orders", Icons.receipt_long, Colors.blue, const ManageOrdersPage()),
                  _buildModuleCard(context, "Customers", Icons.people, Colors.purple, const ManageCustomersPage()),
                  if (isSuperAdmin)
                    _buildModuleCard(context, "Staffs", Icons.admin_panel_settings, Colors.indigo, const ManageAdminsPage()),
                  _buildModuleCard(context, "Specialists", Icons.medical_services, Colors.teal, const ManagePharmacistsPage()),
                  _buildModuleCard(context, "Rewards", Icons.card_giftcard, Colors.pink, const ManageRewardsPage()),
                  _buildModuleCard(context, "Vouchers", Icons.confirmation_number, Colors.amber, const ManageVouchersPage()),
                  _buildModuleCard(context, "Profiles", Icons.account_circle, Colors.grey, null, onTap: () => onTabChange(3)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInsightCard(BuildContext context, String title, String count, IconData icon, Color color, Widget page) {
    return Expanded(
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => page)),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: color.withOpacity(0.1))),
          child: Column(
            children: [
              Icon(icon, color: color, size: 30),
              const SizedBox(height: 8),
              Text(count, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModuleCard(BuildContext context, String title, IconData icon, Color color, Widget? page, {VoidCallback? onTap}) {
    return InkWell(
      onTap: () { 
        if (onTap != null) {
          onTap();
        } else if (page != null) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => page)); 
        }
      },
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
