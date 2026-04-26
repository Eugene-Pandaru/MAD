import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mad/utility.dart';
import 'package:mad/notification_service.dart';
import 'reminder_model.dart';

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

  Future<void> _toggleTaken(Reminder item) async {
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

  Future<void> _addOrUpdateReminder({Reminder? existing}) async {
    final nameController = TextEditingController(text: existing?.medicineName);
    final doseController = TextEditingController(text: existing?.dosage);
    String selectedFreq = existing?.frequency ?? 'Daily';
    
    TimeOfDay selectedTime = const TimeOfDay(hour: 9, minute: 0);
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
        selectedTime = TimeOfDay(hour: hour, minute: minute);
      } catch (e) {
        debugPrint("Time parse error: $e");
      }
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
                TextField(controller: nameController, decoration: const InputDecoration(labelText: "Medicine Name")),
                TextField(controller: doseController, decoration: const InputDecoration(labelText: "Dosage (e.g. 1 pill)")),
                const SizedBox(height: 15),
                ListTile(
                  title: const Text("Time"),
                  subtitle: Text(selectedTime.format(context)),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final picked = await showTimePicker(context: context, initialTime: selectedTime);
                    if (picked != null) setDialogState(() => selectedTime = picked);
                  },
                ),
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
                if (nameController.text.isNotEmpty) {
                  final userId = Utils.currentUser?['id'];
                  final reminderData = {
                    'medicine_name': nameController.text,
                    'dosage': doseController.text,
                    'reminder_time': selectedTime.format(context),
                    'frequency': selectedFreq,
                    'user_id': userId,
                    'is_taken': false,
                  };

                  try {
                    if (existing == null) {
                      await supabase.from('reminders').insert(reminderData);
                    } else {
                      await supabase.from('reminders').update(reminderData).eq('id', existing.id!);
                    }
                    _fetchReminders();
                    Navigator.pop(ctx);
                  } catch (e) {
                    Utils.snackbar(context, "Error: $e", color: Colors.red);
                  }
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
    final pending = _reminders.where((r) => !r.isTaken).toList();
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
                  _buildSectionHeader("Havent", Colors.redAccent),
                  ...pending.map((r) => _buildReminderTile(r)),
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

  Widget _buildReminderTile(Reminder item) {
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
        title: Text(item.medicineName, style: GoogleFonts.openSans(fontWeight: FontWeight.bold, decoration: item.isTaken ? TextDecoration.lineThrough : null)),
        subtitle: Text("${item.dosage} at ${item.time} (${item.frequency})"),
        trailing: _isEditMode ? const Icon(Icons.chevron_right) : null,
      ),
    );
  }
}
