import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mad/utility.dart';
import 'package:mad/footer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  bool agree = false;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  final TextEditingController nicknameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  InputDecoration inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.openSans(color: Colors.grey),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFF1392AB), width: 2),
      ),
    );
  }

  @override
  void dispose() {
    Utils.disposeControllers([
      nicknameController,
      emailController,
      passwordController,
      confirmPasswordController
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 🟢 Header (Matching home/login style)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    "Create Account",
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
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      /// 🖼️ Logo
                      Image.asset('assets/logo.png', height: 100),
                      const SizedBox(height: 10),
                      Text(
                        "Join NoSakit Pharmacy today",
                        style: GoogleFonts.openSans(fontSize: 16, color: Colors.grey),
                      ),

                      const SizedBox(height: 40),

                      /// 👤 Nickname
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
                      const SizedBox(height: 15),

                      /// 📧 Email
                      TextFormField(
                        controller: emailController,
                        style: GoogleFonts.openSans(),
                        decoration: inputDecoration("Email"),
                        validator: (value) {
                          if (value == null || value.isEmpty) return "Please enter email";
                          if (!RegExp(r"^[a-zA-Z0-9._%+-]+@gmail\.com$").hasMatch(value)) {
                            return "Email must be a valid @gmail.com address";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),

                      /// 🔑 Password
                      TextFormField(
                        controller: passwordController,
                        obscureText: obscurePassword,
                        style: GoogleFonts.openSans(),
                        decoration: inputDecoration("Password").copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(obscurePassword ? Icons.visibility : Icons.visibility_off, color: const Color(0xFF1392AB)),
                            onPressed: () => setState(() => obscurePassword = !obscurePassword),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return "Please enter password";
                          if (value.length < 6) return "Password must be at least 6 characters";
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),

                      /// 🔑 Confirm Password
                      TextFormField(
                        controller: confirmPasswordController,
                        obscureText: obscureConfirmPassword,
                        style: GoogleFonts.openSans(),
                        decoration: inputDecoration("Confirm Password").copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(obscureConfirmPassword ? Icons.visibility : Icons.visibility_off, color: const Color(0xFF1392AB)),
                            onPressed: () => setState(() => obscureConfirmPassword = !obscureConfirmPassword),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return "Please confirm password";
                          if (value != passwordController.text) return "Passwords do not match";
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),

                      /// ✅ Agreement Checkbox
                      Row(
                        children: [
                          Checkbox(
                            value: agree,
                            activeColor: const Color(0xFF1392AB),
                            onChanged: (value) => setState(() => agree = value!),
                          ),
                          Expanded(
                            child: Text(
                              "Agree to terms and conditions",
                              style: GoogleFonts.openSans(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 30),

                      /// 🔘 Register Button
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (_formKey.currentState!.validate() && agree) {
                              try {
                                final supabase = Supabase.instance.client;
                                await supabase.from('users_profile').insert({
                                  'nickname': nicknameController.text,
                                  'email': emailController.text,
                                  'password': passwordController.text,
                                });
                                if (mounted) {
                                  Utils.snackbar(context, "Registration Successful", color: Colors.green);
                                  Navigator.pop(context);
                                }
                              } catch (e) {
                                if (mounted) Utils.snackbar(context, "Registration failed", color: Colors.red);
                              }
                            } else if (!agree) {
                              Utils.snackbar(context, "Please agree to terms", color: Colors.red);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1392AB),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            elevation: 0,
                          ),
                          child: Text(
                            "Register",
                            style: GoogleFonts.openSans(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      /// 🔘 Reset Button
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: OutlinedButton(
                          onPressed: () {
                            Utils.resetControllers([nicknameController, emailController, passwordController, confirmPasswordController]);
                            setState(() => agree = false);
                            Utils.snackbar(context, "Form reset");
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                          child: Text(
                            "Reset",
                            style: GoogleFonts.openSans(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
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
