import 'package:flutter/material.dart';
import 'package:mad/footer.dart';
import 'package:mad/utility.dart';
import 'package:mad/startpage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';

class ForgotPassPage extends StatefulWidget {
  const ForgotPassPage({super.key});

  @override
  State<ForgotPassPage> createState() => _ForgotPassPageState();
}

class _ForgotPassPageState extends State<ForgotPassPage> {
  final _formKey = GlobalKey<FormState>();
  final supabase = Supabase.instance.client;

  final emailController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool obscureNew = true;
  bool obscureConfirm = true;
  bool isLoading = false;
  int getCodeAttempts = 0; // 🛑 Track OTP requests

  List<TextEditingController> otpControllers = List.generate(6, (_) => TextEditingController());
  List<FocusNode> otpFocusNodes = List.generate(6, (_) => FocusNode());

  InputDecoration inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  @override
  void dispose() {
    Utils.disposeControllers([emailController, newPasswordController, confirmPasswordController, ...otpControllers]);
    for (var node in otpFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  /// 🎲 Generate and Store OTP
  Future<void> _generateOTP() async {
    if (emailController.text.isEmpty) {
      Utils.snackbar(context, "Please enter your email first", color: Colors.red);
      return;
    }

    setState(() => isLoading = true);

    try {
      // 1. Check if email exists in database
      final userCheck = await supabase.from('users_profile').select().eq('email', emailController.text).maybeSingle();

      if (userCheck == null) {
        Utils.snackbar(context, "Email not found in our system", color: Colors.red);
        setState(() => isLoading = false);
        return;
      }

      // 2. Check Attempts
      getCodeAttempts++;
      if (getCodeAttempts > 3) {
        Utils.snackbar(context, "Too many attempts. Returning to start page.", color: Colors.red);
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const Startpage()), (route) => false);
        return;
      }

      // 3. Generate 6-digit code
      String code = (Random().nextInt(900000) + 100000).toString();

      // 4. Store in Supabase
      await supabase.from('otp_codes').insert({
        'email': emailController.text,
        'code': code,
      });

      Utils.snackbar(context, "OTP Code sent to your email: $code", color: Colors.blue);
    } catch (e) {
      Utils.snackbar(context, "Error: ${e.toString()}", color: Colors.red);
    } finally {
      setState(() => isLoading = false);
    }
  }

  /// 🔐 Reset Password Logic
  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    String enteredOtp = otpControllers.map((c) => c.text).join();
    if (enteredOtp.length < 6) {
      Utils.snackbar(context, "Enter full OTP", color: Colors.red);
      return;
    }

    setState(() => isLoading = true);

    try {
      // 1. Verify OTP in database
      final otpData = await supabase
          .from('otp_codes')
          .select()
          .eq('email', emailController.text)
          .eq('code', enteredOtp)
          .eq('used', false)
          .maybeSingle();

      if (otpData == null) {
        Utils.snackbar(context, "Invalid or expired OTP", color: Colors.red);
        setState(() => isLoading = false);
        return;
      }

      // 2. Update Password for SPECIFIC User
      await supabase.from('users_profile').update({
        'password': newPasswordController.text,
      }).eq('email', emailController.text);

      // 3. Mark OTP as used
      await supabase.from('otp_codes').update({'used': true}).eq('id', otpData['id']);

      Utils.snackbar(context, "Password reset successful", color: Colors.green);
      Navigator.pop(context);
    } catch (e) {
      Utils.snackbar(context, "Reset failed: ${e.toString()}", color: Colors.red);
    } finally {
      setState(() => isLoading = false);
    }
  }

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
            decoration: InputDecoration(counterText: "", border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
            onChanged: (value) {
              if (value.isNotEmpty && index < 5) {
                FocusScope.of(context).requestFocus(otpFocusNodes[index + 1]);
              } else if (value.isEmpty && index > 0) {
                FocusScope.of(context).requestFocus(otpFocusNodes[index - 1]);
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
      appBar: AppBar(title: const Text("Forgot Password"), centerTitle: true),
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
                    TextFormField(
                      controller: emailController,
                      decoration: inputDecoration("Email"),
                      validator: (value) {
                        if (value == null || value.isEmpty) return "Please enter email";
                        if (!RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$").hasMatch(value)) return "Invalid email format";
                        return null;
                      },
                    ),
                    const SizedBox(height: 25),
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(10)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("OTP Code", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                              TextButton(
                                onPressed: isLoading ? null : _generateOTP,
                                child: Text(isLoading ? "Sending..." : "Get Code"),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          buildOtpField(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: newPasswordController,
                      obscureText: obscureNew,
                      decoration: inputDecoration("New Password").copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(obscureNew ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => obscureNew = !obscureNew),
                        ),
                      ),
                      validator: (value) => (value == null || value.length < 6) ? "Min 6 characters required" : null,
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: confirmPasswordController,
                      obscureText: obscureConfirm,
                      decoration: inputDecoration("Confirm New Password").copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(obscureConfirm ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => obscureConfirm = !obscureConfirm),
                        ),
                      ),
                      validator: (value) => (value != newPasswordController.text) ? "Passwords do not match" : null,
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _resetPassword,
                        child: Text(isLoading ? "Processing..." : "Reset Password"),
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
