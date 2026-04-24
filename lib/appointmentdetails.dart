import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
      print("Attempting to cancel appointment ID: ${widget.appointment['id']}");

      final response = await supabase
          .from('appointments')
          .update({'status': 'Cancelled'})
          .eq('id', widget.appointment['id'])
          .select(); // Adding .select() confirms if data actually changed

      print("Database Response: $response");

      if (response.isEmpty) {
        throw "No record found to update. Check if the ID is correct.";
      }

      if (!mounted) return;
      Utils.snackbar(context, "Status changed to Cancelled", color: Colors.red);
      Navigator.pop(context);
    } catch (e) {
      print("Update Error: $e");
      Utils.snackbar(context, "Database Error: $e", color: Colors.red);
    } finally {
      setState(() => isUpdating = false);
    }
  }

  // Show confirmation dialog
  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cancel Appointment?"),
        content: const Text(
          "Are you sure? Please note that the RM 10.00 booking fee is non-refundable.",
          style: TextStyle(color: Colors.red),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Keep it")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelAppointment();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Yes, Cancel", style: TextStyle(color: Colors.white)),
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
      appBar: AppBar(title: const Text("Appointment Details"), backgroundColor: Colors.green),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- 1. STATUS HEADER ---
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: isCancelled ? Colors.red.shade50 : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(isCancelled ? Icons.cancel : Icons.check_circle,
                            color: isCancelled ? Colors.red : Colors.green),
                        const SizedBox(width: 10),
                        Text(
                          "Status: ${appt['status'] ?? 'Confirmed'}",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isCancelled ? Colors.red : Colors.green
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // --- 2. APPOINTMENT INFO ---
                  const Text("Pharmacist", style: TextStyle(color: Colors.grey)),
                  Text(appt['pharmacist_name'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),

                  const SizedBox(height: 20),

                  const Text("Date & Time", style: TextStyle(color: Colors.grey)),
                  Text("${appt['appointment_date']} at ${appt['appointment_time']}",
                      style: const TextStyle(fontSize: 18)),

                  const Divider(height: 40),

                  // --- 3. PAYMENT INFO ---
                  const Text("Payment Details", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Consultation Fee"),
                      Text("RM ${appt['total_amount']}"),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text("Payment Method: Stripe Card", style: TextStyle(color: Colors.grey, fontSize: 12)),

                  const SizedBox(height: 40),

                  // --- 4. REFUND POLICY WARNING ---
                  if (!isCancelled)
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        border: Border.all(color: Colors.amber),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Refund Policy: Appointment fees are non-refundable upon cancellation.",
                              style: TextStyle(fontSize: 12, color: Colors.orange),
                            ),
                          ),
                        ],
                      ),
                    ),
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
                height: 50,
                child: OutlinedButton(
                  onPressed: isUpdating ? null : _showCancelDialog,
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                  child: isUpdating
                      ? const CircularProgressIndicator(color: Colors.red)
                      : const Text("Cancel Appointment"),
                ),
              ),
            ),
          const Footer(),
        ],
      ),
    );
  }
}