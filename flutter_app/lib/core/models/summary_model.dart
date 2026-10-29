class AttendanceSummaryModel {
  final String date;
  final int totalActiveEmployees;
  final int presentCount;
  final int absentCount;
  final int notMarkedCount;
  final int morningShiftCount;
  final int nightShiftCount;
  final double totalHoursWorked;
  final double completionPercentage;

  AttendanceSummaryModel({
    required this.date,
    required this.totalActiveEmployees,
    required this.presentCount,
    required this.absentCount,
    required this.notMarkedCount,
    required this.morningShiftCount,
    required this.nightShiftCount,
    required this.totalHoursWorked,
    required this.completionPercentage,
  });

  factory AttendanceSummaryModel.empty(String date) {
    return AttendanceSummaryModel(
      date: date,
      totalActiveEmployees: 0,
      presentCount: 0,
      absentCount: 0,
      notMarkedCount: 0,
      morningShiftCount: 0,
      nightShiftCount: 0,
      totalHoursWorked: 0.0,
      completionPercentage: 0.0,
    );
  }

  factory AttendanceSummaryModel.fromJson(Map<String, dynamic> json) {
    return AttendanceSummaryModel(
      date: json['date'] as String? ?? '',
      totalActiveEmployees: json['total_active_employees'] as int? ?? 0,
      presentCount: json['present_count'] as int? ?? 0,
      absentCount: json['absent_count'] as int? ?? 0,
      notMarkedCount: json['not_marked_count'] as int? ?? 0,
      morningShiftCount: json['morning_shift_count'] as int? ?? 0,
      nightShiftCount: json['night_shift_count'] as int? ?? 0,
      totalHoursWorked: (json['total_hours_worked'] as num?)?.toDouble() ?? 0.0,
      completionPercentage: (json['completion_percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
