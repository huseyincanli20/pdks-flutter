class ShiftSchedule {
  final int id;
  final String title; // örn: Sabah Vardiyası (08:30 - 17:30)
  final String startTime; // "08:30"
  final String endTime;   // "17:30"
  final int breakMinutes; // 60
  final List<String> activeDays; // ["Pazartesi", "Salı", ...]
  final int assignedEmployeeCount;

  ShiftSchedule({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    this.breakMinutes = 60,
    required this.activeDays,
    this.assignedEmployeeCount = 0,
  });
}
