class AttendanceRowModel {
  final String employeeId;
  final String employeeCode;
  final String fullName;
  final String? designation;
  final String defaultShift;
  final String shift;
  final String? status; // 'present', 'absent', null
  final double hoursWorked;
  final double hourlyRateMorning;
  final double hourlyRateNight;
  final double dailySalary;
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
    this.hourlyRateMorning = 0.0,
    this.hourlyRateNight = 0.0,
    this.dailySalary = 0.0,
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

  double get activeHourlyRate =>
      shift == 'night' ? hourlyRateNight : hourlyRateMorning;

  double get calculatedSalary =>
      isPresent ? (hoursWorked * activeHourlyRate) : 0.0;

  factory AttendanceRowModel.fromJson(Map<String, dynamic> json) {
    final status = json['status'] as String?;
    final hoursWorked = (json['hours_worked'] as num?)?.toDouble() ?? 0.0;
    final shift = (json['shift'] as String?)?.toLowerCase() ?? 'morning';
    final hourlyRateMorning = (json['hourly_rate_morning'] as num?)?.toDouble() ?? 0.0;
    final hourlyRateNight = (json['hourly_rate_night'] as num?)?.toDouble() ?? 0.0;
    final activeRate = shift == 'night' ? hourlyRateNight : hourlyRateMorning;
    final rawDailySalary = (json['daily_salary'] as num?)?.toDouble();
    final dailySalary = rawDailySalary ?? (status == 'present' ? hoursWorked * activeRate : 0.0);

    return AttendanceRowModel(
      employeeId: json['employee_id'] as String,
      employeeCode: json['employee_code'] as String,
      fullName: json['full_name'] as String,
      designation: json['designation'] as String?,
      defaultShift: (json['default_shift'] as String?)?.toLowerCase() ?? 'morning',
      shift: shift,
      status: status,
      hoursWorked: hoursWorked,
      hourlyRateMorning: hourlyRateMorning,
      hourlyRateNight: hourlyRateNight,
      dailySalary: dailySalary,
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
    double? hourlyRateMorning,
    double? hourlyRateNight,
    double? dailySalary,
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
      hourlyRateMorning: hourlyRateMorning ?? this.hourlyRateMorning,
      hourlyRateNight: hourlyRateNight ?? this.hourlyRateNight,
      dailySalary: dailySalary ?? this.dailySalary,
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

class EmployeeSalaryModel {
  final String employeeId;
  final String employeeCode;
  final String fullName;
  final String? designation;
  final double hourlyRateMorning;
  final double hourlyRateNight;
  final double morningHours;
  final double nightHours;
  final double totalHours;
  final double morningSalary;
  final double nightSalary;
  final double totalSalary;
  final int presentDays;
  final int absentDays;

  EmployeeSalaryModel({
    required this.employeeId,
    required this.employeeCode,
    required this.fullName,
    this.designation,
    required this.hourlyRateMorning,
    required this.hourlyRateNight,
    required this.morningHours,
    required this.nightHours,
    required this.totalHours,
    required this.morningSalary,
    required this.nightSalary,
    required this.totalSalary,
    required this.presentDays,
    required this.absentDays,
  });

  factory EmployeeSalaryModel.fromJson(Map<String, dynamic> json) {
    return EmployeeSalaryModel(
      employeeId: json['employee_id']?.toString() ?? '',
      employeeCode: json['employee_code']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      designation: json['designation'] as String?,
      hourlyRateMorning: (json['hourly_rate_morning'] as num?)?.toDouble() ?? 0.0,
      hourlyRateNight: (json['hourly_rate_night'] as num?)?.toDouble() ?? 0.0,
      morningHours: (json['morning_hours'] as num?)?.toDouble() ?? 0.0,
      nightHours: (json['night_hours'] as num?)?.toDouble() ?? 0.0,
      totalHours: (json['total_hours'] as num?)?.toDouble() ?? 0.0,
      morningSalary: (json['morning_salary'] as num?)?.toDouble() ?? 0.0,
      nightSalary: (json['night_salary'] as num?)?.toDouble() ?? 0.0,
      totalSalary: (json['total_salary'] as num?)?.toDouble() ?? 0.0,
      presentDays: (json['present_days'] as num?)?.toInt() ?? 0,
      absentDays: (json['absent_days'] as num?)?.toInt() ?? 0,
    );
  }
}

class PayrollOverviewModel {
  final String startDate;
  final String endDate;
  final double totalPayroll;
  final double totalHours;
  final double morningHours;
  final double nightHours;
  final int totalPresent;
  final List<EmployeeSalaryModel> employees;

  PayrollOverviewModel({
    required this.startDate,
    required this.endDate,
    required this.totalPayroll,
    required this.totalHours,
    required this.morningHours,
    required this.nightHours,
    required this.totalPresent,
    required this.employees,
  });

  factory PayrollOverviewModel.fromJson(Map<String, dynamic> json) {
    return PayrollOverviewModel(
      startDate: json['start_date']?.toString() ?? '',
      endDate: json['end_date']?.toString() ?? '',
      totalPayroll: (json['total_payroll'] as num?)?.toDouble() ?? 0.0,
      totalHours: (json['total_hours'] as num?)?.toDouble() ?? 0.0,
      morningHours: (json['morning_hours'] as num?)?.toDouble() ?? 0.0,
      nightHours: (json['night_hours'] as num?)?.toDouble() ?? 0.0,
      totalPresent: (json['total_present'] as num?)?.toInt() ?? 0,
      employees: (json['employees'] as List<dynamic>?)
              ?.map((e) => EmployeeSalaryModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
