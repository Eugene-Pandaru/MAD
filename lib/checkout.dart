import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mad/cartmanager.dart';
import 'package:mad/footer.dart';
import 'package:mad/paymentpage.dart';
import 'package:mad/addresspage.dart';
import 'package:mad/utility.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final supabase = Supabase.instance.client;
  String? deliveryAddress;
  String selectedShipping = "Standard";
  double shippingFee = 5.00;

  // Voucher Selection State
  Map<String, dynamic>? selectedShippingVoucher;
  Map<String, dynamic>? selectedDiscountVoucher;

  @override
  void initState() {
    super.initState();
    // 🏠 Initialize address from Address 1 in database
    deliveryAddress = Utils.currentUser?['address'];
  }

  void _showAddressSelectionDialog() {
    final user = Utils.currentUser;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Select Delivery Address", style: GoogleFonts.openSans(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAddressOption("Address 1", user?['address']),
              _buildAddressOption("Address 2", user?['address2']),
              _buildAddressOption("Address 3", user?['address3']),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.my_location, color: Color(0xFF1392AB)),
                title: Text("Select from map", style: GoogleFonts.openSans(fontWeight: FontWeight.w600)),
                onTap: () async {
                  Navigator.pop(context); // Close dialog
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddressPage()),
                  );
                  if (result != null && result is String) {
                    setState(() => deliveryAddress = result);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddressOption(String label, String? address) {
    if (address == null || address.isEmpty) return const SizedBox.shrink();
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: GoogleFonts.openSans(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF1392AB))),
      subtitle: Text(address, style: GoogleFonts.openSans(fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
      onTap: () {
        setState(() => deliveryAddress = address);
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double subtotal = CartManager.getTotalPrice();
    
    // Calculate effective shipping fee
    double effectiveShippingFee = shippingFee;
    if (selectedShippingVoucher != null) {
      double discount = double.tryParse(selectedShippingVoucher!['discount_amount']?.toString() ?? '0') ?? 0;
      effectiveShippingFee = (shippingFee - discount).clamp(0, double.infinity);
    }

    // Calculate effective discount
    double discountAmount = 0;
    if (selectedDiscountVoucher != null) {
      double amt = double.tryParse(selectedDiscountVoucher!['discount_amount']?.toString() ?? '0') ?? 0;
      if (selectedDiscountVoucher!['discount_type'] == 'PERCENTAGE') {
        discountAmount = subtotal * (amt / 100);
      } else {
        discountAmount = amt;
      }
    }

    double total = (subtotal - discountAmount + effectiveShippingFee).clamp(0, double.infinity);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🟢 Header
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
                    Text("Delivery Address", style: GoogleFonts.openSans(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: (deliveryAddress == null || deliveryAddress!.isEmpty) 
                              ? Colors.red.shade200 
                              : Colors.grey.shade200
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on, color: Color(0xFF1392AB)),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Text(
                              (deliveryAddress == null || deliveryAddress!.isEmpty) 
                                  ? "No delivery address set. Please add one." 
                                  : deliveryAddress!, 
                              style: GoogleFonts.openSans(
                                fontSize: 14, 
                                color: (deliveryAddress == null || deliveryAddress!.isEmpty) ? Colors.red : Colors.black87
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _showAddressSelectionDialog,
                            child: Text("Change", style: GoogleFonts.openSans(color: const Color(0xFF1392AB), fontWeight: FontWeight.bold)),
                          )
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    /// 2. Order Summary
                    Text("Order Summary", style: GoogleFonts.openSans(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(15)),
                      child: Column(
                        children: CartManager.cartItems.map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("${item.quantity}x ${item.name}", style: GoogleFonts.openSans(fontSize: 14)),
                              Text("RM ${(item.price * item.quantity).toStringAsFixed(2)}", style: GoogleFonts.openSans(fontSize: 14, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        )).toList(),
                      ),
                    ),

                    const SizedBox(height: 25),

                    /// 3. Voucher Selection Section
                    Text("Apply Vouchers", style: GoogleFonts.openSans(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    StreamBuilder<List<Map<String, dynamic>>>(
                      stream: supabase.from('vouchers').stream(primaryKey: ['id']),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const LinearProgressIndicator();
                        final vouchers = snapshot.data!;
                        
                        return Column(
                          children: vouchers.map((v) {
                            bool isShipping = v['category'] == 'SHIPPING';
                            bool isSelected = (isShipping && selectedShippingVoucher?['id'] == v['id']) ||
                                             (!isShipping && selectedDiscountVoucher?['id'] == v['id']);
                            
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF1392AB).withValues(alpha: 0.1) : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isSelected ? const Color(0xFF1392AB) : Colors.grey.shade200),
                              ),
                              child: ListTile(
                                leading: Icon(isShipping ? Icons.local_shipping : Icons.confirmation_number, color: isSelected ? const Color(0xFF1392AB) : Colors.grey),
                                title: Text(v['code'] ?? "VOUCHER", style: GoogleFonts.openSans(fontWeight: FontWeight.bold, fontSize: 14)),
                                subtitle: Text(v['description'] ?? "", style: GoogleFonts.openSans(fontSize: 12)),
                                trailing: Icon(isSelected ? Icons.check_circle : Icons.circle_outlined, color: isSelected ? const Color(0xFF1392AB) : Colors.grey),
                                onTap: () {
                                  setState(() {
                                    if (isShipping) {
                                      selectedShippingVoucher = (selectedShippingVoucher?['id'] == v['id']) ? null : v;
                                    } else {
                                      selectedDiscountVoucher = (selectedDiscountVoucher?['id'] == v['id']) ? null : v;
                                    }
                                  });
                                },
                              ),
                            );
                          }).toList(),
                        );
                      },
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
                          if (discountAmount > 0) buildPriceRow("Discount", -discountAmount, isDiscount: true),
                          buildPriceRow("Shipping Fee", effectiveShippingFee),
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
                          // 🛡️ REQUIRED ADDRESS VALIDATION
                          if (deliveryAddress == null || deliveryAddress!.isEmpty) {
                            Utils.snackbar(context, "Please set a delivery address first!", color: Colors.red);
                            return;
                          }

                          // Combine voucher codes for the order
                          String? combinedCodes;
                          if (selectedShippingVoucher != null && selectedDiscountVoucher != null) {
                            combinedCodes = "${selectedShippingVoucher!['code']}, ${selectedDiscountVoucher!['code']}";
                          } else {
                            combinedCodes = selectedShippingVoucher?['code'] ?? selectedDiscountVoucher?['code'];
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PaymentPage(
                                subtotal: subtotal - discountAmount,
                                deliveryFee: effectiveShippingFee,
                                deliveryAddress: deliveryAddress!,
                                paymentType: "medicine",
                                voucherCode: combinedCodes,
                              ),
                            ),
                          );
                        },
                        child: Text("Proceed to Payment", style: GoogleFonts.openSans(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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

  Widget buildPriceRow(String label, double price, {bool isTotal = false, bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.openSans(fontSize: isTotal ? 18 : 14, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
          Text(
            isDiscount ? "- RM ${(-price).toStringAsFixed(2)}" : "RM ${price.toStringAsFixed(2)}",
            style: GoogleFonts.openSans(
              fontSize: isTotal ? 18 : 14,
              fontWeight: FontWeight.bold,
              color: isTotal ? const Color(0xFF1392AB) : (isDiscount ? Colors.green : Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}
