import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
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
  double _targetHours = 5.0; 
  String _adherenceFilter = "Today";
  double _adherenceRate = 0;
  int _takenCount = 0;
  int _totalReminders = 0;

  @override
  void initState() {
    super.initState();
    _initDashboard();
  }

  Future<void> _initDashboard() async {
    await _fetchExerciseData();
    await _fetchTargetGoal();
    await _fetchAdherenceData();
  }

  Future<void> _fetchAdherenceData() async {
    final userId = Utils.currentUser?['id'];
    if (userId == null) return;

    try {
      // For a real production app, you'd have a 'logs' table.
      // For this prototype, we'll calculate adherence based on the current 'reminders' state.
      final data = await supabase
          .from('reminders')
          .select()
          .eq('user_id', userId)
          .eq('is_archived', false);

      final List<Reminder> reminders = (data as List).map((json) => Reminder.fromJson(json)).toList();
      
      int taken = reminders.where((r) => r.isTaken).length;
      int total = reminders.length;

      if (mounted) {
        setState(() {
          _totalReminders = total;
          _takenCount = taken;
          _adherenceRate = total == 0 ? 0 : (taken / total) * 100;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Adherence fetch error: $e");
      if (mounted) setState(() => _isLoading = false);
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
          _totalHoursLast7Days = total;
          _activeDaysLast7Days = activeDays.length;
        });
      }
    } catch (e) {
      debugPrint("Error fetching exercise: $e");
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
      if (mounted) Utils.snackbar(context, "Failed to record exercise.", color: Colors.red);
    }
  }

  void _showGoalDialog() {
    final controller = TextEditingController(text: _targetHours.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Set Weekly Target", style: GoogleFonts.openSans(fontWeight: FontWeight.bold)),
        content: TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: "Target hours per week"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              final input = controller.text.trim();
              final val = double.tryParse(input);
              if (val == null || val <= 0) {
                Utils.snackbar(context, "Error: Please enter a positive number", color: Colors.red);
                return;
              }
              _updateTargetGoal(val);
              Navigator.pop(ctx);
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Exercise Check-in", style: GoogleFonts.openSans(fontWeight: FontWeight.bold)),
        content: TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: "Hours exercised today"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              final input = controller.text.trim();
              final hours = double.tryParse(input);
              if (hours == null || hours <= 0 || hours > 24) {
                Utils.snackbar(context, "Error: Enter valid hours (0-24)", color: Colors.red);
                return;
              }
              _addExercise(hours);
              Navigator.pop(ctx);
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
          : RefreshIndicator(
              onRefresh: _initDashboard,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeaderWithFilter("Medicine Adherence", (val) {
                      setState(() => _adherenceFilter = val!);
                      // In a real app, re-fetch data based on val
                    }),
                    const SizedBox(height: 15),
                    _buildAdherenceChart(),
                    const SizedBox(height: 20),
                    
                    // Moved Medicine Schedule here
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
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeaderWithFilter(String title, ValueChanged<String?> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildSectionTitle(title),
        DropdownButton<String>(
          value: _adherenceFilter,
          underline: const SizedBox(),
          style: GoogleFonts.openSans(color: const Color(0xFF1392AB), fontWeight: FontWeight.bold),
          items: ["Today", "This Week", "This Month", "This Year"]
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: GoogleFonts.openSans(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87));
  }

  Widget _buildAdherenceChart() {
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
          SizedBox(
            height: 150,
            child: PieChart(
              PieChartData(
                sectionsSpace: 0,
                centerSpaceRadius: 40,
                sections: [
                  PieChartSectionData(
                    value: _adherenceRate,
                    color: const Color(0xFF1392AB),
                    title: "${_adherenceRate.toInt()}%",
                    radius: 50,
                    titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  PieChartSectionData(
                    value: 100 - _adherenceRate,
                    color: Colors.grey[200],
                    title: "",
                    radius: 40,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 15),
          Text(
            "Taken $_takenCount / $_totalReminders medicines",
            style: GoogleFonts.openSans(fontWeight: FontWeight.bold, color: Colors.black54),
          ),
          Text(
            _adherenceRate >= 80 ? "Excellent Adherence!" : "Keep it up!",
            style: GoogleFonts.openSans(fontSize: 12, color: _adherenceRate >= 80 ? Colors.green : Colors.orange),
          ),
        ],
      ),
    );
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
        ],
      ),
    );
  }

  Widget _buildReminderActionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF1392AB).withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        leading: const Icon(Icons.calendar_today, color: Color(0xFF1392AB)),
        title: Text("Medicine Schedule", style: GoogleFonts.openSans(fontWeight: FontWeight.bold)),
        subtitle: const Text("View your daily medication list"),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ReminderScreen())),
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
}
