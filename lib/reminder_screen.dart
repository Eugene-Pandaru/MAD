import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mad/utility.dart';
import 'package:mad/notification_service.dart';
import 'reminder_model.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});

  @override
  _ReminderScreenState createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  final supabase = Supabase.instance.client;
  List<Reminder> _reminders = [];
  bool _isLoading = true;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _fetchReminders();
  }

  Future<void> _fetchReminders() async {
    final userId = Utils.currentUser?['id'];
    if (userId == null) return;

    try {
      final data = await supabase
          .from('reminders')
          .select()
          .eq('user_id', userId)
          .order('created_at');
      
      if (mounted) {
        setState(() {
          _reminders = (data as List).map((json) => Reminder.fromJson(json)).toList();
          _isLoading = false;
        });
        
        // Schedule all reminders
        for (var reminder in _reminders) {
          if (!reminder.isTaken) {
            NotificationService().scheduleMedicineReminder(
              reminder.id!,
              reminder.medicineName,
              reminder.dosage,
              reminder.time,
              reminder.frequency,
            );
          }
        }
      }
    } catch (e) {
      debugPrint("Fetch error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool?> _showConfirmDialog(String title, String content) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: GoogleFonts.openSans(fontWeight: FontWeight.bold)),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              title.contains("Delete") ? "Delete" : "Confirm",
              style: TextStyle(color: title.contains("Delete") ? Colors.red : const Color(0xFF1392AB)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleTaken(Reminder item) async {
    final confirm = await _showConfirmDialog(
      item.isTaken ? "Mark as Haven't?" : "Mark as Taken?",
      "Are you sure you want to change the status of ${item.medicineName}?"
    );
    if (confirm != true) return;

    try {
      final newVal = !item.isTaken;
      await supabase.from('reminders').update({'is_taken': newVal}).eq('id', item.id!);
      
      if (newVal) {
        NotificationService().cancelNotification(item.id!);
      } else {
        NotificationService().scheduleMedicineReminder(
          item.id!, item.medicineName, item.dosage, item.time, item.frequency
        );
      }
      _fetchReminders();
    } catch (e) {
      debugPrint("Toggle error: $e");
    }
  }

  bool _isValidDosage(String value) {
    if (value.isEmpty) return false;
    return RegExp(r'\d').hasMatch(value);
  }

  Future<void> _addOrUpdateReminder({Reminder? existing}) async {
    final nameController = TextEditingController(text: existing?.medicineName);
    final doseController = TextEditingController(text: existing?.dosage);
    String selectedFreq = existing?.frequency ?? 'Daily';
    
    List<TimeOfDay> selectedTimes = [];
    
    if (existing != null) {
      try {
        final parts = existing.time.split(' ');
        final hm = parts[0].split(':');
        int hour = int.parse(hm[0]);
        int minute = int.parse(hm[1]);
        if (parts.length > 1) {
          if (parts[1] == 'PM' && hour < 12) hour += 12;
          if (parts[1] == 'AM' && hour == 12) hour = 0;
        }
        selectedTimes.add(TimeOfDay(hour: hour, minute: minute));
      } catch (e) {
        debugPrint("Time parse error: $e");
        selectedTimes.add(const TimeOfDay(hour: 9, minute: 0));
      }
    } else {
      selectedTimes.add(const TimeOfDay(hour: 9, minute: 0));
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existing == null ? "Add Medicine" : "Edit Medicine", style: GoogleFonts.openSans(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: "Medicine Name", hintText: "e.g. Aspirin")),
                TextField(
                  controller: doseController, 
                  decoration: const InputDecoration(labelText: "Dosage (Quantity required)", hintText: "e.g. 2 pills or 10ml"),
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Reminder Times:", style: TextStyle(fontWeight: FontWeight.bold)),
                    if (existing == null) 
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: Color(0xFF1392AB)),
                        onPressed: () async {
                          final picked = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 9, minute: 0));
                          if (picked != null) setDialogState(() => selectedTimes.add(picked));
                        },
                      ),
                  ],
                ),
                ...selectedTimes.asMap().entries.map((entry) {
                  int idx = entry.key;
                  TimeOfDay time = entry.value;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(time.format(context)),
                    trailing: selectedTimes.length > 1 ? IconButton(
                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                      onPressed: () => setDialogState(() => selectedTimes.removeAt(idx)),
                    ) : const Icon(Icons.access_time),
                    onTap: () async {
                      final picked = await showTimePicker(context: context, initialTime: time);
                      if (picked != null) setDialogState(() => selectedTimes[idx] = picked);
                    },
                  );
                }).toList(),
                const SizedBox(height: 10),
                DropdownButton<String>(
                  value: selectedFreq,
                  isExpanded: true,
                  items: ['Daily', 'Weekly'].map((String value) {
                    return DropdownMenuItem<String>(value: value, child: Text(value));
                  }).toList(),
                  onChanged: (val) => setDialogState(() => selectedFreq = val!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty) {
                  Utils.snackbar(context, "Please enter medicine name", color: Colors.orange);
                  return;
                }
                if (!_isValidDosage(doseController.text)) {
                  Utils.snackbar(context, "Please enter a valid dosage (must include quantity, e.g. 1 pill)", color: Colors.orange);
                  return;
                }

                final userId = Utils.currentUser?['id'];
                
                try {
                  if (existing == null) {
                    for (var time in selectedTimes) {
                      final reminderData = {
                        'medicine_name': nameController.text,
                        'dosage': doseController.text,
                        'reminder_time': time.format(context),
                        'frequency': selectedFreq,
                        'user_id': userId,
                        'is_taken': false,
                      };
                      await supabase.from('reminders').insert(reminderData);
                    }
                  } else {
                    final reminderData = {
                      'medicine_name': nameController.text,
                      'dosage': doseController.text,
                      'reminder_time': selectedTimes.first.format(context),
                      'frequency': selectedFreq,
                      'user_id': userId,
                    };
                    await supabase.from('reminders').update(reminderData).eq('id', existing.id!);
                  }
                  _fetchReminders();
                  Navigator.pop(ctx);
                } catch (e) {
                  Utils.snackbar(context, "Error: $e", color: Colors.red);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1392AB)),
              child: Text(existing == null ? "Add" : "Update", style: const TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _deleteReminder(int id) async {
    final confirm = await _showConfirmDialog(
      "Delete Medicine?",
      "Are you sure you want to delete this reminder permanently?"
    );
    if (confirm != true) return;

    try {
      await supabase.from('reminders').delete().match({'id': id});
      NotificationService().cancelNotification(id);
      _fetchReminders();
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use KL Timezone for validation as requested
    final now = tz.TZDateTime.now(tz.local);
    final DateFormat format = DateFormat.jm();

    final missed = _reminders.where((r) {
      if (r.isTaken) return false;
      try {
        final DateTime parsedTime = format.parse(r.time);
        final scheduledTimeToday = tz.TZDateTime(tz.local, now.year, now.month, now.day, parsedTime.hour, parsedTime.minute);
        return now.isAfter(scheduledTimeToday);
      } catch (e) {
        return false;
      }
    }).toList();

    final upcoming = _reminders.where((r) {
      if (r.isTaken) return false;
      try {
        final DateTime parsedTime = format.parse(r.time);
        final scheduledTimeToday = tz.TZDateTime(tz.local, now.year, now.month, now.day, parsedTime.hour, parsedTime.minute);
        return !now.isAfter(scheduledTimeToday);
      } catch (e) {
        return true;
      }
    }).toList();

    final taken = _reminders.where((r) => r.isTaken).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: AppBar(
        title: Text("Schedule", style: GoogleFonts.openSans(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1392AB),
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isEditMode ? Icons.check : Icons.edit),
            onPressed: () => setState(() => _isEditMode = !_isEditMode),
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1392AB)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (missed.isNotEmpty) ...[
                    _buildSectionHeader("Missed", Colors.red),
                    ...missed.map((r) => _buildReminderTile(r, isMissed: true)),
                    const SizedBox(height: 20),
                  ],
                  _buildSectionHeader("Upcoming", Colors.blueAccent),
                  ...upcoming.map((r) => _buildReminderTile(r)),
                  const SizedBox(height: 30),
                  _buildSectionHeader("Already Taken", Colors.green),
                  ...taken.map((r) => _buildReminderTile(r)),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrUpdateReminder(),
        backgroundColor: const Color(0xFF1392AB),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(width: 4, height: 20, color: color),
          const SizedBox(width: 10),
          Text(title, style: GoogleFonts.openSans(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildReminderTile(Reminder item, {bool isMissed = false}) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: _isEditMode ? () => _addOrUpdateReminder(existing: item) : null,
        leading: _isEditMode 
            ? IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteReminder(item.id!))
            : Checkbox(
                value: item.isTaken,
                activeColor: const Color(0xFF1392AB),
                onChanged: (_) => _toggleTaken(item),
              ),
        title: Text(
          item.medicineName, 
          style: GoogleFonts.openSans(
            fontWeight: FontWeight.bold, 
            decoration: item.isTaken ? TextDecoration.lineThrough : null,
            color: isMissed ? Colors.red : null,
          )
        ),
        subtitle: Text(
          "${item.dosage} at ${item.time} (${item.frequency})",
          style: TextStyle(color: isMissed ? Colors.red.withOpacity(0.7) : null),
        ),
        trailing: _isEditMode ? const Icon(Icons.chevron_right) : (isMissed ? const Icon(Icons.warning, color: Colors.red, size: 20) : null),
      ),
    );
  }
}
