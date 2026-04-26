import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mad/footer.dart';
import 'package:mad/utility.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mad/addresspage.dart';

class MyAddressDetailsPage extends StatefulWidget {
  final String label;
  final String currentAddress;
  final String columnName;

  const MyAddressDetailsPage({
    super.key,
    required this.label,
    required this.currentAddress,
    required this.columnName,
  });

  @override
  State<MyAddressDetailsPage> createState() => _MyAddressDetailsPageState();
}

class _MyAddressDetailsPageState extends State<MyAddressDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final supabase = Supabase.instance.client;
  late TextEditingController _addressController;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController(text: widget.currentAddress);
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _openMapPicker() async {
    // Navigate to AddressPage (the map picker)
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddressPage()),
    );

    // If user confirmed a location on the map, update the text field
    if (result != null && result is String) {
      setState(() {
        _addressController.text = result;
      });
      if (mounted) Utils.snackbar(context, "Location updated from map", color: Colors.green);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 80),
              const SizedBox(height: 20),
              Text(
                "Save Successfully",
                textAlign: TextAlign.center,
                style: GoogleFonts.openSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1392AB),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Back to address list
                  },
                  child: Text("OK",
                      style: GoogleFonts.openSans(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Future<void> _updateAddress() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSaving = true);
    try {
      final userId = Utils.currentUser?['id'];
      final response = await supabase
          .from('users_profile')
          .update({widget.columnName: _addressController.text})
          .eq('id', userId)
          .select()
          .single();

      Utils.currentUser = response; // Update local session
      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) Utils.snackbar(context, "Update failed: ${e.toString()}", color: Colors.red);
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    "Update ${widget.label}",
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Enter your new address below:",
                        style: GoogleFonts.openSans(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _addressController,
                        maxLines: 4,
                        style: GoogleFonts.openSans(),
                        decoration: InputDecoration(
                          hintText: "E.g. No. 1, Jalan Pharmacy...",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: const BorderSide(color: Color(0xFF1392AB)),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return "Please enter an address";
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),

                      /// 📍 Use Map Picker Button (Was Current Location)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _openMapPicker,
                          icon: const Icon(Icons.map_outlined, size: 18),
                          label: Text("Select from Map", style: GoogleFonts.openSans(fontWeight: FontWeight.w600)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF1392AB),
                            side: const BorderSide(color: Color(0xFF1392AB)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: isSaving ? null : _updateAddress,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1392AB),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                          child: isSaving
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  "Save Address",
                                  style: GoogleFonts.openSans(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
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
      ),
    );
  }
}
