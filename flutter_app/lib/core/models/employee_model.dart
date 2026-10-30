class EmployeeModel {
  final String id;
  final String employeeCode;
  final String fullName;
  final String? phoneNumber;
  final String? designation;
  final String defaultShift;
  final String? notes;
  final double hourlyRateMorning;
  final double hourlyRateNight;
  final bool isActive;

  EmployeeModel({
    required this.id,
    required this.employeeCode,
    required this.fullName,
    this.phoneNumber,
    this.designation,
    required this.defaultShift,
    this.notes,
    this.hourlyRateMorning = 0.0,
    this.hourlyRateNight = 0.0,
    required this.isActive,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      id: json['id'] as String,
      employeeCode: json['employee_code'] as String,
      fullName: json['full_name'] as String,
      phoneNumber: json['phone_number'] as String?,
      designation: json['designation'] as String?,
      defaultShift: (json['default_shift'] as String?)?.toLowerCase() ?? 'morning',
      notes: json['notes'] as String?,
      hourlyRateMorning: (json['hourly_rate_morning'] as num?)?.toDouble() ?? 0.0,
      hourlyRateNight: (json['hourly_rate_night'] as num?)?.toDouble() ?? 0.0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employee_code': employeeCode,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'designation': designation,
      'default_shift': defaultShift,
      'notes': notes,
      'hourly_rate_morning': hourlyRateMorning,
      'hourly_rate_night': hourlyRateNight,
      'is_active': isActive,
    };
  }
}
