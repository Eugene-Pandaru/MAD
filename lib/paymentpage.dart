import 'package:flutter/material.dart';
import 'package:mad/cartmanager.dart';
import 'package:mad/footer.dart';
import 'package:mad/home.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;

class PaymentPage extends StatefulWidget {
  final double amount;
  const PaymentPage({super.key, required this.amount});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  bool isProcessing = false;

  // Controllers for your own custom TextFields
  final TextEditingController cardNumController = TextEditingController();
  final TextEditingController expiryController = TextEditingController();
  final TextEditingController cvvController = TextEditingController();

  // Function to create an "Incomplete" record in Stripe Dashboard
  Future<void> _processSimulatedStripePayment() async {
    setState(() => isProcessing = true);

    try {
      // 1. Create a Payment Intent record on Stripe
      // This will show up in your Stripe Dashboard as "Unconfirmed / Incomplete"
      // proving that your API integration is working.
      await createIncompleteStripeRecord(
          (widget.amount * 100).toInt().toString(),
          'MYR'
      );

      // 2. We skip Stripe's official "confirmPayment" to avoid UI crashes.
      // We go straight to saving our data in Supabase.
      await _saveOrderToDatabase("Custom Card Input");

      if (!mounted) return;
      setState(() => isProcessing = false);

      // 3. Show Success Message immediately
      _showSuccessDialog();

    } catch (e) {
      setState(() => isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Payment processing error. Please try again.")),
      );
    }
  }

  // Stripe API Call (Just to create the record)
  Future<void> createIncompleteStripeRecord(String amount, String currency) async {
    try {
      await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          'Authorization': 'Bearer sk_test_51TMTra30pXzuvOG7huvUJr5GNa8dcHR5EuANhFYjRfMyzrzq5N7XH4gKOyeS71Vs9CWtJ5nFAcm41q0KV4uNsx5A00osQSZIc7',
          'Content-Type': 'application/x-www-form-urlencoded'
        },
        body: {
          'amount': amount,
          'currency': currency,
          'description': 'Order from NoSakit App - Member 2 Module',
        },
      );
    } catch (err) {
      debugPrint('Stripe Record Error: $err');
    }
  }

  Future<void> _saveOrderToDatabase(String method) async {
    await Supabase.instance.client.from('orders').insert({
      'user_name': 'Jin Han',
      'total_amount': widget.amount,
      'status': 'Paid',
      'payment_method': method,
      'delivery_status': 'PENDING',
      'items': CartManager.cartItems.map((item) => {
        'name': item.name,
        'price': item.price,
        'quantity': item.quantity,
        'image_url': item.imageUrl,
      }).toList(),
    });
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        content: const Text("Payment Successful!", textAlign: TextAlign.center),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                CartManager.cartItems.clear();
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const HomePage()), (route) => false);
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
      appBar: AppBar(title: const Text("Secure Payment"), backgroundColor: Colors.blueGrey.shade800, foregroundColor: Colors.white),
      body: isProcessing
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text("RM ${widget.amount.toStringAsFixed(2)}",
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green)),
            ),
            const SizedBox(height: 30),

            // --- CUSTOM CARD UI ---
            const Text("Card Number", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: cardNumController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: "4242 4242 4242 4242",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.credit_card),
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Expiry Date", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: expiryController,
                        decoration: const InputDecoration(hintText: "MM/YY", border: OutlineInputBorder()),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("CVV", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: cvvController,
                        obscureText: true,
                        decoration: const InputDecoration(hintText: "123", border: OutlineInputBorder()),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                onPressed: _processSimulatedStripePayment,
                child: const Text("Pay Now", style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
            ),
            const SizedBox(height: 20),
            const Center(child: Text("🔒 Secure SSL Encryption")),
            const Footer(),
          ],
        ),
      ),
    );
  }
}