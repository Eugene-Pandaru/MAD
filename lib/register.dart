import 'package:flutter/material.dart';
import 'package:mad/utility.dart';
import 'package:mad/footer.dart';

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sign Up"), centerTitle: true),

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

                    const SizedBox(height: 20),

                    /// Nickname
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

                    const SizedBox(height: 15),

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

                    /// Password
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
                        if (value.length < 6) {
                          return "Password must be at least 6 characters";
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 15),

                    /// Confirm Password
                    TextFormField(
                      controller: confirmPasswordController,
                      obscureText: obscureConfirmPassword,
                      decoration: inputDecoration("Confirm Password").copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureConfirmPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              obscureConfirmPassword = !obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please confirm password";
                        }
                        if (value != passwordController.text) {
                          return "Password does not match";
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 15),

                    /// ✅ Checkbox
                    Row(
                      children: [
                        Checkbox(
                          value: agree,
                          onChanged: (value) {
                            setState(() {
                              agree = value!;
                            });
                          },
                        ),
                        const Expanded(
                          child: Text("Agree to terms and conditions"),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    /// 🔘 Reset Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Utils.resetControllers([
                            nicknameController,
                            emailController,
                            passwordController,
                            confirmPasswordController,
                          ]);

                          setState(() {
                            agree = false;
                          });

                          Utils.snackbar(
                            context,
                            "Form reset",
                            color: Colors.black,
                          );
                        },
                        child: const Text("Reset"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ),

                    /// ⬆️ Space to prevent mis-click
                    const SizedBox(height: 20),

                    /// 🔘 Register Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate() && agree) {
                            Utils.snackbar(
                              context,
                              "Registration Successful",
                              color: Colors.green,
                            );

                            Utils.resetControllers([
                              nicknameController,
                              emailController,
                              passwordController,
                              confirmPasswordController,
                            ]);

                            setState(() {
                              agree = false;
                            });
                          } else if (!agree) {
                            Utils.snackbar(
                              context,
                              "Please agree to terms",
                              color: Colors.red,
                            );
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

          /// 🔻 Footer
          const Footer(),
        ],
      ),
    );
  }
}
