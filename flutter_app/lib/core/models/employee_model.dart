class EmployeeModel {
  final String id;
  final String employeeCode;
  final String fullName;
  final String? phoneNumber;
  final String? designation;
  final String defaultShift;
  final String? notes;
  final bool isActive;

  EmployeeModel({
    required this.id,
    required this.employeeCode,
    required this.fullName,
    this.phoneNumber,
    this.designation,
    required this.defaultShift,
    this.notes,
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
      'is_active': isActive,
    };
  }
}
