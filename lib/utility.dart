import 'package:flutter/material.dart';

class Utils {
  /// 🔔 Snackbar
  static void snackbar(
    BuildContext context,
    String message, {
    Color color = Colors.black,
  }) {
    final messenger = ScaffoldMessenger.of(context);

    // ❌ Remove current snackbar
    messenger.clearSnackBars();

    // ✅ Show only latest
    messenger.showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
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
