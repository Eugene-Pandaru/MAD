import 'package:flutter/material.dart';
import 'package:mad/footer.dart';
import 'package:mad/utility.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nicknameController = TextEditingController(text: "John Doe");
  final TextEditingController emailController = TextEditingController(text: "johndoe@example.com");
  final TextEditingController currentPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool obscureCurrent = true;
  bool obscureNew = true;
  bool obscureConfirm = true;

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
                    ),
                    const SizedBox(height: 15),

                    /// 🔑 New Password
                    buildPasswordField(
                      controller: newPasswordController,
                      label: "New Password",
                      obscureText: obscureNew,
                      onToggle: () => setState(() => obscureNew = !obscureNew),
                      validator: (value) {
                        if (value != null && value.isNotEmpty && value.length < 6) {
                          return "Password must be at least 6 characters";
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
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            // Logic to update profile would go here
                            Utils.snackbar(context, "Profile updated successfully", color: Colors.green);
                            Navigator.pop(context);
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
