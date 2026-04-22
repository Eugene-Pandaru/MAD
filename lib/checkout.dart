import 'package:flutter/material.dart';
import 'package:mad/cartmanager.dart';
import 'package:mad/footer.dart';
import 'package:mad/paymentpage.dart';
import 'package:mad/addresspage.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});


  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String deliveryAddress = "123, Jalan Pharmacy, Taman NoSakit, 56000 Kuala Lumpur";
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
                      children: [
                        Text(deliveryAddress),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      // Navigate to AddressPage and wait for the result
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AddressPage()),
                      );

                      // If the user confirmed an address, update the UI
                      if (result != null && result is String) {
                        setState(() {
                          deliveryAddress = result;
                        });
                      }
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
            RadioGroup<String>(
              groupValue: selectedShipping,
              onChanged: (value) {
                setState(() {
                  selectedShipping = value!;
                  shippingFee = value == "Standard" ? 5.00 : 12.00;
                });
              },
              child: Column(
                children: [
                  RadioListTile<String>(
                    title: const Text("Standard Delivery (3-5 Days)"),
                    subtitle: const Text("RM 5.00"),
                    value: "Standard",
                  ),
                  RadioListTile<String>(
                    title: const Text("Express Delivery (Next Day)"),
                    subtitle: const Text("RM 12.00"),
                    value: "Express",
                  ),
                ],
              ),
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PaymentPage(
                        subtotal: subtotal,        // Pass your cart subtotal
                        deliveryFee: shippingFee,  // Pass the RM 5.00 or RM 12.00 fee
                        deliveryAddress: deliveryAddress,
                      ),
                    ),
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