import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mad/utility.dart';
import 'package:mad/notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'reminder_model.dart';

class HealthDashboard extends StatefulWidget {
  const HealthDashboard({super.key});

  @override
  State<HealthDashboard> createState() => _HealthDashboardState();
}

class _HealthDashboardState extends State<HealthDashboard> {
  final supabase = Supabase.instance.client;
  List<ExerciseRecord> _exerciseRecords = [];
  bool _isLoading = true;
  double _totalHoursLast7Days = 0;
  int _activeDaysLast7Days = 0;
  
  // Notification Settings State
  bool _remindersEnabled = true;
  bool _exerciseAlerts = true;

  @override
  void initState() {
    super.initState();
    _initDashboard();
  }

  Future<void> _initDashboard() async {
    await _fetchExerciseData();
    if (_remindersEnabled) {
      await _checkMedicineReminders();
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
          "Time to take your ${medicine.medicineName} (${medicine.dosage})"
        );
      }
    } catch (e) {
      debugPrint("Error checking reminders: $e");
    }
  }

  Future<void> _fetchExerciseData() async {
    final userId = Utils.currentUser?['id'];
    if (userId == null) return;

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
          _exerciseRecords = records;
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
    if (userId == null) return;

    try {
      await supabase.from('exercise_records').insert({
        'user_id': userId,
        'date': DateTime.now().toIso8601String(),
        'hours': hours,
      });
      _fetchExerciseData();
      if (mounted) Utils.snackbar(context, "Exercise recorded!", color: Colors.green);
    } catch (e) {
      if (mounted) Utils.snackbar(context, "Failed to record exercise", color: Colors.red);
    }
  }

  void _showExerciseDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Exercise Check-in", style: GoogleFonts.openSans(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Hours exercised today", hintText: "e.g. 1.5"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              final hours = double.tryParse(controller.text);
              if (hours != null) {
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
                  _buildSectionTitle("Medicine Adherence"),
                  const SizedBox(height: 15),
                  _buildAdherenceChart(),
                  const SizedBox(height: 30),
                  
                  _buildSectionTitle("Exercise Summary (Last 7 Days)"),
                  const SizedBox(height: 15),
                  _buildExerciseSummary(),
                  const SizedBox(height: 20),
                  
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _showExerciseDialog,
                      icon: const Icon(Icons.add),
                      label: const Text("Daily Check-in"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1392AB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
    return Text(
      title,
      style: GoogleFonts.openSans(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
    );
  }

  Widget _buildAdherenceChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sectionsSpace: 0,
                centerSpaceRadius: 40,
                sections: [
                  PieChartSectionData(value: 85, color: const Color(0xFF1392AB), title: "85%", radius: 45, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  PieChartSectionData(value: 15, color: Colors.grey[300], title: "15%", radius: 45, titleStyle: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text("You're doing great! Keep it up.", style: GoogleFonts.openSans(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildExerciseSummary() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            "Total Hours",
            _totalHoursLast7Days.toStringAsFixed(1),
            Icons.timer_outlined,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _buildSummaryCard(
            "Active Days",
            "$_activeDaysLast7Days",
            Icons.calendar_today_outlined,
            Colors.green,
          ),
        ),
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
      child: Column(
        children: [
          SwitchListTile(
            title: Text("Medicine Reminders", style: GoogleFonts.openSans(fontSize: 15, fontWeight: FontWeight.w600)),
            subtitle: const Text("Receive alerts for scheduled medication"),
            value: _remindersEnabled,
            activeColor: const Color(0xFF1392AB),
            onChanged: (val) => setState(() => _remindersEnabled = val),
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: Text("Daily Health Tips", style: GoogleFonts.openSans(fontSize: 15, fontWeight: FontWeight.w600)),
            subtitle: const Text("Get occasional tips for staying healthy"),
            value: _exerciseAlerts,
            activeColor: const Color(0xFF1392AB),
            onChanged: (val) => setState(() => _exerciseAlerts = val),
          ),
        ],
      ),
    );
  }
}
