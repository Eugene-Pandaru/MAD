import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

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

    // ✅ Show only latest, use floating to prevent pushing UI
    messenger.showSnackBar(
      SnackBar(
        content: Text(message), 
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
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

  /// 🖼️ Upload Image to Supabase Storage
  static Future<String?> uploadImage({
    required File file,
    required String bucket,
    required String fileName,
  }) async {
    try {
      final supabase = Supabase.instance.client;
      
      // Upload the file
      final String path = await supabase.storage.from(bucket).upload(
        fileName,
        file,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
      );

      debugPrint("Upload Success: $path");

      // Return the public URL
      return supabase.storage.from(bucket).getPublicUrl(fileName);
    } on StorageException catch (e) {
      debugPrint("Supabase Storage Error: ${e.message}");
      return null;
    } catch (e) {
      debugPrint("Unexpected Upload Error: $e");
      return null;
    }
  }
}
