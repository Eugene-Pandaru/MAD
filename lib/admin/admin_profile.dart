import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mad/utility.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mad/admin/admindashboard.dart';

class AdminProfilePage extends StatefulWidget {
  final VoidCallback? onUpdate;
  const AdminProfilePage({super.key, this.onUpdate});

  @override
  State<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final supabase = Supabase.instance.client;

  late TextEditingController _nameController;
  late TextEditingController _userController;
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isEditing = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSaving = false;
  int _failedAttempts = 0;

  File? _pickedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: Utils.currentUser?['full_name']);
    _userController = TextEditingController(text: Utils.currentUser?['username']);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _userController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (_currentPasswordController.text != Utils.currentUser?['password']) {
      _failedAttempts++;
      
      if (_failedAttempts >= 3) {
        Utils.snackbar(context, "Too many failed attempts. Returning to dashboard.", color: Colors.orange);
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const AdminDashboard()),
            (route) => false,
          );
        }
        return;
      }

      Utils.snackbar(context, "Incorrect current password ($_failedAttempts/3)", color: Colors.red);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final String role = Utils.currentUser?['roles'] ?? "Admin";
      final bool isSuperAdmin = role == 'Superadmin';
      final String adminId = Utils.currentUser?['id'];

      final Map<String, dynamic> updateData = {};
      
      if (_nameController.text != Utils.currentUser?['full_name']) {
        updateData['full_name'] = _nameController.text;
      }
      
      if (_userController.text != Utils.currentUser?['username']) {
        updateData['username'] = _userController.text;
      }

      if (_pickedImage != null) {
        final fileName = 'admin_${adminId}_${DateTime.now().millisecondsSinceEpoch}.png';
        final publicUrl = await Utils.uploadImage(
          file: _pickedImage!, 
          bucket: 'adminprofile', 
          fileName: fileName
        );
        if (publicUrl != null) {
          updateData['profile_url'] = publicUrl;
        }
      }

      if (!isSuperAdmin && _newPasswordController.text.isNotEmpty) {
        updateData['password'] = _newPasswordController.text;
      }

      if (updateData.isEmpty) {
        setState(() {
          _isEditing = false;
          _currentPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();
        });
        Utils.snackbar(context, "No changes detected", color: Colors.blue);
        return;
      }

      final List<Map<String, dynamic>> results = await supabase
          .from('admin')
          .update(updateData)
          .eq('id', adminId)
          .select();

      if (results.isEmpty) {
        throw "Update failed: Record not found";
      }

      setState(() {
        Utils.currentUser = results.first;
        _isEditing = false;
        _failedAttempts = 0;
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        _pickedImage = null;
      });
      
      if (widget.onUpdate != null) widget.onUpdate!();
      
      Utils.snackbar(context, "Profile updated successfully", color: Colors.green);
    } catch (e) {
      Utils.snackbar(context, "Update failed: $e", color: Colors.red);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  InputDecoration _inputDeco(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
    );
  }

  @override
  Widget build(BuildContext context) {
    final admin = Utils.currentUser;
    final String role = admin?['roles'] ?? "Admin";
    final bool isSuperAdmin = role == 'Superadmin';
    final String? profileUrl = admin?['profile_url'];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text("My Profile", style: GoogleFonts.openSans(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.blueAccent,
                    backgroundImage: _pickedImage != null
                        ? FileImage(_pickedImage!)
                        : (profileUrl != null && profileUrl.startsWith('http')
                            ? NetworkImage(profileUrl)
                            : null) as ImageProvider?,
                    child: _pickedImage == null && (profileUrl == null || profileUrl.isEmpty)
                        ? const Icon(Icons.admin_panel_settings, size: 60, color: Colors.white)
                        : null,
                  ),
                  if (_isEditing)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () async {
                          final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
                          if (pickedFile != null) {
                            setState(() {
                              _pickedImage = File(pickedFile.path);
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)]),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 15),
              Text("Admin ID: ${admin?['id']}", style: GoogleFonts.openSans(color: Colors.grey, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Text(role, style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              const SizedBox(height: 30),

              TextFormField(
                controller: _nameController,
                enabled: _isEditing,
                decoration: _inputDeco("Full Name"),
                validator: (val) => (val == null || val.isEmpty) ? "Name cannot be empty" : null,
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _userController,
                enabled: _isEditing,
                decoration: _inputDeco("Username"),
                validator: (val) => (val == null || val.isEmpty) ? "Username cannot be empty" : null,
              ),
              
              if (_isEditing) ...[
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 10),
                
                TextFormField(
                  controller: _currentPasswordController,
                  obscureText: _obscureCurrent,
                  decoration: _inputDeco("Current Password (Required to Save)").copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(_obscureCurrent ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                    ),
                  ),
                  validator: (val) => (val == null || val.isEmpty) ? "Required" : null,
                ),

                if (!isSuperAdmin) ...[
                  const SizedBox(height: 20),
                  Text("Change Password (Optional)", style: GoogleFonts.openSans(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 10),
                  
                  TextFormField(
                    controller: _newPasswordController,
                    obscureText: _obscureNew,
                    decoration: _inputDeco("New Password").copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(_obscureNew ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _obscureNew = !_obscureNew),
                      ),
                    ),
                    validator: (val) {
                      if (val != null && val.isNotEmpty && val.length < 6) return "Min 6 characters";
                      if (val != null && val.isNotEmpty && val == _currentPasswordController.text) return "Cannot be same as old";
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),
                  
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirm,
                    decoration: _inputDeco("Confirm New Password").copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirm ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),
                    validator: (val) {
                      if (_newPasswordController.text.isNotEmpty && val != _newPasswordController.text) return "Mismatch";
                      return null;
                    },
                  ),
                ],
              ],

              const SizedBox(height: 40),

              if (!_isEditing)
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () => setState(() => _isEditing = true),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                    child: const Text("Edit Profile", style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSaving ? null : () => setState(() {
                          _isEditing = false;
                          _currentPasswordController.clear();
                          _newPasswordController.clear();
                          _confirmPasswordController.clear();
                          _pickedImage = null;
                        }),
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                        child: const Text("Cancel"),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _updateProfile,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                        child: _isSaving 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text("Save Changes", style: TextStyle(color: Colors.white, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
