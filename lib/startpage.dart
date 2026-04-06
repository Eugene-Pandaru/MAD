import 'package:flutter/material.dart';
import 'package:mad/register.dart';
import 'package:mad/login.dart';
import 'package:mad/footer.dart';

class Startpage extends StatefulWidget {
  const Startpage({super.key});

  @override
  State<Startpage> createState() => _StartpageState();
}

class _StartpageState extends State<Startpage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("NoSakit Pharmacy"), centerTitle: true),

      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // push footer down
        children: [
          //  Center Content
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 🖼️ Logo
                  Image.asset('assets/logo.png', height: 120),

                  const SizedBox(height: 20),

                  const Text(
                    "WELCOME",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 40),

                  // 🔘 Sign Up Button
                  SizedBox(
                    width: 200,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterPage(),
                          ),
                        );
                      },
                      child: const Text("Sign Up"),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // 🔘 Login Button
                  SizedBox(
                    width: 200,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginPage(),
                          ),
                        );
                      },
                      child: const Text("Login"),
                    ),
                  ),
                ],
              ),
            ),
          ),

          //  Footer
          const Footer(),
        ],
      ),
    );
  }
}
