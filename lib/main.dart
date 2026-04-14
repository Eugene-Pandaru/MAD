import 'package:flutter/material.dart';
import 'package:mad/startpage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
