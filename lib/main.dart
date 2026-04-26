import 'package:flutter/material.dart';
import 'package:mad/startpage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:mad/notification_service.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Notifications singleton
  final notificationService = NotificationService();
  await notificationService.init();

  // Initialize Stripe
  Stripe.publishableKey = "pk_test_51TMTra30pXzuvOG7tMZOeoJVE9VWX2kSVS1wChjsAsQoJ4yPN8E6m15slIEQb2XwS0Z0efa88HP6cNk3q0Aqc3Td00Bxa7xhwE";

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://ilywlqeofnxhssnezpgw.supabase.co',
    anonKey: 'sb_publishable_wo6aVzrhzp3kt28xrld6ng_CC2eQyCB',
  );

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.openSansTextTheme(),
      ),
      home: const Startpage(),
      builder: (context, child) {
        return Stack(
          children: [
            if (child != null) child,
            // Listens to the global NotificationService singleton
            ListenableBuilder(
              listenable: NotificationService(),
              builder: (context, _) {
                return const GlobalReminderOverlay();
              },
            ),
          ],
        );
      },
    );
  }
}

class GlobalReminderOverlay extends StatelessWidget {
  const GlobalReminderOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final notificationService = NotificationService();
    final reminder = notificationService.overdueReminder;

    // If no medicine is due, show nothing
    if (reminder == null) return const SizedBox.shrink();

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Material(
            elevation: 10,
            borderRadius: BorderRadius.circular(15),
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFF1392AB), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1392AB).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.medication, color: Color(0xFF1392AB), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Medicine Time!",
                          style: GoogleFonts.openSans(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.black87
                          ),
                        ),
                        Text(
                          "${reminder.medicineName} - ${reminder.dosage}",
                          style: GoogleFonts.openSans(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        // Mark as taken in Supabase
                        await Supabase.instance.client
                            .from('reminders')
                            .update({'is_taken': true})
                            .eq('id', reminder.id!);

                        // Dismiss the overlay and check for the next one
                        notificationService.dismissReminder();
                        notificationService.checkOverdueReminders();
                      } catch (e) {
                        debugPrint("Error marking as taken: $e");
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1392AB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      minimumSize: const Size(60, 35),
                    ),
                    child: const Text("Eat", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                    onPressed: () => notificationService.dismissReminder(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
