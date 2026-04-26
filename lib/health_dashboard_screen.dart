import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mad/utility.dart';
import 'package:mad/notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'reminder_model.dart';
import 'reminder_screen.dart';

class HealthDashboard extends StatefulWidget {
  const HealthDashboard({super.key});

  @override
  State<HealthDashboard> createState() => _HealthDashboardState();
}

class _HealthDashboardState extends State<HealthDashboard> {
  final supabase = Supabase.instance.client;
  bool _isLoading = true;
  double _totalHoursLast7Days = 0;
  int _activeDaysLast7Days = 0;
  double _targetHours = 5.0; // Default target
  
  bool _remindersEnabled = true;

  @override
  void initState() {
    super.initState();
    _initDashboard();
  }

  Future<void> _initDashboard() async {
    await _fetchExerciseData();
    await _fetchTargetGoal();
    if (_remindersEnabled) {
      await _checkMedicineReminders();
    }
  }

  Future<void> _fetchTargetGoal() async {
    final userId = Utils.currentUser?['id'];
    if (userId == null) return;

    try {
      final data = await supabase
          .from('users_profile')
          .select('exercise_goal')
          .eq('id', userId)
          .maybeSingle();
      
      if (data != null && data['exercise_goal'] != null) {
        if (mounted) {
          setState(() {
            _targetHours = (data['exercise_goal'] as num).toDouble();
          });
        }
      }
    } catch (e) {
      debugPrint("Goal fetch error: $e");
    }
  }

  Future<void> _updateTargetGoal(double newGoal) async {
    final userId = Utils.currentUser?['id'];
    if (userId == null) return;

    try {
      await supabase.from('users_profile').update({'exercise_goal': newGoal}).eq('id', userId);
      setState(() => _targetHours = newGoal);
      if (mounted) Utils.snackbar(context, "Weekly goal updated!", color: Colors.green);
    } catch (e) {
      if (mounted) Utils.snackbar(context, "Failed to update goal", color: Colors.red);
    }
  }

  Future<void> _checkMedicineReminders() async {
    final userId = Utils.currentUser?['id'];
    if (userId == null) return;

    try {
      final data = await supabase.from('reminders').select().eq('user_id', userId);
      final reminders = (data as List).map((json) => Reminder.fromJson(json)).toList();
      
      if (reminders.isNotEmpty) {
        final medicine = reminders.first;
        await NotificationService().showNotification(
          0, 
          "Medicine Reminder", 
          "Don't forget your scheduled meds today!"
        );
      }
    } catch (e) {
      debugPrint("Error checking reminders: $e");
    }
  }

  Future<void> _fetchExerciseData() async {
    final userId = Utils.currentUser?['id'];
    if (userId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final last7Days = DateTime.now().subtract(const Duration(days: 7)).toIso8601String();
      final data = await supabase
          .from('exercise_records')
          .select()
          .eq('user_id', userId)
          .gte('date', last7Days);

      final records = (data as List).map((json) => ExerciseRecord.fromJson(json)).toList();

      double total = 0;
      Set<String> activeDays = {};
      for (var record in records) {
        total += record.hours;
        activeDays.add(DateFormat('yyyy-MM-dd').format(record.date));
      }

      if (mounted) {
        setState(() {
          _totalHoursLast7Days = total;
          _activeDaysLast7Days = activeDays.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching exercise: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addExercise(double hours) async {
    final userId = Utils.currentUser?['id'];
    if (userId == null) {
      Utils.snackbar(context, "Error: User session not found.", color: Colors.red);
      return;
    }

    try {
      await supabase.from('exercise_records').insert({
        'user_id': userId,
        'date': DateTime.now().toIso8601String(),
        'hours': hours,
      });
      
      _fetchExerciseData();
      if (mounted) Utils.snackbar(context, "Exercise recorded!", color: Colors.green);
    } catch (e) {
      debugPrint("DEBUG: Exercise insert failed. Error: $e");
      if (mounted) Utils.snackbar(context, "Failed to record exercise.", color: Colors.red);
    }
  }

  void _showGoalDialog() {
    final controller = TextEditingController(text: _targetHours.toString());
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Set Weekly Target", style: GoogleFonts.openSans(fontWeight: FontWeight.bold)),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: "Target hours per week",
              hintText: "e.g. 10.0",
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return "Please enter a target";
              final val = double.tryParse(value);
              if (val == null) return "Enter a valid number";
              if (val <= 0) return "Target must be positive";
              return null;
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final val = double.parse(controller.text);
                _updateTargetGoal(val);
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1392AB)),
            child: const Text("Save", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showExerciseDialog() {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Exercise Check-in", style: GoogleFonts.openSans(fontWeight: FontWeight.bold)),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: "Hours exercised today",
              hintText: "e.g. 1.5",
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return "Please enter hours";
              final hours = double.tryParse(value);
              if (hours == null) return "Enter a valid number (e.g. 1.5)";
              if (hours <= 0) return "Hours must be greater than zero";
              if (hours > 24) return "Value seems too high for a day";
              return null;
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final hours = double.parse(controller.text);
                _addExercise(hours);
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1392AB)),
            child: const Text("Save", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double progress = (_totalHoursLast7Days / _targetHours).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: AppBar(
        title: Text("Health Tracker", style: GoogleFonts.openSans(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1392AB),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1392AB)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle("Medicine Management"),
                  const SizedBox(height: 15),
                  _buildReminderActionCard(),
                  const SizedBox(height: 30),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionTitle("Weekly Exercise Goal"),
                      TextButton.icon(
                        onPressed: _showGoalDialog,
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text("Set Target"),
                      )
                    ],
                  ),
                  _buildGoalProgress(progress),
                  const SizedBox(height: 20),
                  _buildExerciseSummary(),
                  const SizedBox(height: 20),
                  
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _showExerciseDialog,
                      icon: const Icon(Icons.add_task),
                      label: const Text("Daily Exercise Check-in"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1392AB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                  _buildSectionTitle("Notification Settings"),
                  const SizedBox(height: 15),
                  _buildNotificationSettings(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: GoogleFonts.openSans(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87));
  }

  Widget _buildGoalProgress(double progress) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("${_totalHoursLast7Days.toStringAsFixed(1)} / $_targetHours hours", style: const TextStyle(fontWeight: FontWeight.bold)),
              Text("${(progress * 100).toInt()}%", style: const TextStyle(color: Color(0xFF1392AB), fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            color: const Color(0xFF1392AB),
            minHeight: 10,
            borderRadius: BorderRadius.circular(5),
          ),
          const SizedBox(height: 10),
          Text(progress >= 1.0 ? "Goal Reached! Amazing!" : "Keep moving to reach your goal!", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildReminderActionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          const Icon(Icons.alarm_on, size: 50, color: Color(0xFF1392AB)),
          const SizedBox(height: 10),
          Text("Keep track of your medications", style: GoogleFonts.openSans(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ReminderScreen())),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1392AB), foregroundColor: Colors.white),
              child: const Text("View & Edit All Reminders"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseSummary() {
    return Row(
      children: [
        Expanded(child: _buildSummaryCard("Total Hours", _totalHoursLast7Days.toStringAsFixed(1), Icons.timer_outlined, Colors.orange)),
        const SizedBox(width: 15),
        Expanded(child: _buildSummaryCard("Active Days", "$_activeDaysLast7Days", Icons.calendar_today_outlined, Colors.green)),
      ],
    );
  }

  Widget _buildSummaryCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 10),
          Text(value, style: GoogleFonts.openSans(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(label, style: GoogleFonts.openSans(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: SwitchListTile(
        title: Text("Medicine Reminders", style: GoogleFonts.openSans(fontSize: 15, fontWeight: FontWeight.w600)),
        subtitle: const Text("Receive alerts for scheduled medication"),
        value: _remindersEnabled,
        activeColor: const Color(0xFF1392AB),
        onChanged: (val) => setState(() => _remindersEnabled = val),
      ),
    );
  }
}
