import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mad/footer.dart';
import 'package:mad/utility.dart';
import 'package:mad/myaddressdetails.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyAddressPage extends StatefulWidget {
  const MyAddressPage({super.key});

  @override
  State<MyAddressPage> createState() => _MyAddressPageState();
}

class _MyAddressPageState extends State<MyAddressPage> {
  final supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    final user = Utils.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
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
                    "My Addresses",
                    style: GoogleFonts.openSans(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _buildAddressBox(
                      context,
                      label: "Address 1",
                      address: user?['address'] ?? "No address set",
                      columnName: 'address',
                    ),
                    _buildAddressBox(
                      context,
                      label: "Address 2",
                      address: user?['address2'] ?? "No address set",
                      columnName: 'address2',
                    ),
                    _buildAddressBox(
                      context,
                      label: "Address 3",
                      address: user?['address3'] ?? "No address set",
                      columnName: 'address3',
                    ),
                  ],
                ),
              ),
            ),
            const Footer(),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressBox(BuildContext context, {required String label, required String address, required String columnName}) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MyAddressDetailsPage(
              label: label,
              currentAddress: address == "No address set" ? "" : address,
              columnName: columnName,
            ),
          ),
        );
        setState(() {}); // Refresh UI on return
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: GoogleFonts.openSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1392AB),
                  ),
                ),
                const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF1392AB)),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              address,
              style: GoogleFonts.openSans(fontSize: 14, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}
