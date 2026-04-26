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

  Future<void> _addReminder(String name, String dose, String time, String freq) async {
    final userId = Utils.currentUser?['id'];
    if (userId == null) return;

    try {
      await supabase.from('reminders').insert({
        'medicine_name': name,
        'dosage': dose,
        'reminder_time': time,
        'frequency': freq,
        'user_id': userId,
      });
      _fetchReminders();
      if (mounted) Utils.snackbar(context, "Reminder added!", color: Colors.green);
    } catch (e) {
      if (mounted) Utils.snackbar(context, "Failed to add reminder", color: Colors.red);
    }
  }

  Future<void> _deleteReminder(int id) async {
    try {
      await supabase.from('reminders').delete().match({'id': id});
      _fetchReminders();
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
        onPressed: () => _showAddDialog(),
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

  void _showAddDialog() {
    final nameController = TextEditingController();
    final doseController = TextEditingController();
    String selectedFreq = 'Daily';
    TimeOfDay selectedTime = const TimeOfDay(hour: 9, minute: 0);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text("Add Medicine", style: GoogleFonts.openSans(fontWeight: FontWeight.bold)),
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
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  _addReminder(nameController.text, doseController.text, selectedTime.format(context), selectedFreq);
                  Navigator.pop(ctx);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1392AB)),
              child: const Text("Add", style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }
}
