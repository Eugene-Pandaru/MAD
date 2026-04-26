import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class ExpiryPage extends StatefulWidget {
  const ExpiryPage({super.key});

  @override
  State<ExpiryPage> createState() => _ExpiryPageState();
}

class _ExpiryPageState extends State<ExpiryPage> {
  final supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text("Expiry Item Alerts (3 Months)", style: GoogleFonts.openSans(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orangeAccent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase.from('products').stream(primaryKey: ['id']),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.orangeAccent));
          
          final allItems = snapshot.data ?? [];
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final threeMonthsFromNow = today.add(const Duration(days: 90));

          final items = allItems.where((item) {
            if (item['expiry_date'] == null) return false;
            try {
              DateTime expiry = DateTime.parse(item['expiry_date']);
              DateTime expDate = DateTime(expiry.year, expiry.month, expiry.day);
              return expDate.isBefore(threeMonthsFromNow) && (expDate.isAfter(today) || expDate.isAtSameMomentAs(today));
            } catch (e) {
              return false;
            }
          }).toList();

          return Column(
            children: [
              // 📊 TOTAL NUMBER DISPLAY
              Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      "Total items expiring soon: ${items.length}",
                      style: GoogleFonts.openSans(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              Expanded(
                child: items.isEmpty
                    ? Center(child: Text("No items near expiry.", style: GoogleFonts.openSans(color: Colors.grey)))
                    : ListView.builder(
                        itemCount: items.length,
                        padding: const EdgeInsets.all(15),
                        itemBuilder: (context, index) {
                          final product = items[index];
                          return Card(
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.orange[100]!)),
                            child: ListTile(
                              leading: const CircleAvatar(backgroundColor: Colors.orangeAccent, child: Icon(Icons.warning, color: Colors.white)),
                              title: Text(product['name'], style: GoogleFonts.openSans(fontWeight: FontWeight.bold)),
                              subtitle: Text("Expiry Date: ${product['expiry_date']}", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
