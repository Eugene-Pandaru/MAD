import 'package:flutter/material.dart';
import 'package:mad/utility.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ManageAdminsPage extends StatefulWidget {
  const ManageAdminsPage({super.key});

  @override
  State<ManageAdminsPage> createState() => _ManageAdminsPageState();
}

class _ManageAdminsPageState extends State<ManageAdminsPage> {
  final supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Management"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase.from('admin').stream(primaryKey: ['id']),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final admins = snapshot.data ?? [];

          return ListView.builder(
            itemCount: admins.length,
            padding: const EdgeInsets.all(10),
            itemBuilder: (context, index) {
              final admin = admins[index];
              bool isSuper = admin['roles'] == 'Superadmin';

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isSuper ? Colors.amber : Colors.indigo,
                    child: const Icon(Icons.security, color: Colors.white),
                  ),
                  title: Text(admin['full_name']),
                  subtitle: Text("${admin['username']} - ${admin['roles']}"),
                  trailing: (admin['id'] == Utils.currentUser?['id']) 
                      ? const Text("(Me)", style: TextStyle(color: Colors.grey))
                      : IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteAdmin(admin['id']),
                        ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddAdminDialog(context),
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }

  void _deleteAdmin(String id) async {
    await supabase.from('admin').delete().eq('id', id);
    if (mounted) Utils.snackbar(context, "Admin removed");
  }

  void _showAddAdminDialog(BuildContext context) {
    final nameController = TextEditingController();
    final userController = TextEditingController();
    final passController = TextEditingController();
    String role = 'Admin';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Register New Admin"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: "Full Name")),
              TextField(controller: userController, decoration: const InputDecoration(labelText: "Username")),
              TextField(controller: passController, decoration: const InputDecoration(labelText: "Password"), obscureText: true),
              const SizedBox(height: 10),
              DropdownButton<String>(
                value: role,
                isExpanded: true,
                items: ['Admin', 'Superadmin'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                onChanged: (val) => setState(() => role = val!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                await supabase.from('admin').insert({
                  'full_name': nameController.text,
                  'username': userController.text,
                  'password': passController.text,
                  'roles': role,
                });
                Navigator.pop(context);
              },
              child: const Text("Register"),
            ),
          ],
        ),
      ),
    );
  }
}
