import 'package:flutter/material.dart';
import 'package:mad/utility.dart';
import 'package:mad/login.dart';
import 'package:mad/admin/manage_products.dart';
import 'package:mad/admin/manage_orders.dart';
import 'package:mad/admin/manage_inventory.dart';
import 'package:mad/admin/manage_customers.dart';
import 'package:mad/admin/manage_admins.dart';
import 'package:mad/admin/admin_profile.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    // Check if user is Superadmin for Admin Management visibility
    final bool isSuperAdmin = Utils.currentUser?['roles'] == 'Superadmin';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Pharmacy Admin"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminProfilePage())),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Utils.currentUser = null;
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginPage()), (route) => false);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.blueAccent,
                  child: Text(Utils.currentUser?['full_name']?[0] ?? "A", style: const TextStyle(color: Colors.white, fontSize: 24)),
                ),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Welcome back,", style: TextStyle(color: Colors.grey[600])),
                    Text(Utils.currentUser?['full_name'] ?? "Admin", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 30),
            const Text("Quick Insights", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            Row(
              children: [
                _buildStatCard("Orders", "24", Icons.shopping_basket, Colors.blue),
                const SizedBox(width: 15),
                _buildStatCard("Low Stock", "8", Icons.warning_amber_rounded, Colors.red),
              ],
            ),
            const SizedBox(height: 30),
            const Text("Management Modules", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 1.1,
              children: [
                _buildModuleCard(context, "Products", Icons.medication, Colors.teal, const ManageProductsPage()),
                _buildModuleCard(context, "Inventory", Icons.inventory_2, Colors.orange, const ManageInventoryPage()),
                _buildModuleCard(context, "Orders", Icons.receipt_long, Colors.blue, const ManageOrdersPage()),
                _buildModuleCard(context, "Customers", Icons.people, Colors.purple, const ManageCustomersPage()),
                if (isSuperAdmin)
                  _buildModuleCard(context, "Admins", Icons.admin_panel_settings, Colors.indigo, const ManageAdminsPage()),
                _buildModuleCard(context, "My Profile", Icons.account_circle, Colors.grey[700]!, const AdminProfilePage()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: color.withOpacity(0.1))),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 10),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(title, style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleCard(BuildContext context, String title, IconData icon, Color color, Widget page) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => page)),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
