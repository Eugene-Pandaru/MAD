import 'package:flutter/material.dart';
import 'package:mad/utility.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ManageCustomersPage extends StatefulWidget {
  const ManageCustomersPage({super.key});

  @override
  State<ManageCustomersPage> createState() => _ManageCustomersPageState();
}

class _ManageCustomersPageState extends State<ManageCustomersPage> {
  final supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Customer Management"),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase.from('users_profile').stream(primaryKey: ['id']),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final customers = snapshot.data ?? [];

          return ListView.builder(
            itemCount: customers.length,
            padding: const EdgeInsets.all(10),
            itemBuilder: (context, index) {
              final customer = customers[index];
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(customer['nickname'] ?? 'User'),
                  subtitle: Text(customer['email']),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteCustomer(customer['id']),
                  ),
                  onTap: () => _showCustomerDetails(customer),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _deleteCustomer(String id) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Customer?"),
        content: const Text("This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await supabase.from('users_profile').delete().eq('id', id);
      if (mounted) Utils.snackbar(context, "Customer deleted");
    }
  }

  void _showCustomerDetails(Map<String, dynamic> customer) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Customer Details", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Divider(),
            Text("ID: ${customer['id']}"),
            Text("Name: ${customer['nickname']}"),
            Text("Email: ${customer['email']}"),
            Text("Address: ${customer['address'] ?? 'Not set'}"),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
