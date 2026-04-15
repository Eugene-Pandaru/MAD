import 'package:flutter/material.dart';
import 'package:mad/startpage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Stripe (Replace with your own publishable key)
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
    return const MaterialApp(
      home: Startpage(),
    );
  }
}
