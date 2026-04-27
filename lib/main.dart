import 'package:flutter/material.dart';
import 'package:mad/startpage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:mad/notification_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mad/reminder_screen.dart';
import 'package:mad/utility.dart';

// 1. Create a global navigator key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Notifications singleton
  final notificationService = NotificationService();
  // 2. Pass the navigatorKey to the init method
  await notificationService.init(navKey: navigatorKey);
  
  // Request permissions for notifications
  await notificationService.requestPermissions();

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
      // 3. Set the navigatorKey in MaterialApp
      navigatorKey: navigatorKey,
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
    // Only show if user is logged in
    if (Utils.currentUser == null) return const SizedBox.shrink();

    final notificationService = NotificationService();
    final reminder = notificationService.overdueReminder;

    // If no medicine is due, show nothing
    if (reminder == null) return const SizedBox.shrink();

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: GestureDetector(
            onTap: () {
              // Jump to schedule screen
              final navigator = Navigator.of(context);
              notificationService.dismissReminder();
              navigator.push(MaterialPageRoute(builder: (context) => const ReminderScreen()));
            },
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF1392AB), width: 1.5),
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
                    const Icon(Icons.notification_important, color: Color(0xFF1392AB), size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Medicine Reminder",
                            style: GoogleFonts.openSans(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.black87
                            ),
                          ),
                          Text(
                            "Time for ${reminder.medicineName}. Tap to view schedule.",
                            style: GoogleFonts.openSans(fontSize: 12, color: Colors.black54),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
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
      ),
    );
  }
}
