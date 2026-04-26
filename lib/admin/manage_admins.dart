import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mad/utility.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class ManageAdminsPage extends StatefulWidget {
  const ManageAdminsPage({super.key});

  @override
  State<ManageAdminsPage> createState() => _ManageAdminsPageState();
}

class _ManageAdminsPageState extends State<ManageAdminsPage> {
  final supabase = Supabase.instance.client;

  // Sorting Helper
  int _rolePriority(String role) {
    switch (role) {
      case 'Superadmin': return 0;
      case 'Admin': return 1;
      case 'Pharmacist': return 2;
      default: return 3;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text("Admin Management", style: GoogleFonts.openSans(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase.from('admin').stream(primaryKey: ['id']),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.indigo));
          
          List<Map<String, dynamic>> admins = snapshot.data ?? [];

          // 🛠️ Sorting: Superadmin -> Admin -> Pharmacist
          admins.sort((a, b) {
            int pA = _rolePriority(a['roles'] ?? "");
            int pB = _rolePriority(b['roles'] ?? "");
            if (pA != pB) return pA.compareTo(pB);
            return (a['full_name'] as String).compareTo(b['full_name'] as String);
          });

          return Column(
            children: [
              Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                child: Row(
                  children: [
                    const Icon(Icons.admin_panel_settings_outlined, color: Colors.indigo, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      "Total Staff: ${admins.length}",
                      style: GoogleFonts.openSans(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              Expanded(
                child: ListView.builder(
                  itemCount: admins.length,
                  padding: const EdgeInsets.all(15),
                  itemBuilder: (context, index) {
                    final admin = admins[index];
                    String role = admin['roles'] ?? "Admin";
                    bool isMe = admin['id'] == Utils.currentUser?['id'];

                    Color roleColor;
                    if (role == 'Superadmin') roleColor = Colors.amber;
                    else if (role == 'Admin') roleColor = Colors.indigo;
                    else roleColor = Colors.teal;

                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.grey[200]!)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: roleColor.withOpacity(0.1),
                          child: Icon(
                            role == 'Pharmacist' ? Icons.medication : Icons.security, 
                            color: roleColor
                          ),
                        ),
                        title: Text(admin['full_name'], style: GoogleFonts.openSans(fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: Text("${admin['username']} • $role", style: GoogleFonts.openSans(fontSize: 14)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                              onPressed: () => _showAdminDialog(context, admin: admin),
                            ),
                            if (!isMe && role != 'Superadmin')
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => _confirmDeleteAdmin(admin['id']),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAdminDialog(context),
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }

  void _confirmDeleteAdmin(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Remove Staff?", style: GoogleFonts.openSans(fontWeight: FontWeight.bold)),
        content: Text("Are you sure? This will remove the access for this user.", style: GoogleFonts.openSans()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel", style: GoogleFonts.openSans())),
          ElevatedButton(
            onPressed: () async {
              try {
                await supabase.from('admin').delete().eq('id', id);
                if (mounted) {
                  Navigator.pop(context);
                  Utils.snackbar(context, "Staff removed", color: Colors.red);
                }
              } catch (e) {
                if (mounted) Utils.snackbar(context, "Error: $e", color: Colors.red);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text("Delete", style: GoogleFonts.openSans(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAdminDialog(BuildContext context, {Map<String, dynamic>? admin}) {
    final bool isEdit = admin != null;
    final _formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: isEdit ? admin['full_name'] : "");
    final userController = TextEditingController(text: isEdit ? admin['username'] : "");
    final passController = TextEditingController(text: isEdit ? admin['password'] : "");
    String role = isEdit ? admin['roles'] : 'Admin';
    bool obscurePass = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(isEdit ? "Edit Staff" : "Register New Staff", style: GoogleFonts.openSans(fontWeight: FontWeight.bold)),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController, 
                    decoration: const InputDecoration(labelText: "Full Name", border: OutlineInputBorder()),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]'))],
                    validator: (val) => (val == null || val.trim().isEmpty) ? "Enter valid name (no numbers/symbols)" : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: userController, 
                    decoration: const InputDecoration(labelText: "Username", border: OutlineInputBorder()),
                    validator: (val) => (val == null || val.isEmpty) ? "Enter username" : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: passController, 
                    decoration: InputDecoration(
                      labelText: "Password", 
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(obscurePass ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => obscurePass = !obscurePass),
                      ),
                    ), 
                    obscureText: obscurePass,
                    validator: (val) => (val == null || val.length < 6) ? "Password must be at least 6 characters" : null,
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    value: role,
                    decoration: const InputDecoration(labelText: "Role", border: OutlineInputBorder()),
                    items: ['Admin', 'Superadmin', 'Pharmacist'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                    onChanged: (val) => setState(() => role = val!),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel", style: GoogleFonts.openSans())),
            ElevatedButton(
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;

                final data = {
                  'full_name': nameController.text.trim(),
                  'username': userController.text.trim(),
                  'password': passController.text,
                  'roles': role,
                };

                try {
                  if (isEdit) {
                    await supabase.from('admin').update(data).eq('id', admin['id']);
                    Utils.snackbar(context, "Updated successfully", color: Colors.green);
                  } else {
                    await supabase.from('admin').insert(data);
                    Utils.snackbar(context, "Registered successfully", color: Colors.green);
                  }
                  Navigator.pop(context);
                } catch (e) {
                  Utils.snackbar(context, "Error: $e", color: Colors.red);
                }
              },
              child: Text("Save", style: GoogleFonts.openSans()),
            ),
          ],
        ),
      ),
    );
  }
}
