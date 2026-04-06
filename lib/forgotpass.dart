import 'package:flutter/material.dart';
import 'package:mad/footer.dart';
import 'package:mad/utility.dart';

class ForgotPassPage extends StatefulWidget {
  const ForgotPassPage({super.key});

  @override
  State<ForgotPassPage> createState() => _ForgotPassPageState();
}

class _ForgotPassPageState extends State<ForgotPassPage> {
  final _formKey = GlobalKey<FormState>();

  final emailController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool obscureNew = true;
  bool obscureConfirm = true;

  /// OTP controllers
  List<TextEditingController> otpControllers =
  List.generate(6, (_) => TextEditingController());

  List<FocusNode> otpFocusNodes =
  List.generate(6, (_) => FocusNode());

  InputDecoration inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  @override
  void dispose() {
    Utils.disposeControllers([
      emailController,
      newPasswordController,
      confirmPasswordController,
      ...otpControllers,
    ]);

    for (var node in otpFocusNodes) {
      node.dispose();
    }

    super.dispose();
  }

  /// 🔢 OTP UI
  Widget buildOtpField() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (index) {
        return SizedBox(
          width: 45,
          child: TextField(
            controller: otpControllers[index],
            focusNode: otpFocusNodes[index],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 1,
            decoration: InputDecoration(
              counterText: "",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onChanged: (value) {
              if (value.isNotEmpty && index < 5) {
                FocusScope.of(context)
                    .requestFocus(otpFocusNodes[index + 1]);
              } else if (value.isEmpty && index > 0) {
                FocusScope.of(context)
                    .requestFocus(otpFocusNodes[index - 1]);
              }
            },
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Forgot Password"),
        centerTitle: true,
      ),

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

                    /// 📧 Email
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

                    const SizedBox(height: 25),

                    /// 🔢 OTP Boxes
                    /// 🔢 OTP Section (Box + Button)
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          /// 🔹 Top Row (Label + Button)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "OTP Code",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),

                              TextButton(
                                onPressed: () {
                                  Utils.snackbar(context, "OTP sent: 123456",
                                      color: Colors.blue);
                                },
                                child: const Text("Get Code"),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          /// 🔹 OTP Boxes
                          buildOtpField(),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// 🔐 New Password
                    TextFormField(
                      controller: newPasswordController,
                      obscureText: obscureNew,
                      decoration: inputDecoration("New Password").copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(obscureNew
                              ? Icons.visibility
                              : Icons.visibility_off),
                          onPressed: () {
                            setState(() {
                              obscureNew = !obscureNew;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Enter new password";
                        }
                        if (value.length < 6) {
                          return "Password must be at least 6 characters";
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 15),

                    /// 🔐 Confirm Password
                    TextFormField(
                      controller: confirmPasswordController,
                      obscureText: obscureConfirm,
                      decoration:
                      inputDecoration("Confirm New Password").copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(obscureConfirm
                              ? Icons.visibility
                              : Icons.visibility_off),
                          onPressed: () {
                            setState(() {
                              obscureConfirm = !obscureConfirm;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Confirm your password";
                        }
                        if (value != newPasswordController.text) {
                          return "Password does not match";
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 30),

                    /// 🔘 Reset Password Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          String enteredOtp =
                          otpControllers.map((c) => c.text).join();

                          if (_formKey.currentState!.validate()) {

                            if (enteredOtp.length < 6) {
                              Utils.snackbar(context, "Enter full OTP",
                                  color: Colors.red);
                              return;
                            }

                            if (enteredOtp != "123456") {
                              Utils.snackbar(context, "Invalid OTP",
                                  color: Colors.red);
                              return;
                            }

                            Utils.snackbar(
                                context, "Password reset successful",
                                color: Colors.green);

                            Navigator.pop(context);
                          }
                        },
                        child: const Text("Reset Password"),
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