class Endpoints {
  static const String login = '/api/v1/auth/login';
  static const String refresh = '/api/v1/auth/refresh';
  static const String logout = '/api/v1/auth/logout';
  static const String me = '/api/v1/auth/me';

  static const String employees = '/api/v1/employees';
  static String employee(String id) => '/api/v1/employees/$id';
  static String employeeStatus(String id) => '/api/v1/employees/$id/status';

  static const String attendance = '/api/v1/attendance';
  static const String attendanceSummary = '/api/v1/attendance/summary';
  static String markAttendance(String empId, String date, String shift) =>
      '/api/v1/attendance/$empId/$date/$shift';
  static const String bulkAttendance = '/api/v1/attendance/bulk';
  static const String attendanceHistory = '/api/v1/attendance/history';
  static const String attendancePayroll = '/api/v1/attendance/payroll';

  static const String exportExcel = '/api/v1/exports/attendance.xlsx';
}
