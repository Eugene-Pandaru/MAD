///kh

class Reminder {
  final int? id;
  final String medicineName;
  final String dosage;
  final String time;
  final bool isTaken;

  Reminder({this.id, required this.medicineName, required this.dosage, required this.time, this.isTaken = false});

  // Convert for Supabase Insert
  Map<String, dynamic> toJson() => {
    'medicine_name': medicineName,
    'dosage': dosage,
    'reminder_time': time,
    'is_taken': isTaken,
  };

  // Create from Supabase Response
  factory Reminder.fromJson(Map<String, dynamic> json) => Reminder(
    id: json['id'],
    medicineName: json['medicine_name'],
    dosage: json['dosage'],
    time: json['reminder_time'],
    isTaken: json['is_taken'],
  );
}