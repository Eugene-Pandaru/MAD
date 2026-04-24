import 'package:flutter/material.dart';
import 'package:mad/utility.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminProfilePage extends StatefulWidget {
  const AdminProfilePage({super.key});

  @override
  State<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  final supabase = Supabase.instance.client;
  late TextEditingController _nameController;
  late TextEditingController _userController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: Utils.currentUser?['full_name']);
    _userController = TextEditingController(text: Utils.currentUser?['username']);
  }

  Future<void> _updateProfile() async {
    try {
      final response = await supabase
          .from('admin')
          .update({
            'full_name': _nameController.text,
            'username': _userController.text,
          })
          .eq('id', Utils.currentUser?['id'])
          .select()
          .single();

      setState(() {
        Utils.currentUser = response;
        _isEditing = false;
      });
      Utils.snackbar(context, "Profile updated", color: Colors.green);
    } catch (e) {
      Utils.snackbar(context, "Update failed", color: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = Utils.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text("My Profile"), backgroundColor: Colors.blueAccent),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 60,
              backgroundColor: Colors.blueAccent,
              child: Icon(Icons.admin_panel_settings, size: 70, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Text("Admin ID: ${admin?['id']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 30),
            TextField(
              controller: _nameController,
              enabled: _isEditing,
              decoration: const InputDecoration(labelText: "Full Name", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _userController,
              enabled: _isEditing,
              decoration: const InputDecoration(labelText: "Username", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 15),
            ListTile(
              title: const Text("Role"),
              subtitle: Text(admin?['roles'] ?? "N/A"),
              leading: const Icon(Icons.security),
            ),
            const SizedBox(height: 30),
            if (!_isEditing)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => setState(() => _isEditing = true),
                  child: const Text("Edit Profile"),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _isEditing = false),
                      child: const Text("Cancel"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _updateProfile,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: const Text("Save Changes"),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
