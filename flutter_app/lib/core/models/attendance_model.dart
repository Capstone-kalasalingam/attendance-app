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
