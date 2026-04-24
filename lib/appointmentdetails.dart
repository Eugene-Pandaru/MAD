import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mad/footer.dart';
import 'package:mad/utility.dart';

class AppointmentDetailPage extends StatefulWidget {
  final Map<String, dynamic> appointment;
  const AppointmentDetailPage({super.key, required this.appointment});

  @override
  State<AppointmentDetailPage> createState() => _AppointmentDetailPageState();
}

class _AppointmentDetailPageState extends State<AppointmentDetailPage> {
  final supabase = Supabase.instance.client;
  bool isUpdating = false;

  Future<void> _cancelAppointment() async {
    setState(() => isUpdating = true);
    try {
      final response = await supabase
          .from('appointments')
          .update({'status': 'Cancelled'})
          .eq('id', widget.appointment['id'])
          .select();

      if (response.isEmpty) {
        throw "No record found to update.";
      }

      if (!mounted) return;
      Utils.snackbar(context, "Status changed to Cancelled", color: Colors.red);
      Navigator.pop(context);
    } catch (e) {
      Utils.snackbar(context, "Database Error: $e", color: Colors.red);
    } finally {
      setState(() => isUpdating = false);
    }
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Cancel Appointment?", style: GoogleFonts.openSans(fontWeight: FontWeight.bold)),
        content: Text(
          "Are you sure? Please note that the RM 10.00 booking fee is non-refundable.",
          style: GoogleFonts.openSans(color: Colors.red, fontSize: 14),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Keep it", style: GoogleFonts.openSans(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelAppointment();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: Text("Yes, Cancel", style: GoogleFonts.openSans(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appt = widget.appointment;
    bool isCancelled = appt['status'] == 'Cancelled';

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
                    "Booking Details",
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- 1. STATUS HEADER ---
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: (isCancelled ? Colors.red : const Color(0xFF1392AB)).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: (isCancelled ? Colors.red : const Color(0xFF1392AB)).withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(isCancelled ? Icons.cancel : Icons.check_circle,
                              color: isCancelled ? Colors.red : const Color(0xFF1392AB)),
                          const SizedBox(width: 15),
                          Text(
                            "Status: ${appt['status'] ?? 'Confirmed'}",
                            style: GoogleFonts.openSans(
                                fontWeight: FontWeight.bold,
                                color: isCancelled ? Colors.red : const Color(0xFF1392AB)
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // --- 2. APPOINTMENT INFO ---
                    Text("Pharmacist", style: GoogleFonts.openSans(color: Colors.grey, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 5),
                    Text(appt['pharmacist_name'], style: GoogleFonts.openSans(fontSize: 20, fontWeight: FontWeight.bold)),

                    const SizedBox(height: 25),

                    Text("Consultation Schedule", style: GoogleFonts.openSans(color: Colors.grey, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Color(0xFF1392AB), size: 20),
                          const SizedBox(width: 10),
                          Text("${appt['appointment_date']} at ${appt['appointment_time']}",
                              style: GoogleFonts.openSans(fontSize: 16, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),
                    const Divider(),
                    const SizedBox(height: 20),

                    // --- 3. PAYMENT INFO ---
                    Text("Payment Summary", style: GoogleFonts.openSans(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 15),
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1392AB).withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Consultation Fee", style: GoogleFonts.openSans()),
                              Text("RM ${appt['total_amount']}", style: GoogleFonts.openSans(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Payment Method", style: GoogleFonts.openSans(fontSize: 12, color: Colors.grey)),
                              Text(appt['payment_method'] ?? "Stripe Card", style: GoogleFonts.openSans(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // --- 4. REFUND POLICY WARNING ---
                    if (!isCancelled)
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          border: Border.all(color: Colors.amber.shade200),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.amber, size: 24),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Text(
                                "Cancellation Policy: Booking fees are non-refundable once confirmed.",
                                style: GoogleFonts.openSans(fontSize: 12, color: Colors.amber.shade900, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // --- 5. CANCEL BUTTON ---
            if (!isCancelled)
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: OutlinedButton(
                    onPressed: isUpdating ? null : _showCancelDialog,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red, 
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: isUpdating
                        ? const CircularProgressIndicator(color: Colors.red)
                        : Text("Cancel Appointment", style: GoogleFonts.openSans(fontWeight: FontWeight.bold)),
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
