///kh

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'reminder_model.dart';

class ReminderScreen extends StatefulWidget {
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

  // READ - Get data from Supabase
  Future<void> _fetchReminders() async {
    try {
      final data = await supabase.from('reminders').select().order('created_at');
      setState(() {
        _reminders = (data as List).map((json) => Reminder.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // CREATE - Insert into Supabase
  Future<void> _addReminder(String name, String dose) async {
    await supabase.from('reminders').insert({
      'medicine_name': name,
      'dosage': dose,
      'reminder_time': '09:00 AM', // Simplified for demo
      'user_id': supabase.auth.currentUser!.id, // Assumes Member 1 handled Login
    });
    _fetchReminders(); // Refresh list
  }

  // DELETE - Remove from Supabase
  Future<void> _deleteReminder(int id) async {
    await supabase.from('reminders').delete().match({'id': id});
    _fetchReminders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Cloud Reminders (Supabase)")),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _reminders.length,
        itemBuilder: (context, index) {
          final item = _reminders[index];
          return ListTile(
            title: Text(item.medicineName),
            subtitle: Text(item.dosage),
            trailing: IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteReminder(item.id!),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(),
        child: Icon(Icons.add),
      ),
    );
  }

  // UI Dialog for adding medicine
  void _showAddDialog() {
    final nameController = TextEditingController();
    final doseController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Add Medicine"),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameController, decoration: InputDecoration(labelText: "Name")),
          TextField(controller: doseController, decoration: InputDecoration(labelText: "Dose")),
        ]),
        actions: [
          ElevatedButton(
            onPressed: () {
              _addReminder(nameController.text, doseController.text);
              Navigator.pop(ctx);
            },
            child: Text("Add"),
          )
        ],
      ),
    );
  }
}