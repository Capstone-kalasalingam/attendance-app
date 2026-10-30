import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/models/attendance_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';
import '../../auth/providers/auth_provider.dart';

enum SalaryPreset {
  thisMonth,
  thisWeek,
  last30Days,
  custom,
}

class SalaryState {
  final SalaryPreset preset;
  final DateTime startDate;
  final DateTime endDate;
  final PayrollOverviewModel? payroll;
  final String searchQuery;
  final bool isLoading;
  final String? errorMessage;

  const SalaryState({
    required this.preset,
    required this.startDate,
    required this.endDate,
    this.payroll,
    this.searchQuery = '',
    this.isLoading = false,
    this.errorMessage,
  });

  SalaryState copyWith({
    SalaryPreset? preset,
    DateTime? startDate,
    DateTime? endDate,
    PayrollOverviewModel? payroll,
    String? searchQuery,
    bool? isLoading,
    String? Function()? errorMessage,
  }) {
    return SalaryState(
      preset: preset ?? this.preset,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      payroll: payroll ?? this.payroll,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }

  List<EmployeeSalaryModel> get filteredEmployees {
    if (payroll == null) return [];
    if (searchQuery.trim().isEmpty) return payroll!.employees;

    final q = searchQuery.toLowerCase().trim();
    return payroll!.employees.where((emp) {
      final name = emp.fullName.toLowerCase();
      final code = emp.employeeCode.toLowerCase();
      final des = (emp.designation ?? '').toLowerCase();
      return name.contains(q) || code.contains(q) || des.contains(q);
    }).toList();
  }
}

class SalaryNotifier extends StateNotifier<SalaryState> {
  final ApiClient apiClient;

  SalaryNotifier({required this.apiClient})
      : super(_initialState()) {
    loadPayroll();
  }

  static SalaryState _initialState() {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    return SalaryState(
      preset: SalaryPreset.thisMonth,
      startDate: firstDayOfMonth,
      endDate: now,
    );
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setPreset(SalaryPreset preset) {
    final now = DateTime.now();
    DateTime start;
    DateTime end = now;

    switch (preset) {
      case SalaryPreset.thisMonth:
        start = DateTime(now.year, now.month, 1);
        break;
      case SalaryPreset.thisWeek:
        final weekday = now.weekday; // 1 = Monday
        start = now.subtract(Duration(days: weekday - 1));
        break;
      case SalaryPreset.last30Days:
        start = now.subtract(const Duration(days: 29));
        break;
      case SalaryPreset.custom:
        start = state.startDate;
        end = state.endDate;
        break;
    }

    state = state.copyWith(
      preset: preset,
      startDate: start,
      endDate: end,
    );
    loadPayroll();
  }

  void setCustomRange(DateTime start, DateTime end) {
    state = state.copyWith(
      preset: SalaryPreset.custom,
      startDate: start,
      endDate: end,
    );
    loadPayroll();
  }

  Future<void> loadPayroll() async {
    state = state.copyWith(isLoading: true, errorMessage: () => null);

    final formatter = DateFormat('yyyy-MM-dd');
    final startStr = formatter.format(state.startDate);
    final endStr = formatter.format(state.endDate);

    try {
      final response = await apiClient.dio.get(
        Endpoints.attendancePayroll,
        queryParameters: {
          'start_date': startStr,
          'end_date': endStr,
        },
      );

      final payroll = PayrollOverviewModel.fromJson(response.data as Map<String, dynamic>);
      state = state.copyWith(
        payroll: payroll,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: () => ApiClient.parseError(e),
      );
    }
  }
}

final salaryNotifierProvider =
    StateNotifierProvider<SalaryNotifier, SalaryState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SalaryNotifier(apiClient: apiClient);
});
