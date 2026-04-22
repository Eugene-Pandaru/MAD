import 'package:flutter/material.dart';
import 'package:mad/cartmanager.dart';
import 'package:mad/footer.dart';
import 'package:mad/home.dart';
import 'package:mad/utility.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;

class PaymentPage extends StatefulWidget {
  final double subtotal;
  final double deliveryFee;
  final String deliveryAddress;

  const PaymentPage({
    super.key,
    required this.subtotal,
    required this.deliveryFee,
    required this.deliveryAddress,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  bool isProcessing = false;
  String mainMethod = "FPX"; // Default selection: FPX, E-wallet, or Card

  // Form Key for Card Validation
  final _formKey = GlobalKey<FormState>();

  // Sub-selections
  String selectedBank = "Maybank2u";
  String selectedWallet = "Touch 'n Go";

  // Card Controllers
  final TextEditingController cardNumController = TextEditingController();
  final TextEditingController expiryController = TextEditingController();
  final TextEditingController cvvController = TextEditingController();

  final List<String> banks = ["Maybank2u", "CIMB Clicks", "Public Bank", "RHB Now", "Bank Islam"];
  final List<String> wallets = ["Touch 'n Go", "GrabPay", "ShopeePay", "Apple Pay"];

  double get totalAmount => widget.subtotal + widget.deliveryFee;

  Future<void> _handlePayment() async {
    // 1. If Card is selected, validate the form first
    if (mainMethod == "Card") {
      if (!_formKey.currentState!.validate()) return;
    }

    setState(() => isProcessing = true);

    try {
      // 2. Determine the Label for Database
      String finalMethodLabel = "";
      if (mainMethod == "FPX") finalMethodLabel = "FPX - $selectedBank";
      else if (mainMethod == "E-wallet") finalMethodLabel = "E-wallet - $selectedWallet";
      else finalMethodLabel = "Card";

      // 3. Create simulated Stripe Record (Reality Check)
      await createIncompleteStripeRecord(
          (totalAmount * 100).toInt().toString(), 'MYR', finalMethodLabel);

      // 4. Save to Supabase
      await _saveOrderToDatabase(finalMethodLabel);

      if (!mounted) return;
      setState(() => isProcessing = false);
      _showSuccessDialog(finalMethodLabel);

    } catch (e) {
      setState(() => isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Future<void> createIncompleteStripeRecord(String amount, String currency, String method) async {
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
          'description': 'Method: $method | Order NoSakit',
        },
      );
    } catch (err) {
      debugPrint('Stripe Log Error: $err');
    }
  }

  Future<void> _saveOrderToDatabase(String method) async {
    await Supabase.instance.client.from('orders').insert({
      'user_id': Utils.currentUser?['id'],
      'user_name': Utils.currentUser?['nickname'] ?? 'Guest',
      'total_amount': totalAmount,
      'delivery_fee': widget.deliveryFee,
      'delivery_address': widget.deliveryAddress,
      'status': 'Paid',
      'payment_method': method, // e.g., "FPX - Maybank2u"
      'delivery_status': 'PENDING',
      'items': CartManager.cartItems.map((item) => {
        'name': item.name,
        'price': item.price,
        'quantity': item.quantity,
        'image_url': item.imageUrl,
      }).toList(),
    });
  }

  void _showSuccessDialog(String method) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        content: Text("Payment Successful via $method!"),
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
      appBar: AppBar(title: const Text("Payment"), backgroundColor: Colors.blueGrey.shade800, foregroundColor: Colors.white),
      body: isProcessing
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Bill Summary ---
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  _row("Subtotal", widget.subtotal),
                  _row("Delivery Fee", widget.deliveryFee),
                  const Divider(),
                  _row("Total Amount", totalAmount, isBold: true),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // --- Payment Mode Selection ---
            const Text("Select Payment Category", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _methodBtn("FPX"),
                _methodBtn("E-wallet"),
                _methodBtn("Card"),
              ],
            ),
            const SizedBox(height: 25),

            // --- Dynamic Content ---
            if (mainMethod == "FPX") _buildFPXView(),
            if (mainMethod == "E-wallet") _buildEWalletView(),
            if (mainMethod == "Card") _buildCardView(),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                onPressed: _handlePayment,
                child: Text("Pay RM ${totalAmount.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontSize: 18)),
              ),
            ),
            const Footer(),
          ],
        ),
      ),
    );
  }

  // --- UI Components ---

  Widget _methodBtn(String type) {
    bool isSel = mainMethod == type;
    return GestureDetector(
      onTap: () => setState(() => mainMethod = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSel ? Colors.blueAccent : Colors.white,
          border: Border.all(color: Colors.blueAccent),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(type, style: TextStyle(color: isSel ? Colors.white : Colors.blueAccent, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildFPXView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Select Bank"),
        const SizedBox(height: 10),
        DropdownButtonFormField(
          value: selectedBank,
          items: banks.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
          onChanged: (val) => setState(() => selectedBank = val!),
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
      ],
    );
  }

  Widget _buildEWalletView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Select E-wallet"),
        const SizedBox(height: 10),
        DropdownButtonFormField(
          value: selectedWallet,
          items: wallets.map((w) => DropdownMenuItem(value: w, child: Text(w))).toList(),
          onChanged: (val) => setState(() => selectedWallet = val!),
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
      ],
    );
  }

  Widget _buildCardView() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Card Number"),
          const SizedBox(height: 8),
          TextFormField(
            controller: cardNumController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: "1234 1234 1234 1234", border: OutlineInputBorder()),
            validator: (value) => (value == null || value.length < 16) ? "Please Enter Valid Card Number" : null,
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Expiry (MM/YY)"),
                    TextFormField(
                      controller: expiryController,
                      decoration: const InputDecoration(hintText: "12/25", border: OutlineInputBorder()),
                      validator: (value) {
                        if (value == null || !RegExp(r'^\d{2}/\d{2}$').hasMatch(value)) return "Invalid format";
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("CVV"),
                    TextFormField(
                      controller: cvvController,
                      obscureText: true,
                      decoration: const InputDecoration(hintText: "123", border: OutlineInputBorder()),
                      validator: (value) => (value == null || value.length != 3) ? "Invalid CVV" : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String label, double amt, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text("RM ${amt.toStringAsFixed(2)}", style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}
