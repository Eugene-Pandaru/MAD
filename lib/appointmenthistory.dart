import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mad/footer.dart';
import 'package:mad/pharmacist.dart';
import 'package:mad/appointmentdetails.dart';

class AppointmentHistoryPage extends StatefulWidget {
  const AppointmentHistoryPage({super.key});

  @override
  State<AppointmentHistoryPage> createState() => _AppointmentHistoryPageState();
}

class _AppointmentHistoryPageState extends State<AppointmentHistoryPage> {
  final supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
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
                    "My Appointments",
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
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: supabase
                    .from('appointments')
                    .stream(primaryKey: ['id'])
                    .order('created_at', ascending: false),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF1392AB)));
                  }

                  final appointments = snapshot.data ?? [];

                  if (appointments.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_today_outlined, size: 80, color: Colors.grey.shade300),
                          const SizedBox(height: 10),
                          Text("No appointments scheduled.", 
                            style: GoogleFonts.openSans(color: Colors.grey)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: appointments.length,
                    itemBuilder: (context, index) {
                      final appt = appointments[index];
                      bool isCancelled = appt['status'] == 'Cancelled';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: ListTile(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AppointmentDetailPage(appointment: appt),
                              ),
                            );
                          },
                          contentPadding: const EdgeInsets.all(15),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: (isCancelled ? Colors.red : const Color(0xFF1392AB)).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.person_outline, 
                              color: isCancelled ? Colors.red : const Color(0xFF1392AB)
                            ),
                          ),
                          title: Text(
                            appt['pharmacist_name'],
                            style: GoogleFonts.openSans(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 5),
                              Text("📅 ${appt['appointment_date']}", style: GoogleFonts.openSans(fontSize: 12)),
                              Text("⏰ ${appt['appointment_time']}", style: GoogleFonts.openSans(fontSize: 12)),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: (isCancelled ? Colors.red : const Color(0xFF8DC6BC)).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  appt['status'] ?? "Confirmed",
                                  style: GoogleFonts.openSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isCancelled ? Colors.red : const Color(0xFF1392AB),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          trailing: Text(
                            "RM ${appt['total_amount']}",
                            style: GoogleFonts.openSans(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1392AB)
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const Footer(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1392AB),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PharmacistListPage()),
          );
        },
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }
}
