import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🟢 Header (Matching home/productlist style)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      "Checkout",
                      style: GoogleFonts.openSans(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// 1. Delivery Address Section
                    Text("Delivery Address",
                        style: GoogleFonts.openSans(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on, color: Color(0xFF1392AB)),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  deliveryAddress,
                                  style: GoogleFonts.openSans(fontSize: 14, color: Colors.black87),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => AddressPage()),
                              );
                              if (result != null && result is String) {
                                setState(() {
                                  deliveryAddress = result;
                                });
                              }
                            },
                            child: Text(
                              "Change",
                              style: GoogleFonts.openSans(
                                color: const Color(0xFF1392AB),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    /// 2. Order Summary
                    Text("Order Summary",
                        style: GoogleFonts.openSans(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        children: CartManager.cartItems.map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "${item.quantity}x ${item.name}",
                                style: GoogleFonts.openSans(fontSize: 14),
                              ),
                              Text(
                                "RM ${(item.price * item.quantity).toStringAsFixed(2)}",
                                style: GoogleFonts.openSans(fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        )).toList(),
                      ),
                    ),

                    const SizedBox(height: 25),

                    /// 3. Shipping Options
                    Text("Shipping Method",
                        style: GoogleFonts.openSans(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        children: [
                          RadioListTile<String>(
                            activeColor: const Color(0xFF1392AB),
                            title: Text("Standard Delivery", style: GoogleFonts.openSans(fontSize: 15, fontWeight: FontWeight.w600)),
                            subtitle: Text("3-5 Days • RM 5.00", style: GoogleFonts.openSans(fontSize: 12)),
                            value: "Standard",
                            groupValue: selectedShipping,
                            onChanged: (value) {
                              setState(() {
                                selectedShipping = value!;
                                shippingFee = 5.00;
                              });
                            },
                          ),
                          RadioListTile<String>(
                            activeColor: const Color(0xFF1392AB),
                            title: Text("Express Delivery", style: GoogleFonts.openSans(fontSize: 15, fontWeight: FontWeight.w600)),
                            subtitle: Text("Next Day • RM 12.00", style: GoogleFonts.openSans(fontSize: 12)),
                            value: "Express",
                            groupValue: selectedShipping,
                            onChanged: (value) {
                              setState(() {
                                selectedShipping = value!;
                                shippingFee = 12.00;
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    /// 4. Final Bill
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1392AB).withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF1392AB).withValues(alpha: 0.1)),
                      ),
                      child: Column(
                        children: [
                          buildPriceRow("Subtotal", subtotal),
                          buildPriceRow("Shipping Fee", shippingFee),
                          const Divider(height: 30),
                          buildPriceRow("Total Payment", total, isTotal: true),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    /// 5. Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1392AB),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          elevation: 0,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PaymentPage(
                                subtotal: subtotal,
                                deliveryFee: shippingFee,
                                deliveryAddress: deliveryAddress,
                                paymentType: "medicine",
                              ),
                            ),
                          );
                        },
                        child: Text(
                          "Proceed to Payment",
                          style: GoogleFonts.openSans(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Footer(),
                  ],
                ),
              ),
            ],
          ),
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
          Text(label, style: GoogleFonts.openSans(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal
          )),
          Text("RM ${price.toStringAsFixed(2)}", style: GoogleFonts.openSans(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.bold,
              color: isTotal ? const Color(0xFF1392AB) : Colors.black
          )),
        ],
      ),
    );
  }
}
