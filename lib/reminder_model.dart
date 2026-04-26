///kh

class Reminder {
  final int? id;
  final String medicineName;
  final String dosage;
  final String time;
  final bool isTaken;
  final String frequency; // 'Daily' or 'Weekly'

  Reminder({
    this.id,
    required this.medicineName,
    required this.dosage,
    required this.time,
    this.isTaken = false,
    this.frequency = 'Daily',
  });

  // Convert for Supabase Insert
  Map<String, dynamic> toJson() => {
    'medicine_name': medicineName,
    'dosage': dosage,
    'reminder_time': time,
    'is_taken': isTaken,
    'frequency': frequency,
  };

  // Create from Supabase Response
  factory Reminder.fromJson(Map<String, dynamic> json) => Reminder(
    id: json['id'],
    medicineName: json['medicine_name'] ?? '',
    dosage: json['dosage'] ?? '',
    time: json['reminder_time'] ?? '',
    isTaken: json['is_taken'] ?? false,
    frequency: json['frequency'] ?? 'Daily',
  );
}

class ExerciseRecord {
  final int? id;
  final DateTime date;
  final double hours;
  final String userId;

  ExerciseRecord({
    this.id,
    required this.date,
    required this.hours,
    required this.userId,
  });

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'hours': hours,
    'user_id': userId,
  };

  factory ExerciseRecord.fromJson(Map<String, dynamic> json) => ExerciseRecord(
    id: json['id'],
    date: DateTime.parse(json['date']),
    hours: (json['hours'] as num).toDouble(),
    userId: json['user_id'] ?? '',
  );
}
