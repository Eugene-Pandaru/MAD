import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mad/footer.dart';
import 'package:mad/utility.dart';
import 'package:mad/forgotpass.dart';
import 'package:mad/home.dart';
import 'package:mad/admin/adminlogin.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool obscurePassword = true;

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
    Utils.disposeControllers([emailController, passwordController]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 🟢 Header (Matching home style)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    "Welcome Back",
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
                        "Login to your account",
                        style: GoogleFonts.openSans(fontSize: 16, color: Colors.grey),
                      ),

                      const SizedBox(height: 40),

                      /// Email
                      TextFormField(
                        controller: emailController,
                        style: GoogleFonts.openSans(),
                        decoration: inputDecoration("Email"),
                        validator: (value) {
                          if (value == null || value.isEmpty) return "Please enter email";
                          return null;
                        },
                      ),

                      const SizedBox(height: 15),

                      /// Password
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
                          return null;
                        },
                      ),

                      const SizedBox(height: 15),

                      /// 🔗 Forgot Password
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ForgotPassPage()),
                            );
                          },
                          child: Text(
                            "Forgot Password?",
                            style: GoogleFonts.openSans(
                              color: const Color(0xFF1392AB),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      /// 🔘 Login Button
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              // ADMIN REDIRECT
                              if (emailController.text == "admin" && passwordController.text == "admin") {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminLoginPage()));
                                return;
                              }

                              try {
                                final supabase = Supabase.instance.client;
                                final data = await supabase.from('users_profile').select().eq('email', emailController.text).eq('password', passwordController.text).maybeSingle();

                                if (data != null) {
                                  Utils.currentUser = data;
                                  // 🔵 Changed to signature blue color
                                  Utils.snackbar(context, "Login Successful", color: const Color(0xFF1392AB));
                                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomePage()));
                                } else {
                                  Utils.snackbar(context, "Invalid credentials", color: Colors.red);
                                }
                              } catch (e) {
                                Utils.snackbar(context, "An error occurred", color: Colors.red);
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1392AB),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            elevation: 0,
                          ),
                          child: Text(
                            "Login",
                            style: GoogleFonts.openSans(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
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
      ),
    );
  }
}
