import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  List<String> takenSlots = [];
  bool isLoadingSlots = false;

  final List<String> allTimeSlots = [
    "09:00 AM", "10:00 AM", "11:00 AM", "12:00 PM",
    "02:00 PM", "03:00 PM", "04:00 PM", "05:00 PM"
  ];

  Future<void> _fetchTakenSlots(DateTime date) async {
    setState(() => isLoadingSlots = true);
    final formattedDate = "${date.day}/${date.month}/${date.year}";

    try {
      final data = await supabase
          .from('appointments')
          .select('appointment_time')
          .eq('pharmacist_name', widget.pharmacist['name'])
          .eq('appointment_date', formattedDate)
          .neq('status', 'Cancelled');

      setState(() {
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
      initialDate: DateTime.now().add(const Duration(days: 0)), // Can select today
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1392AB),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
        selectedTimeSlot = null;
      });
      _fetchTakenSlots(picked);
    }
  }

  // 🔍 Helper to check if a slot has already passed today
  bool _isSlotPast(String slot) {
    if (selectedDate == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selDate = DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day);

    // If selected date is in the future, no slots are past
    if (selDate.isAfter(today)) return false;

    // It's today. Parse the slot time (e.g. "09:00 AM")
    int slotHour = int.parse(slot.split(':')[0]);
    if (slot.contains("PM") && slotHour != 12) slotHour += 12;
    if (slot.contains("AM") && slotHour == 12) slotHour = 0;

    // Disable if the current hour has reached or passed the slot start time
    return now.hour >= slotHour;
  }

  @override
  Widget build(BuildContext context) {
    final dr = widget.pharmacist;

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
                    "Book Consultation",
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
                    // Pharmacist Profile Card
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 40, 
                            backgroundImage: NetworkImage(dr['image_url']),
                            backgroundColor: Colors.grey.shade200,
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  dr['name'], 
                                  style: GoogleFonts.openSans(fontSize: 20, fontWeight: FontWeight.bold)
                                ),
                                const SizedBox(height: 5),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1392AB).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    "Senior Pharmacist",
                                    style: GoogleFonts.openSans(fontSize: 12, color: const Color(0xFF1392AB), fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),
                    Text("Professional Biography", style: GoogleFonts.openSans(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 10),
                    Text(
                      "As a highly qualified pharmacist, ${dr['name']} specializes in clinical pharmacy. They are committed to helping patients achieve optimal health outcomes through personalized care.",
                      style: GoogleFonts.openSans(fontSize: 14, color: Colors.grey.shade600, height: 1.6),
                    ),

                    const SizedBox(height: 30),
                    const Divider(),
                    const SizedBox(height: 20),

                    // 1. Select Date
                    Text("1. Select Date", style: GoogleFonts.openSans(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () => _selectDate(context),
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8DC6BC).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: const Color(0xFF8DC6BC).withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_month, color: Color(0xFF1392AB)),
                            const SizedBox(width: 15),
                            Text(
                              selectedDate == null
                                  ? "Choose a consultation date"
                                  : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
                              style: GoogleFonts.openSans(fontWeight: FontWeight.w600),
                            ),
                            const Spacer(),
                            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // 2. Select Time
                    Text("2. Available Time Slots", style: GoogleFonts.openSans(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 15),

                    if (selectedDate == null)
                      Center(child: Text("Please select a date first", style: GoogleFonts.openSans(color: Colors.grey)))
                    else if (isLoadingSlots)
                      const Center(child: CircularProgressIndicator(color: Color(0xFF1392AB)))
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
                          bool isPast = _isSlotPast(slot); // 🔍 Check if slot is in the past
                          bool isSelected = selectedTimeSlot == slot;
                          bool isDisabled = isTaken || isPast;

                          return GestureDetector(
                            onTap: isDisabled ? null : () => setState(() => selectedTimeSlot = slot),
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isDisabled
                                    ? Colors.grey.shade200
                                    : (isSelected ? const Color(0xFF1392AB) : Colors.white),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDisabled ? Colors.transparent : const Color(0xFF1392AB),
                                ),
                              ),
                              child: Text(
                                isTaken ? "Booked" : (isPast ? "Unavailable" : slot),
                                style: GoogleFonts.openSans(
                                  color: isDisabled ? Colors.grey : (isSelected ? Colors.white : const Color(0xFF1392AB)),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),

            // Footer Button
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))],
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 55,
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1392AB),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 0,
                      ),
                      child: Text(
                        "Confirm & Pay RM10.00", 
                        style: GoogleFonts.openSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Footer(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
