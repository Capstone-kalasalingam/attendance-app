class AttendanceRowModel {
  final String employeeId;
  final String employeeCode;
  final String fullName;
  final String? designation;
  final String defaultShift;
  final String shift;
  final String? status; // 'present', 'absent', null
  final double hoursWorked;
  final String? workDescription;
  final String? recordId;
  final DateTime? lastUpdated;

  // Transient UI interaction states
  final bool isSaving;
  final bool saveSuccess;
  final String? saveError;

  AttendanceRowModel({
    required this.employeeId,
    required this.employeeCode,
    required this.fullName,
    this.designation,
    required this.defaultShift,
    required this.shift,
    this.status,
    required this.hoursWorked,
    this.workDescription,
    this.recordId,
    this.lastUpdated,
    this.isSaving = false,
    this.saveSuccess = false,
    this.saveError,
  });

  bool get isPresent => status == 'present';
  bool get isAbsent => status == 'absent';
  bool get isUnmarked => status == null;

  factory AttendanceRowModel.fromJson(Map<String, dynamic> json) {
    return AttendanceRowModel(
      employeeId: json['employee_id'] as String,
      employeeCode: json['employee_code'] as String,
      fullName: json['full_name'] as String,
      designation: json['designation'] as String?,
      defaultShift: (json['default_shift'] as String?)?.toLowerCase() ?? 'morning',
      shift: (json['shift'] as String?)?.toLowerCase() ?? 'morning',
      status: json['status'] as String?,
      hoursWorked: (json['hours_worked'] as num?)?.toDouble() ?? 0.0,
      workDescription: json['work_description'] as String?,
      recordId: json['record_id'] as String?,
      lastUpdated: json['last_updated'] != null
          ? DateTime.tryParse(json['last_updated'].toString())
          : null,
    );
  }

  AttendanceRowModel copyWith({
    String? shift,
    String? Function()? status,
    double? hoursWorked,
    String? Function()? workDescription,
    String? recordId,
    DateTime? lastUpdated,
    bool? isSaving,
    bool? saveSuccess,
    String? Function()? saveError,
  }) {
    return AttendanceRowModel(
      employeeId: employeeId,
      employeeCode: employeeCode,
      fullName: fullName,
      designation: designation,
      defaultShift: defaultShift,
      shift: shift ?? this.shift,
      status: status != null ? status() : this.status,
      hoursWorked: hoursWorked ?? this.hoursWorked,
      workDescription: workDescription != null ? workDescription() : this.workDescription,
      recordId: recordId ?? this.recordId,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isSaving: isSaving ?? this.isSaving,
      saveSuccess: saveSuccess ?? this.saveSuccess,
      saveError: saveError != null ? saveError() : this.saveError,
    );
  }
}

class AttendanceRecordModel {
  final String id;
  final String employeeId;
  final String attendanceDate;
  final String shift;
  final String status;
  final double hoursWorked;
  final String? workDescription;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AttendanceRecordModel({
    required this.id,
    required this.employeeId,
    required this.attendanceDate,
    required this.shift,
    required this.status,
    required this.hoursWorked,
    this.workDescription,
    this.createdAt,
    this.updatedAt,
  });

  bool get isPresent => status == 'present';
  bool get isAbsent => status == 'absent';

  factory AttendanceRecordModel.fromJson(Map<String, dynamic> json) {
    return AttendanceRecordModel(
      id: json['id']?.toString() ?? '',
      employeeId: json['employee_id']?.toString() ?? '',
      attendanceDate: json['attendance_date']?.toString() ?? '',
      shift: (json['shift'] as String?)?.toLowerCase() ?? 'morning',
      status: (json['status'] as String?)?.toLowerCase() ?? 'present',
      hoursWorked: (json['hours_worked'] as num?)?.toDouble() ?? 0.0,
      workDescription: json['work_description'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
    );
  }
}

class EmployeeRangeAggregate {
  final String employeeId;
  final String employeeCode;
  final String fullName;
  final String? designation;
  final String defaultShift;
  final int daysPresent;
  final int daysAbsent;
  final int morningShifts;
  final int nightShifts;
  final double totalHours;
  final int totalRangeDays;
  final List<AttendanceRecordModel> records;

  EmployeeRangeAggregate({
    required this.employeeId,
    required this.employeeCode,
    required this.fullName,
    this.designation,
    required this.defaultShift,
    required this.daysPresent,
    required this.daysAbsent,
    required this.morningShifts,
    required this.nightShifts,
    required this.totalHours,
    required this.totalRangeDays,
    required this.records,
  });

  double get attendancePercentage =>
      totalRangeDays > 0 ? (daysPresent / totalRangeDays) * 100 : 0.0;
  double get averageDailyHours =>
      daysPresent > 0 ? totalHours / daysPresent : 0.0;
}

