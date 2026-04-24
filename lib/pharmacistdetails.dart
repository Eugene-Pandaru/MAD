import 'package:flutter/material.dart';
import 'package:mad/footer.dart';
import 'package:mad/utility.dart';
import 'package:mad/paymentpage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PharmacistDetailsPage extends StatefulWidget {
  final Map<String, dynamic> pharmacist;
  const PharmacistDetailsPage({super.key, required this.pharmacist});

  @override
  State<PharmacistDetailsPage> createState() => _PharmacistDetailsPageState();
}

class _PharmacistDetailsPageState extends State<PharmacistDetailsPage> {
  final supabase = Supabase.instance.client;
  DateTime? selectedDate;
  String? selectedTimeSlot;
  List<String> takenSlots = []; // To store slots already booked in DB
  bool isLoadingSlots = false;

  // 1-hour interval slots
  final List<String> allTimeSlots = [
    "09:00 AM", "10:00 AM", "11:00 AM", "12:00 PM",
    "02:00 PM", "03:00 PM", "04:00 PM", "05:00 PM"
  ];

  // Fetch booked slots for the selected pharmacist and date
  Future<void> _fetchTakenSlots(DateTime date) async {
    setState(() => isLoadingSlots = true);
    final formattedDate = "${date.day}/${date.month}/${date.year}";

    try {
      final data = await supabase
          .from('appointments')
          .select('appointment_time')
          .eq('pharmacist_name', widget.pharmacist['name'])
          .eq('appointment_date', formattedDate)
      // THIS LINE IS THE KEY:
          .neq('status', 'Cancelled');

      setState(() {
        // takenSlots will now ONLY contain slots where status is 'Paid' or 'Confirmed'
        takenSlots = List<String>.from(data.map((item) => item['appointment_time']));
        isLoadingSlots = false;
      });
    } catch (e) {
      setState(() => isLoadingSlots = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
        selectedTimeSlot = null; // Reset time if date changes
      });
      _fetchTakenSlots(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dr = widget.pharmacist;

    return Scaffold(
      appBar: AppBar(title: const Text("Book Appointment"), backgroundColor: Colors.green),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pharmacist Info
                  Row(
                    children: [
                      CircleAvatar(radius: 40, backgroundImage: NetworkImage(dr['image_url'])),
                      const SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(dr['name'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 25),
                        ],
                      ),
                    ],
                  ),
                  const Text("Professional Biography",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Text(
                      "As a highly qualified pharmacist, ${widget.pharmacist['name']} specializes in ${widget.pharmacist['description'].toLowerCase()}. "
                          "With extensive experience in clinical pharmacy and patient counseling, they provide expert guidance on medication safety, "
                          "drug interactions, and wellness management. They are committed to helping patients achieve optimal health outcomes "
                          "through personalized pharmaceutical care and evidence-based advice.",
                      style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.6),
                    ),
                  ),

                  const SizedBox(height: 30),
                  const Divider(height: 40),

                  // 1. Pick Date First
                  const Text("1. Select Date", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ListTile(
                    tileColor: Colors.green.shade50,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    leading: const Icon(Icons.calendar_month, color: Colors.green),
                    title: Text(selectedDate == null
                        ? "Choose a date"
                        : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}"),
                    trailing: const Icon(Icons.edit, size: 20),
                    onTap: () => _selectDate(context),
                  ),

                  const SizedBox(height: 30),

                  // 2. Time Slot Table
                  const Text("2. Available Time Slots (1-hour)", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),

                  if (selectedDate == null)
                    const Center(child: Text("Please select a date first", style: TextStyle(color: Colors.grey)))
                  else if (isLoadingSlots)
                    const Center(child: CircularProgressIndicator())
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 2.2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: allTimeSlots.length,
                      itemBuilder: (context, index) {
                        String slot = allTimeSlots[index];
                        bool isTaken = takenSlots.contains(slot);
                        bool isSelected = selectedTimeSlot == slot;

                        return GestureDetector(
                          onTap: isTaken ? null : () => setState(() => selectedTimeSlot = slot),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isTaken
                                  ? Colors.grey.shade300 // Disabled color
                                  : (isSelected ? Colors.green : Colors.white),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: isTaken ? Colors.transparent : Colors.green),
                            ),
                            child: Text(
                              isTaken ? "Booked" : slot,
                              style: TextStyle(
                                color: isTaken ? Colors.grey.shade600 : (isSelected ? Colors.white : Colors.green),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),

          // Booking Button
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: (selectedDate == null || selectedTimeSlot == null)
                    ? null
                    : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PaymentPage(
                        subtotal: 10.0,
                        deliveryFee: 0,
                        deliveryAddress: "Online Consultation",
                        paymentType: "appointment",
                        pharmacistName: dr['name'],
                        apptDate: "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
                        apptTime: selectedTimeSlot!,
                      ),
                    ),
                  );
                },
                child: const Text("Confirm & Pay RM10.00"),
              ),
            ),
          ),
          const Footer(),
        ],
      ),
    );
  }
}