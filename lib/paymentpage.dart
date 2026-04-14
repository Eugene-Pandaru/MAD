import 'package:flutter/material.dart';
import 'package:mad/cartmanager.dart';
import 'package:mad/utility.dart';
import 'package:mad/footer.dart';
import 'package:mad/home.dart'; // To go back home after success
import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentPage extends StatefulWidget {
  final double amount;
  const PaymentPage({super.key, required this.amount});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String paymentMethod = "Card"; // Default
  String selectedBank = "Maybank2u";
  bool isProcessing = false;

  final List<String> banks = ["Maybank2u", "CIMB Clicks", "Public Bank", "RHB Now", "Bank Islam"];

  // Modify the function to accept the method as a parameter
  // Inside paymentpage.dart
  Future<void> _saveOrderToDatabase(String method) async {
    await Supabase.instance.client.from('orders').insert({
      'user_name': 'Jin Han',
      'total_amount': widget.amount,
      'status': 'Paid',              // Payment Status
      'payment_method': method,      // The method (Card/FPX)
      'delivery_status': 'PENDING',  // Initial Delivery Status
      'items': CartManager.cartItems.map((item) => {
        'name': item.name,
        'price': item.price,
        'quantity': item.quantity,
        'image_url': item.imageUrl,
      }).toList(),
    });
  }

// Update the call inside _processPayment
  void _processPayment() async {
    setState(() => isProcessing = true);

    // Pass the current state variable 'paymentMethod' (Card or FPX)
    await _saveOrderToDatabase(paymentMethod);

    await Future.delayed(const Duration(seconds: 1));
    setState(() => isProcessing = false);
    _showSuccessDialog();
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Payment Successful!",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text("Amount Paid: RM ${widget.amount.toStringAsFixed(2)}"),
            const SizedBox(height: 5),
            const Text("Your order is being processed.", textAlign: TextAlign.center),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                // IMPORTANT: Member 2 logic - Clear the cart after purchase
                setState(() {
                  CartManager.cartItems.clear();
                });
                // Navigate back to Home and clear the navigation stack
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const HomePage()),
                      (route) => false,
                );
              },
              child: const Text("Back to Home"),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Secure Payment"),
        backgroundColor: Colors.blueGrey.shade800,
        foregroundColor: Colors.white,
      ),
      body: isProcessing
          ? const Center(child: CircularProgressIndicator()) // Loading state
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Total Amount Header
            Center(
              child: Column(
                children: [
                  const Text("Total Amount to Pay", style: TextStyle(color: Colors.grey)),
                  Text("RM ${widget.amount.toStringAsFixed(2)}",
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green)),
                ],
              ),
            ),
            const SizedBox(height: 30),

            /// Payment Method Selector
            const Text("Select Payment Method", style: TextStyle(fontWeight: FontWeight.bold)),
            Row(
              children: [
                Expanded(
                  child: RadioListTile(
                    title: const Text("Card"),
                    value: "Card",
                    groupValue: paymentMethod,
                    onChanged: (val) => setState(() => paymentMethod = val!),
                  ),
                ),
                Expanded(
                  child: RadioListTile(
                    title: const Text("FPX"),
                    value: "FPX",
                    groupValue: paymentMethod,
                    onChanged: (val) => setState(() => paymentMethod = val!),
                  ),
                ),
              ],
            ),

            const Divider(),

            /// Dynamic View based on selection
            if (paymentMethod == "Card") ...[
              const TextField(
                decoration: InputDecoration(labelText: "Cardholder Name", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 15),
              const TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: "Card Number", border: OutlineInputBorder(), hintText: "XXXX XXXX XXXX XXXX"),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: const TextField(
                      decoration: InputDecoration(labelText: "Expiry (MM/YY)", border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: const TextField(
                      obscureText: true,
                      decoration: InputDecoration(labelText: "CVV", border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
            ] else ...[
              const Text("Select Bank"),
              DropdownButtonFormField(
                value: selectedBank,
                items: banks.map((bank) => DropdownMenuItem(value: bank, child: Text(bank))).toList(),
                onChanged: (val) => setState(() => selectedBank = val!),
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),
              const Text("You will be redirected to your bank's login page.", style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],

            const SizedBox(height: 40),

            /// Pay Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                onPressed: _processPayment,
                child: Text("Pay RM ${widget.amount.toStringAsFixed(2)} Now",
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),

            const SizedBox(height: 20),
            const Center(child: Text("🔒 Encrypted & Secure Payment")),
            const Footer(),
          ],
        ),
      ),
    );
  }
}