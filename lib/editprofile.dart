import 'package:flutter/material.dart';
import 'package:mad/footer.dart';
import 'package:mad/utility.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  @override
  void initState() {
    super.initState();
    // Initialize with current user data from Utils
    nicknameController = TextEditingController(text: Utils.currentUser?['nickname'] ?? "");
    emailController = TextEditingController(text: Utils.currentUser?['email'] ?? "");
  }

  InputDecoration inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
      decoration: inputDecoration(label).copyWith(
        suffixIcon: IconButton(
          icon: Icon(obscureText ? Icons.visibility : Icons.visibility_off),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// 📧 Email (Read Only)
                    TextFormField(
                      controller: emailController,
                      enabled: false,
                      decoration: inputDecoration("Email (Cannot be changed)").copyWith(
                        filled: true,
                        fillColor: Colors.grey.shade100,
                      ),
                    ),
                    const SizedBox(height: 15),

                    /// 👤 Nickname
                    TextFormField(
                      controller: nicknameController,
                      decoration: inputDecoration("Nickname"),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please enter nickname";
                        }
                        if (value.length < 3) {
                          return "Nickname must be at least 3 characters";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 25),

                    const Text(
                      "Change Password",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Divider(),
                    const SizedBox(height: 10),

                    /// 🔑 Current Password
                    buildPasswordField(
                      controller: currentPasswordController,
                      label: "Current Password",
                      obscureText: obscureCurrent,
                      onToggle: () => setState(() => obscureCurrent = !obscureCurrent),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please enter current password";
                        }
                        // Verify if it matches the current password in our local session
                        if (value != Utils.currentUser?['password']) {
                          return "Incorrect current password";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),

                    /// 🔑 New Password
                    buildPasswordField(
                      controller: newPasswordController,
                      label: "New Password",
                      obscureText: obscureNew,
                      onToggle: () => setState(() => obscureNew = !obscureNew),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (value == currentPasswordController.text) {
                            return "New Password cannot same as current Password";
                          }
                          if (value.length < 6) {
                            return "New password must be at least 6 characters";
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),

                    /// 🔑 Confirm New Password
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

                    const SizedBox(height: 30),

                    /// 🔘 Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            try {
                              // Ensure we have a user ID
                              final userId = Utils.currentUser?['id'];
                              if (userId == null) {
                                Utils.snackbar(context, "Session expired. Please login again.", color: Colors.red);
                                return;
                              }

                              // Data to update
                              final Map<String, dynamic> updateData = {
                                'nickname': nicknameController.text,
                              };

                              // If user filled in a new password, update it too
                              if (newPasswordController.text.isNotEmpty) {
                                updateData['password'] = newPasswordController.text;
                              }

                              // Update in Supabase
                              final response = await supabase
                                  .from('users_profile')
                                  .update(updateData)
                                  .eq('id', userId)
                                  .select()
                                  .single();

                              // Update local global variable
                              Utils.currentUser = response;

                              Utils.snackbar(context, "Profile updated successfully", color: Colors.green);
                              Navigator.pop(context);
                            } catch (e) {
                              Utils.snackbar(context, "Update failed: ${e.toString()}", color: Colors.red);
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        child: const Text("Submit", style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Footer(),
        ],
      ),
    );
  }
}
