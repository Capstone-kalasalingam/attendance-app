import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/employee_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';

final employeeServiceProvider = Provider<EmployeeService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return EmployeeService(apiClient: apiClient, ref: ref);
});

class EmployeeService {
  final ApiClient apiClient;
  final Ref ref;

  EmployeeService({required this.apiClient, required this.ref});

  Future<EmployeeModel> createEmployee({
    required String code,
    required String name,
    String? phone,
    String? designation,
    required String defaultShift,
    String? notes,
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
      },
    );

    final newEmp = EmployeeModel.fromJson(response.data as Map<String, dynamic>);

    // Trigger dashboard refresh immediately
    ref.read(dashboardNotifierProvider.notifier).loadData();

    return newEmp;
  }

  Future<EmployeeModel> updateEmployee({
    required String id,
    required String name,
    String? phone,
    String? designation,
    required String defaultShift,
    String? notes,
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
        'is_active': isActive,
      },
    );

    final updatedEmp = EmployeeModel.fromJson(response.data as Map<String, dynamic>);
    ref.read(dashboardNotifierProvider.notifier).loadData();
    return updatedEmp;
  }

  Future<void> setEmployeeStatus({required String id, required bool isActive}) async {
    await apiClient.dio.patch(
      Endpoints.employeeStatus(id),
      data: {'is_active': isActive},
    );
    ref.read(dashboardNotifierProvider.notifier).loadData();
  }
}
