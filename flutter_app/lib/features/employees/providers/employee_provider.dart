import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/employee_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';
import '../../auth/providers/auth_provider.dart';

final employeeServiceProvider = Provider<EmployeeService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return EmployeeService(apiClient: apiClient);
});

final employeesListProvider = FutureProvider<List<EmployeeModel>>((ref) async {
  final service = ref.watch(employeeServiceProvider);
  return service.getEmployees();
});

class EmployeeService {
  final ApiClient apiClient;

  EmployeeService({required this.apiClient});

  Future<List<EmployeeModel>> getEmployees({String? search, bool? activeOnly}) async {
    final queryParams = <String, dynamic>{};
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (activeOnly != null) queryParams['active'] = activeOnly;

    final response = await apiClient.dio.get(
      Endpoints.employees,
      queryParameters: queryParams,
    );

    final list = response.data as List<dynamic>;
    return list.map((e) => EmployeeModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<EmployeeModel> createEmployee({
    required String code,
    required String name,
    String? phone,
    String? designation,
    required String defaultShift,
    String? notes,
    double hourlyRateMorning = 0.0,
    double hourlyRateNight = 0.0,
  }) async {
    final response = await apiClient.dio.post(
      Endpoints.employees,
      data: {
        'employee_code': code.trim(),
        'full_name': name.trim(),
        'phone_number': phone?.trim().isEmpty == true ? null : phone?.trim(),
        'designation': designation?.trim().isEmpty == true ? null : designation?.trim(),
        'default_shift': defaultShift.toLowerCase(),
        'notes': notes?.trim().isEmpty == true ? null : notes?.trim(),
        'hourly_rate_morning': hourlyRateMorning,
        'hourly_rate_night': hourlyRateNight,
      },
    );

    return EmployeeModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<EmployeeModel> updateEmployee({
    required String id,
    required String name,
    String? phone,
    String? designation,
    required String defaultShift,
    String? notes,
    double? hourlyRateMorning,
    double? hourlyRateNight,
    bool? isActive,
  }) async {
    final response = await apiClient.dio.patch(
      Endpoints.employee(id),
      data: {
        'full_name': name.trim(),
        'phone_number': phone?.trim().isEmpty == true ? null : phone?.trim(),
        'designation': designation?.trim().isEmpty == true ? null : designation?.trim(),
        'default_shift': defaultShift.toLowerCase(),
        'notes': notes?.trim().isEmpty == true ? null : notes?.trim(),
        if (hourlyRateMorning != null) 'hourly_rate_morning': hourlyRateMorning,
        if (hourlyRateNight != null) 'hourly_rate_night': hourlyRateNight,
        if (isActive != null) 'is_active': isActive,
      },
    );

    return EmployeeModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> setEmployeeStatus({required String id, required bool isActive}) async {
    await apiClient.dio.patch(
      Endpoints.employeeStatus(id),
      data: {'is_active': isActive},
    );
  }
}
