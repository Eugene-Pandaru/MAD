import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mad/footer.dart';
import 'package:mad/pharmacist.dart'; // To navigate to new booking
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
      appBar: AppBar(
        title: const Text("My Appointments"),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),

      // --- 1. THE LIST OF APPOINTMENTS ---
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              // Using a stream so it updates instantly after booking
              stream: supabase
                  .from('appointments')
                  .stream(primaryKey: ['id'])
                  .order('created_at'),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final appointments = snapshot.data ?? [];

                if (appointments.isEmpty) {
                  return const Center(
                    child: Text("No appointments scheduled.",
                        style: TextStyle(color: Colors.grey)),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: appointments.length,
                  itemBuilder: (context, index) {
                    final appt = appointments[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 15),
                      child: ListTile(
                        // --- ADD THIS ONTAP HERE ---
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AppointmentDetailPage(appointment: appt),
                            ),
                          );
                        },
                        // ---------------------------
                        leading: const CircleAvatar(
                          backgroundColor: Colors.green,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text(appt['pharmacist_name'],
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("📅 ${appt['appointment_date']} \n⏰ ${appt['appointment_time']}"),
                        isThreeLine: true,
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text("RM ${appt['total_amount']}",
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                            const SizedBox(height: 5),
                            Text(appt['status'] ?? "Confirmed",
                                style: const TextStyle(fontSize: 10, color: Colors.blue)),
                          ],
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

      // --- 2. THE "+" BUTTON TO MAKE NEW APPOINTMENT ---
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
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