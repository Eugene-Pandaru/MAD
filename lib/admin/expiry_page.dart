import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
      appBar: AppBar(
        title: const Text("Expiry Item Alerts (Near 3 Months)"),
        backgroundColor: Colors.orangeAccent,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase.from('products').stream(primaryKey: ['id']),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          
          final allItems = snapshot.data ?? [];
          final now = DateTime.now();
          final threeMonthsFromNow = now.add(const Duration(days: 90));

          final items = allItems.where((item) {
            if (item['expiry_date'] == null) return false;
            DateTime expiry = DateTime.parse(item['expiry_date']);
            return expiry.isBefore(threeMonthsFromNow) && expiry.isAfter(now);
          }).toList();

          if (items.isEmpty) {
            return const Center(child: Text("No items near expiry."));
          }

          return ListView.builder(
            itemCount: items.length,
            padding: const EdgeInsets.all(10),
            itemBuilder: (context, index) {
              final product = items[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.warning, color: Colors.orange),
                  title: Text(product['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Expiry Date: ${product['expiry_date']}", style: const TextStyle(color: Colors.red)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
