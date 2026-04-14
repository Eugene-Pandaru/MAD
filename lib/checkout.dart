import 'package:flutter/material.dart';
import 'package:mad/cartmanager.dart';
import 'package:mad/utility.dart';
import 'package:mad/footer.dart';
import 'package:mad/paymentpage.dart';

import 'paymentpage.dart'; // We will create this next

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String selectedShipping = "Standard";
  double shippingFee = 5.00;

  @override
  Widget build(BuildContext context) {
    double subtotal = CartManager.getTotalPrice();
    double total = subtotal + shippingFee;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Checkout"),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 1. Delivery Address Section
            const Text("Delivery Address",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.red),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text("Jin Han", style: TextStyle(fontWeight: FontWeight.bold)),
                        Text("123, Jalan Pharmacy, Taman NoSakit, 56000 Kuala Lumpur"),
                        Text("+60 12-345 6789", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Utils.snackbar(context, "Address Management (Member 3 Feature)");
                    },
                    child: const Text("Change"),
                  )
                ],
              ),
            ),

            const SizedBox(height: 25),

            /// 2. Order Summary (Mini List)
            const Text("Order Summary",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...CartManager.cartItems.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("${item.quantity}x ${item.name}"),
                  Text("RM ${(item.price * item.quantity).toStringAsFixed(2)}"),
                ],
              ),
            )).toList(),

            const Divider(height: 30),

            /// 3. Shipping Options
            const Text("Shipping Method",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            RadioListTile(
              title: const Text("Standard Delivery (3-5 Days)"),
              subtitle: const Text("RM 5.00"),
              value: "Standard",
              groupValue: selectedShipping,
              onChanged: (value) {
                setState(() {
                  selectedShipping = value.toString();
                  shippingFee = 5.00;
                });
              },
            ),
            RadioListTile(
              title: const Text("Express Delivery (Next Day)"),
              subtitle: const Text("RM 12.00"),
              value: "Express",
              groupValue: selectedShipping,
              onChanged: (value) {
                setState(() {
                  selectedShipping = value.toString();
                  shippingFee = 12.00;
                });
              },
            ),

            const SizedBox(height: 25),

            /// 4. Final Bill
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  buildPriceRow("Subtotal", subtotal),
                  buildPriceRow("Shipping Fee", shippingFee),
                  const Divider(),
                  buildPriceRow("Total Payment", total, isTotal: true),
                ],
              ),
            ),

            const SizedBox(height: 30),

            /// 5. Action Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                onPressed: () {
                  // Navigate to Payment Simulation
                  Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => PaymentPage(amount: total))
                  );
                },
                child: const Text("Proceed to Payment",
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const Footer(),
          ],
        ),
      ),
    );
  }

  Widget buildPriceRow(String label, double price, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal
          )),
          Text("RM ${price.toStringAsFixed(2)}", style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.green : Colors.black
          )),
        ],
      ),
    );
  }
}