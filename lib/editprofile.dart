import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mad/footer.dart';
import 'package:mad/utility.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:mad/startpage.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final supabase = Supabase.instance.client;

  late TextEditingController nicknameController;
  late TextEditingController emailController;
  final TextEditingController currentPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool obscureCurrent = true;
  bool obscureNew = true;
  bool obscureConfirm = true;
  bool isSaving = false;
  File? _pickedImage;
  final picker = ImagePicker();
  int _failedAttempts = 0;

  @override
  void initState() {
    super.initState();
    nicknameController = TextEditingController(text: Utils.currentUser?['nickname'] ?? "");
    emailController = TextEditingController(text: Utils.currentUser?['email'] ?? "");
  }

  InputDecoration inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.openSans(color: Colors.grey),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFF1392AB)),
      ),
    );
  }

  Widget buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      style: GoogleFonts.openSans(),
      decoration: inputDecoration(label).copyWith(
        suffixIcon: IconButton(
          icon: Icon(obscureText ? Icons.visibility : Icons.visibility_off, color: const Color(0xFF1392AB)),
          onPressed: onToggle,
        ),
      ),
      validator: validator,
    );
  }

  @override
  void dispose() {
    Utils.disposeControllers([
      nicknameController,
      emailController,
      currentPasswordController,
      newPasswordController,
      confirmPasswordController,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = Utils.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    "Edit Profile",
                    style: GoogleFonts.openSans(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Center(
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.grey.shade100,
                              backgroundImage: _pickedImage != null 
                                ? FileImage(_pickedImage!) 
                                : (user?['profile_url'] != null && user!['profile_url'].startsWith('http') 
                                    ? NetworkImage(user['profile_url']) 
                                    : null) as ImageProvider?,
                              child: _pickedImage == null && (user?['profile_url'] == null || !user!['profile_url'].startsWith('http'))
                                  ? const Icon(Icons.person, size: 50, color: Color(0xFF1392AB))
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () async {
                                  final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                                  if (pickedFile != null) {
                                    setState(() {
                                      _pickedImage = File(pickedFile.path);
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: const BoxDecoration(color: Color(0xFF1392AB), shape: BoxShape.circle),
                                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),

                      TextFormField(
                        controller: emailController,
                        enabled: false,
                        style: GoogleFonts.openSans(color: Colors.grey),
                        decoration: inputDecoration("Email (Read Only)").copyWith(
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                      ),
                      const SizedBox(height: 20),

                      TextFormField(
                        controller: nicknameController,
                        style: GoogleFonts.openSans(),
                        decoration: inputDecoration("Nickname"),
                        validator: (value) {
                          if (value == null || value.isEmpty) return "Please enter nickname";
                          if (value.length < 3) return "Nickname must be at least 3 characters";
                          return null;
                        },
                      ),
                      const SizedBox(height: 30),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Change Password",
                          style: GoogleFonts.openSans(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Divider(height: 30),

                      buildPasswordField(
                        controller: currentPasswordController,
                        label: "Current Password (Required)",
                        obscureText: obscureCurrent,
                        onToggle: () => setState(() => obscureCurrent = !obscureCurrent),
                        validator: (value) {
                          if (value == null || value.isEmpty) return "Required to save changes";
                          if (value != user?['password']) return "Incorrect current password";
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),

                      buildPasswordField(
                        controller: newPasswordController,
                        label: "New Password (Optional)",
                        obscureText: obscureNew,
                        onToggle: () => setState(() => obscureNew = !obscureNew),
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            if (value.length < 6) return "Min 6 characters required";
                            if (value == currentPasswordController.text) return "New Password cannot same as current Password";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),

                      buildPasswordField(
                        controller: confirmPasswordController,
                        label: "Confirm New Password",
                        obscureText: obscureConfirm,
                        onToggle: () => setState(() => obscureConfirm = !obscureConfirm),
                        validator: (value) {
                          if (newPasswordController.text.isNotEmpty && value != newPasswordController.text) {
                            return "Passwords do not match";
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 40),

                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: isSaving ? null : () async {
                            if (_formKey.currentState!.validate()) {
                              setState(() => isSaving = true);
                              try {
                                final userId = user?['id'];
                                final Map<String, dynamic> updateData = {
                                  'nickname': nicknameController.text,
                                };
                                
                                if (_pickedImage != null) {
                                  final fileName = 'user_${userId}_${DateTime.now().millisecondsSinceEpoch}.png';
                                  final publicUrl = await Utils.uploadImage(
                                    file: _pickedImage!, 
                                    bucket: 'userprofile', 
                                    fileName: fileName
                                  );
                                  if (publicUrl != null) {
                                    updateData['profile_url'] = publicUrl;
                                  }
                                }

                                if (newPasswordController.text.isNotEmpty) {
                                  updateData['password'] = newPasswordController.text;
                                }

                                final response = await supabase.from('users_profile').update(updateData).eq('id', userId).select();
                                if (response.isNotEmpty) {
                                  Utils.currentUser = response.first;
                                }
                                
                                if (mounted) {
                                  Utils.snackbar(context, "Profile updated successfully", color: Colors.green);
                                  Navigator.pop(context);
                                }
                              } catch (e) {
                                if (mounted) Utils.snackbar(context, "Update failed: ${e.toString()}", color: Colors.red);
                              } finally {
                                if (mounted) setState(() => isSaving = false);
                              }
                            } else {
                              if (currentPasswordController.text != user?['password']) {
                                _failedAttempts++;
                                if (_failedAttempts >= 3) {
                                  Utils.snackbar(context, "Too many failed attempts. Logging out...", color: Colors.red);
                                  Utils.currentUser = null;
                                  Navigator.pushAndRemoveUntil(
                                    context, 
                                    MaterialPageRoute(builder: (context) => const Startpage()), 
                                    (route) => false
                                  );
                                } else {
                                  Utils.snackbar(context, "Incorrect password ($_failedAttempts/3)", color: Colors.red);
                                }
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1392AB),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                          child: isSaving 
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text("Save Changes", style: GoogleFonts.openSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
            const Footer(),
          ],
        ),
      ),
    );
  }
}
