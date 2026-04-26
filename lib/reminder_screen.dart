import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mad/utility.dart';
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
      }
    } catch (e) {
      debugPrint("Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addOrUpdateReminder({Reminder? existing}) async {
    final nameController = TextEditingController(text: existing?.medicineName);
    final doseController = TextEditingController(text: existing?.dosage);
    String selectedFreq = existing?.frequency ?? 'Daily';
    
    // Parse existing time string to TimeOfDay if updating
    TimeOfDay selectedTime = const TimeOfDay(hour: 9, minute: 0);
    if (existing != null) {
      try {
        final parts = existing.time.split(' ');
        final hm = parts[0].split(':');
        int hour = int.parse(hm[0]);
        int minute = int.parse(hm[1]);
        if (parts[1] == 'PM' && hour < 12) hour += 12;
        if (parts[1] == 'AM' && hour == 12) hour = 0;
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
                  };

                  try {
                    if (existing == null) {
                      await supabase.from('reminders').insert(reminderData);
                    } else {
                      await supabase.from('reminders').update(reminderData).eq('id', existing.id!);
                    }
                    _fetchReminders();
                    Navigator.pop(ctx);
                    if (mounted) Utils.snackbar(context, existing == null ? "Reminder added!" : "Reminder updated!", color: Colors.green);
                  } catch (e) {
                    if (mounted) Utils.snackbar(context, "Operation failed", color: Colors.red);
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
      _fetchReminders();
      if (mounted) Utils.snackbar(context, "Reminder deleted", color: Colors.orange);
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Medicine Reminders", style: GoogleFonts.openSans(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1392AB),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1392AB)))
          : _reminders.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: _reminders.length,
                  itemBuilder: (context, index) {
                    final item = _reminders[index];
                    return _buildReminderCard(item);
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrUpdateReminder(),
        backgroundColor: const Color(0xFF1392AB),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.medical_services_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 15),
          Text("No reminders set yet", style: GoogleFonts.openSans(fontSize: 16, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildReminderCard(Reminder item) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        onTap: () => _addOrUpdateReminder(existing: item),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: const CircleAvatar(
          backgroundColor: Color(0xFF1392AB),
          child: Icon(Icons.medication, color: Colors.white),
        ),
        title: Text(item.medicineName, style: GoogleFonts.openSans(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("${item.dosage} • ${item.time}"),
            Text("Frequency: ${item.frequency}", style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () => _deleteReminder(item.id!),
        ),
      ),
    );
  }
}
