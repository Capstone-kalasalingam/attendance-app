import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/models/attendance_model.dart';
import '../../../core/models/summary_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';
import '../../auth/providers/auth_provider.dart';

class DashboardState {
  final DateTime selectedDate;
  final String searchQuery;
  final String quickFilter; // 'all', 'present', 'absent', 'morning', 'night'
  final List<AttendanceRowModel> allRows;
  final AttendanceSummaryModel? summary;
  final bool isLoading;
  final String? error;
  final Set<String> selectedEmployeeIds; // For bulk operations

  const DashboardState({
    required this.selectedDate,
    this.searchQuery = '',
    this.quickFilter = 'all',
    this.allRows = const [],
    this.summary,
    this.isLoading = false,
    this.error,
    this.selectedEmployeeIds = const {},
  });

  String get dateString => DateFormat('yyyy-MM-dd').format(selectedDate);
  String get formattedDateTitle => DateFormat('EEEE, MMM d, yyyy').format(selectedDate);

  List<AttendanceRowModel> get filteredRows {
    return allRows.where((row) {
      // 1. Search query filter
      if (searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        final matchName = row.fullName.toLowerCase().contains(q);
        final matchCode = row.employeeCode.toLowerCase().contains(q);
        final matchDesig = (row.designation ?? '').toLowerCase().contains(q);
        if (!matchName && !matchCode && !matchDesig) return false;
      }

      // 2. Quick filter
      switch (quickFilter) {
        case 'present':
          return row.isPresent;
        case 'absent':
          return row.isAbsent;
        case 'morning':
          return row.shift == 'morning';
        case 'night':
          return row.shift == 'night';
        case 'all':
        default:
          return true;
      }
    }).toList();
  }

  DashboardState copyWith({
    DateTime? selectedDate,
    String? searchQuery,
    String? quickFilter,
    List<AttendanceRowModel>? allRows,
    AttendanceSummaryModel? Function()? summary,
    bool? isLoading,
    String? Function()? error,
    Set<String>? selectedEmployeeIds,
  }) {
    return DashboardState(
      selectedDate: selectedDate ?? this.selectedDate,
      searchQuery: searchQuery ?? this.searchQuery,
      quickFilter: quickFilter ?? this.quickFilter,
      allRows: allRows ?? this.allRows,
      summary: summary != null ? summary() : this.summary,
      isLoading: isLoading ?? this.isLoading,
      error: error != null ? error() : this.error,
      selectedEmployeeIds: selectedEmployeeIds ?? this.selectedEmployeeIds,
    );
  }
}

final dashboardNotifierProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DashboardNotifier(apiClient: apiClient);
});

class DashboardNotifier extends StateNotifier<DashboardState> {
  final ApiClient apiClient;

  DashboardNotifier({required this.apiClient})
      : super(DashboardState(selectedDate: DateTime.now())) {
    loadData();
  }

  void setDate(DateTime date) {
    if (state.selectedDate.year == date.year &&
        state.selectedDate.month == date.month &&
        state.selectedDate.day == date.day) {
      return;
    }
    state = state.copyWith(selectedDate: date, selectedEmployeeIds: const {});
    loadData();
  }

  void setSearchQuery(String q) {
    state = state.copyWith(searchQuery: q);
  }

  void setQuickFilter(String filter) {
    state = state.copyWith(quickFilter: filter);
  }

  void toggleEmployeeSelection(String empId) {
    final updated = Set<String>.from(state.selectedEmployeeIds);
    if (updated.contains(empId)) {
      updated.remove(empId);
    } else {
      updated.add(empId);
    }
    state = state.copyWith(selectedEmployeeIds: updated);
  }

  void selectAllFiltered(bool select) {
    if (select) {
      final ids = state.filteredRows.map((r) => r.employeeId).toSet();
      state = state.copyWith(selectedEmployeeIds: ids);
    } else {
      state = state.copyWith(selectedEmployeeIds: const {});
    }
  }

  Future<void> loadData() async {
    state = state.copyWith(isLoading: true, error: () => null);
    final dateStr = state.dateString;

    try {
      final responses = await Future.wait([
        apiClient.dio.get(Endpoints.attendance, queryParameters: {'date': dateStr}),
        apiClient.dio.get(Endpoints.attendanceSummary, queryParameters: {'date': dateStr}),
      ]);

      final rowsData = responses[0].data as List;
      final rows = rowsData.map((e) => AttendanceRowModel.fromJson(e)).toList();

      final summary = AttendanceSummaryModel.fromJson(responses[1].data as Map<String, dynamic>);

      state = state.copyWith(
        allRows: rows,
        summary: () => summary,
        isLoading: false,
        error: () => null,
      );
    } catch (e) {
      final msg = ApiClient.parseError(e);
      state = state.copyWith(isLoading: false, error: () => msg);
    }
  }

  Future<void> markStatus(String employeeId, String newStatus) async {
    final index = state.allRows.indexWhere((r) => r.employeeId == employeeId);
    if (index == -1) return;

    final oldRow = state.allRows[index];

    // Determine default hours: if present and hours was 0, default to 8.0, else keep or 0 if absent
    double hours = oldRow.hoursWorked;
    if (newStatus == 'absent') {
      hours = 0.0;
    } else if (newStatus == 'present' && hours == 0) {
      hours = 8.0;
    }

    // Optimistic UI update
    final optimisticRow = oldRow.copyWith(
      status: () => newStatus,
      hoursWorked: hours,
      isSaving: true,
      saveError: () => null,
    );
    final updatedRows = List<AttendanceRowModel>.from(state.allRows);
    updatedRows[index] = optimisticRow;
    state = state.copyWith(allRows: updatedRows);

    try {
      final dateStr = state.dateString;
      final resp = await apiClient.dio.put(
        Endpoints.markAttendance(employeeId, dateStr, optimisticRow.shift),
        data: {
          'shift': optimisticRow.shift,
          'status': newStatus,
          'hours_worked': hours,
          'work_description': optimisticRow.workDescription,
        },
      );

      final savedRow = optimisticRow.copyWith(
        isSaving: false,
        saveSuccess: true,
        recordId: resp.data['id'] as String?,
        lastUpdated: DateTime.tryParse(resp.data['updated_at'].toString()),
      );
      final currentRows = List<AttendanceRowModel>.from(state.allRows);
      currentRows[index] = savedRow;
      state = state.copyWith(allRows: currentRows);

      // Refresh summary quietly
      _refreshSummary();
    } catch (e) {
      final errorMsg = ApiClient.parseError(e);
      // Rollback to old row with error message
      final rolledBackRow = oldRow.copyWith(
        isSaving: false,
        saveSuccess: false,
        saveError: () => errorMsg,
      );
      final currentRows = List<AttendanceRowModel>.from(state.allRows);
      currentRows[index] = rolledBackRow;
      state = state.copyWith(allRows: currentRows);
    }
  }

  Future<void> changeShift(String employeeId, String newShift) async {
    final index = state.allRows.indexWhere((r) => r.employeeId == employeeId);
    if (index == -1) return;

    final oldRow = state.allRows[index];
    if (oldRow.shift == newShift) return;

    // Optimistic update
    final optimisticRow = oldRow.copyWith(
      shift: newShift,
      isSaving: true,
      saveError: () => null,
    );
    final updatedRows = List<AttendanceRowModel>.from(state.allRows);
    updatedRows[index] = optimisticRow;
    state = state.copyWith(allRows: updatedRows);

    // If already marked, update on backend
    if (optimisticRow.status != null) {
      try {
        final dateStr = state.dateString;
        final resp = await apiClient.dio.put(
          Endpoints.markAttendance(employeeId, dateStr, newShift),
          data: {
            'shift': newShift,
            'status': optimisticRow.status,
            'hours_worked': optimisticRow.hoursWorked,
            'work_description': optimisticRow.workDescription,
          },
        );

        final savedRow = optimisticRow.copyWith(
          isSaving: false,
          saveSuccess: true,
          recordId: resp.data['id'] as String?,
          lastUpdated: DateTime.tryParse(resp.data['updated_at'].toString()),
        );
        final currentRows = List<AttendanceRowModel>.from(state.allRows);
        currentRows[index] = savedRow;
        state = state.copyWith(allRows: currentRows);

        _refreshSummary();
      } catch (e) {
        final errorMsg = ApiClient.parseError(e);
        final rolledBackRow = oldRow.copyWith(
          isSaving: false,
          saveSuccess: false,
          saveError: () => errorMsg,
        );
        final currentRows = List<AttendanceRowModel>.from(state.allRows);
        currentRows[index] = rolledBackRow;
        state = state.copyWith(allRows: currentRows);
      }
    } else {
      // Just local shift preference before marking
      optimisticRow.copyWith(isSaving: false);
      final currentRows = List<AttendanceRowModel>.from(state.allRows);
      currentRows[index] = optimisticRow.copyWith(isSaving: false);
      state = state.copyWith(allRows: currentRows);
    }
  }

  Future<void> updateHours(String employeeId, double hours) async {
    final index = state.allRows.indexWhere((r) => r.employeeId == employeeId);
    if (index == -1) return;

    final oldRow = state.allRows[index];
    if (oldRow.hoursWorked == hours) return;

    final optimisticRow = oldRow.copyWith(
      hoursWorked: hours,
      status: () => 'present',
      isSaving: true,
      saveError: () => null,
    );
    final updatedRows = List<AttendanceRowModel>.from(state.allRows);
    updatedRows[index] = optimisticRow;
    state = state.copyWith(allRows: updatedRows);

    try {
      final dateStr = state.dateString;
      final resp = await apiClient.dio.put(
        Endpoints.markAttendance(employeeId, dateStr, optimisticRow.shift),
        data: {
          'shift': optimisticRow.shift,
          'status': 'present',
          'hours_worked': hours,
          'work_description': optimisticRow.workDescription,
        },
      );

      final savedRow = optimisticRow.copyWith(
        isSaving: false,
        saveSuccess: true,
        recordId: resp.data['id'] as String?,
        lastUpdated: DateTime.tryParse(resp.data['updated_at'].toString()),
      );
      final currentRows = List<AttendanceRowModel>.from(state.allRows);
      currentRows[index] = savedRow;
      state = state.copyWith(allRows: currentRows);

      _refreshSummary();
    } catch (e) {
      final errorMsg = ApiClient.parseError(e);
      final rolledBackRow = oldRow.copyWith(
        isSaving: false,
        saveSuccess: false,
        saveError: () => errorMsg,
      );
      final currentRows = List<AttendanceRowModel>.from(state.allRows);
      currentRows[index] = rolledBackRow;
      state = state.copyWith(allRows: currentRows);
    }
  }

  Future<void> updateWorkDescription(String employeeId, String description) async {
    final index = state.allRows.indexWhere((r) => r.employeeId == employeeId);
    if (index == -1) return;

    final oldRow = state.allRows[index];
    final optimisticRow = oldRow.copyWith(
      workDescription: () => description.trim().isEmpty ? null : description.trim(),
      isSaving: true,
      saveError: () => null,
    );
    final updatedRows = List<AttendanceRowModel>.from(state.allRows);
    updatedRows[index] = optimisticRow;
    state = state.copyWith(allRows: updatedRows);

    try {
      final dateStr = state.dateString;
      final status = optimisticRow.status ?? 'present';
      final hours = status == 'absent' ? 0.0 : (optimisticRow.hoursWorked > 0 ? optimisticRow.hoursWorked : 8.0);

      final resp = await apiClient.dio.put(
        Endpoints.markAttendance(employeeId, dateStr, optimisticRow.shift),
        data: {
          'shift': optimisticRow.shift,
          'status': status,
          'hours_worked': hours,
          'work_description': description.trim().isEmpty ? null : description.trim(),
        },
      );

      final savedRow = optimisticRow.copyWith(
        status: () => status,
        hoursWorked: hours,
        isSaving: false,
        saveSuccess: true,
        recordId: resp.data['id'] as String?,
        lastUpdated: DateTime.tryParse(resp.data['updated_at'].toString()),
      );
      final currentRows = List<AttendanceRowModel>.from(state.allRows);
      currentRows[index] = savedRow;
      state = state.copyWith(allRows: currentRows);

      _refreshSummary();
    } catch (e) {
      final errorMsg = ApiClient.parseError(e);
      final rolledBackRow = oldRow.copyWith(
        isSaving: false,
        saveSuccess: false,
        saveError: () => errorMsg,
      );
      final currentRows = List<AttendanceRowModel>.from(state.allRows);
      currentRows[index] = rolledBackRow;
      state = state.copyWith(allRows: currentRows);
    }
  }

  Future<bool> bulkMarkSelectedPresent({double hours = 8.0}) async {
    final selectedIds = state.selectedEmployeeIds;
    if (selectedIds.isEmpty) return false;

    final items = <Map<String, dynamic>>[];
    for (final row in state.allRows) {
      if (selectedIds.contains(row.employeeId)) {
        items.add({
          'employee_id': row.employeeId,
          'shift': row.shift,
          'status': 'present',
          'hours_worked': hours,
          'work_description': row.workDescription,
        });
      }
    }

    try {
      state = state.copyWith(isLoading: true);
      await apiClient.dio.post(
        Endpoints.bulkAttendance,
        data: {
          'date': state.dateString,
          'items': items,
        },
      );

      state = state.copyWith(selectedEmployeeIds: const {});
      await loadData();
      return true;
    } catch (e) {
      final msg = ApiClient.parseError(e);
      state = state.copyWith(isLoading: false, error: () => msg);
      return false;
    }
  }

  Future<void> _refreshSummary() async {
    try {
      final response = await apiClient.dio.get(
        Endpoints.attendanceSummary,
        queryParameters: {'date': state.dateString},
      );
      final summary = AttendanceSummaryModel.fromJson(response.data as Map<String, dynamic>);
      state = state.copyWith(summary: () => summary);
    } catch (_) {}
  }
}
