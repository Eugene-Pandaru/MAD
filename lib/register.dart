import 'package:flutter/material.dart';
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
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
      appBar: AppBar(title: const Text("Sign Up"), centerTitle: true),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Image.asset('assets/logo.png', height: 100),
                    const SizedBox(height: 20),

                    /// 👤 Nickname (At least 3 characters)
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
                    const SizedBox(height: 15),

                    /// 📧 Email (@gmail.com format)
                    TextFormField(
                      controller: emailController,
                      decoration: inputDecoration("Email"),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please enter email";
                        }
                        // Regex for @gmail.com validation
                        if (!RegExp(r"^[a-zA-Z0-9._%+-]+@gmail\.com$").hasMatch(value)) {
                          return "Email must be a valid @gmail.com address";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),

                    /// 🔑 Password (At least 6 characters)
                    TextFormField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      decoration: inputDecoration("Password").copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () => setState(() => obscurePassword = !obscurePassword),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please enter password";
                        }
                        if (value.length < 6) {
                          return "Password must be at least 6 characters";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),

                    /// 🔑 Confirm Password (Must match)
                    TextFormField(
                      controller: confirmPasswordController,
                      obscureText: obscureConfirmPassword,
                      decoration: inputDecoration("Confirm Password").copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () => setState(() => obscureConfirmPassword = !obscureConfirmPassword),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please confirm password";
                        }
                        if (value != passwordController.text) {
                          return "Passwords do not match";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),

                    /// ✅ Agreement Checkbox
                    Row(
                      children: [
                        Checkbox(
                          value: agree,
                          onChanged: (value) => setState(() => agree = value!),
                        ),
                        const Expanded(child: Text("Agree to terms and conditions")),
                      ],
                    ),
                    const SizedBox(height: 20),

                    /// 🔘 Reset Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Utils.resetControllers([nicknameController, emailController, passwordController, confirmPasswordController]);
                          setState(() => agree = false);
                          Utils.snackbar(context, "Form reset");
                        },
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text("Reset"),
                      ),
                    ),
                    const SizedBox(height: 20),

                    /// 🔘 Register Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate() && agree) {
                            try {
                              final supabase = Supabase.instance.client;
                              
                              // Insert into Supabase
                              await supabase.from('users_profile').insert({
                                'nickname': nicknameController.text,
                                'email': emailController.text,
                                'password': passwordController.text, // Note: In production, use Supabase Auth for security!
                              });

                              Utils.snackbar(context, "Registration Successful", color: Colors.green);
                              
                              // Clear and navigate back
                              Navigator.pop(context);
                            } catch (e) {
                              Utils.snackbar(context, "Registration failed: ${e.toString()}", color: Colors.red);
                            }
                          } else if (!agree) {
                            Utils.snackbar(context, "Please agree to terms", color: Colors.red);
                          }
                        },
                        child: const Text("Register"),
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
