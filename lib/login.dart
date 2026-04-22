import 'package:flutter/material.dart';
import 'package:mad/footer.dart';
import 'package:mad/utility.dart';
import 'package:mad/forgotpass.dart';
import 'package:mad/home.dart';
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
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
      appBar: AppBar(title: const Text("Login"), centerTitle: true),

      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          /// 🔹 Main Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    /// 🖼️ Logo
                    Image.asset('assets/logo.png', height: 100),

                    const SizedBox(height: 30),

                    /// Email
                    TextFormField(
                      controller: emailController,
                      decoration: inputDecoration("Email"),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please enter email";
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 15),

                    /// Password with 👁 toggle
                    TextFormField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      decoration: inputDecoration("Password").copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              obscurePassword = !obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please enter password";
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 10),

                    /// 🔗 Forgot Password
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        children: [
                          const Text("Can't remember password? "),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ForgotPassPage(),
                                ),
                              );
                            },
                            child: const Text(
                              "Click here",
                              style: TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    /// 🔘 Login Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            try {
                              final supabase = Supabase.instance.client;

                              // Query the users_profile table for matching email and password
                              final data = await supabase
                                  .from('users_profile')
                                  .select()
                                  .eq('email', emailController.text)
                                  .eq('password', passwordController.text)
                                  .maybeSingle();

                              if (data != null) {
                                // ✅ Save user data globally
                                Utils.currentUser = data;

                                Utils.snackbar(context, "Login success",
                                    color: Colors.green);

                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const HomePage(),
                                  ),
                                );
                              } else {
                                // Generic error for security
                                Utils.snackbar(
                                    context, "Invalid email or password",
                                    color: Colors.red);
                              }
                            } catch (e) {
                              Utils.snackbar(
                                  context, "An error occurred during login",
                                  color: Colors.red);
                            }
                          }
                        },
                        child: const Text("Login"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          /// 🔻 Footer
          const Footer(),
        ],
      ),
    );
  }
}
