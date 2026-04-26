import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Utils {
  /// 👤 Logged-in User Data
  static Map<String, dynamic>? currentUser;

  /// 🔔 Snackbar
  static void snackbar(
    BuildContext context,
    String message, {
    Color color = Colors.black,
  }) {
    final messenger = ScaffoldMessenger.of(context);

    // ❌ Remove current snackbar
    messenger.clearSnackBars();

    // ✅ Show only latest with Open Sans style and modern floating design
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.openSans(
            color: Colors.white, 
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating, // 👈 Floating behavior
        margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20), // 👈 Space from bottom/left/right
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15), // 👈 Curved borders
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// 🧹 Reset (clear all inputs)
  static void resetControllers(List<TextEditingController> controllers) {
    for (var controller in controllers) {
      controller.clear();
    }
  }

  /// ❌ Dispose controllers (prevent memory leak)
  static void disposeControllers(List<TextEditingController> controllers) {
    for (var controller in controllers) {
      controller.dispose();
    }
  }
}
