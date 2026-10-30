import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/models/attendance_model.dart';
import '../../../core/models/summary_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';
import '../../auth/providers/auth_provider.dart';

class DashboardState {
  final DateTime selectedDate;
  final bool isRangeMode;
  final DateTime? startDate;
  final DateTime? endDate;
  final String searchQuery;
  final String quickFilter; // 'all', 'present', 'absent', 'morning', 'night'
  final List<AttendanceRowModel> allRows;
  final List<EmployeeRangeAggregate> rangeAggregates;
  final AttendanceSummaryModel? summary;
  final bool isLoading;
  final String? error;
  final Set<String> selectedEmployeeIds; // For bulk operations

  const DashboardState({
    required this.selectedDate,
    this.isRangeMode = false,
    this.startDate,
    this.endDate,
    this.searchQuery = '',
    this.quickFilter = 'all',
    this.allRows = const [],
    this.rangeAggregates = const [],
    this.summary,
    this.isLoading = false,
    this.error,
    this.selectedEmployeeIds = const {},
  });

  String get dateString => DateFormat('yyyy-MM-dd').format(selectedDate);
  String get formattedDateTitle => DateFormat('EEEE, MMM d, yyyy').format(selectedDate);
  String get compactDateTitle => DateFormat('EEE, MMM d, yyyy').format(selectedDate);

  String get rangeTitle {
    if (startDate == null || endDate == null) return formattedDateTitle;
    final f = DateFormat('MMM d, yyyy');
    if (startDate!.year == endDate!.year) {
      final fShort = DateFormat('MMM d');
      return '${fShort.format(startDate!)} – ${f.format(endDate!)}';
    }
    return '${f.format(startDate!)} – ${f.format(endDate!)}';
  }

  String get compactRangeTitle {
    if (startDate == null || endDate == null) return compactDateTitle;
    final s = startDate!;
    final e = endDate!;
    if (s.year == e.year) {
      if (s.month == e.month) {
        return '${DateFormat('MMM d').format(s)} – ${e.day}';
      }
      return '${DateFormat('MMM d').format(s)} – ${DateFormat('MMM d').format(e)}';
    }
    return "${DateFormat('MMM d, \'yy').format(s)} – ${DateFormat('MMM d, \'yy').format(e)}";
  }

  String get fullRangeTitle {
    if (startDate == null || endDate == null) return formattedDateTitle;
    final s = startDate!;
    final e = endDate!;
    if (s.year == e.year) {
      return '${DateFormat('MMMM d').format(s)} – ${DateFormat('MMMM d, yyyy').format(e)}';
    }
    return '${DateFormat('MMMM d, yyyy').format(s)} – ${DateFormat('MMMM d, yyyy').format(e)}';
  }

  int get totalRangeDays {
    if (startDate == null || endDate == null) return 1;
    return endDate!.difference(startDate!).inDays + 1;
  }

  List<EmployeeRangeAggregate> get filteredRangeAggregates {
    return rangeAggregates.where((agg) {
      if (searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        final matchName = agg.fullName.toLowerCase().contains(q);
        final matchCode = agg.employeeCode.toLowerCase().contains(q);
        final matchDesig = (agg.designation ?? '').toLowerCase().contains(q);
        if (!matchName && !matchCode && !matchDesig) return false;
      }
      switch (quickFilter) {
        case 'present':
          return agg.daysPresent > 0;
        case 'absent':
          return agg.daysAbsent > 0;
        case 'morning':
          return agg.morningShifts > 0;
        case 'night':
          return agg.nightShifts > 0;
        case 'all':
        default:
          return true;
      }
    }).toList();
  }

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
    bool? isRangeMode,
    DateTime? Function()? startDate,
    DateTime? Function()? endDate,
    String? searchQuery,
    String? quickFilter,
    List<AttendanceRowModel>? allRows,
    List<EmployeeRangeAggregate>? rangeAggregates,
    AttendanceSummaryModel? Function()? summary,
    bool? isLoading,
    String? Function()? error,
    Set<String>? selectedEmployeeIds,
  }) {
    return DashboardState(
      selectedDate: selectedDate ?? this.selectedDate,
      isRangeMode: isRangeMode ?? this.isRangeMode,
      startDate: startDate != null ? startDate() : this.startDate,
      endDate: endDate != null ? endDate() : this.endDate,
      searchQuery: searchQuery ?? this.searchQuery,
      quickFilter: quickFilter ?? this.quickFilter,
      allRows: allRows ?? this.allRows,
      rangeAggregates: rangeAggregates ?? this.rangeAggregates,
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
    if (!state.isRangeMode &&
        state.selectedDate.year == date.year &&
        state.selectedDate.month == date.month &&
        state.selectedDate.day == date.day) {
      return;
    }
    state = state.copyWith(
      isRangeMode: false,
      selectedDate: date,
      startDate: () => null,
      endDate: () => null,
      selectedEmployeeIds: const {},
    );
    loadData();
  }

  Future<void> setDateRange(DateTime start, DateTime end) async {
    state = state.copyWith(
      isRangeMode: true,
      startDate: () => start,
      endDate: () => end,
      selectedEmployeeIds: const {},
    );
    await loadRangeData();
  }

  void clearDateRange() {
    state = state.copyWith(
      isRangeMode: false,
      startDate: () => null,
      endDate: () => null,
      selectedEmployeeIds: const {},
    );
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
    if (state.isRangeMode) {
      return loadRangeData();
    }

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

  Future<void> loadRangeData() async {
    if (state.startDate == null || state.endDate == null) return;
    state = state.copyWith(isLoading: true, error: () => null);

    final startStr = DateFormat('yyyy-MM-dd').format(state.startDate!);
    final endStr = DateFormat('yyyy-MM-dd').format(state.endDate!);

    try {
      final responses = await Future.wait([
        apiClient.dio.get(Endpoints.employees),
        apiClient.dio.get(Endpoints.attendanceHistory, queryParameters: {
          'start_date': startStr,
          'end_date': endStr,
        }),
      ]);

      final employeesData = responses[0].data as List;
      final historyData = responses[1].data as List;

      final historyRecords = historyData
          .map((r) => AttendanceRecordModel.fromJson(r as Map<String, dynamic>))
          .toList();

      final Map<String, List<AttendanceRecordModel>> recordsByEmp = {};
      for (final rec in historyRecords) {
        recordsByEmp.putIfAbsent(rec.employeeId, () => []).add(rec);
      }

      final totalDays = state.totalRangeDays;
      int totalPresentRecords = 0;
      int totalAbsentRecords = 0;
      int totalMorningShifts = 0;
      int totalNightShifts = 0;
      double totalHoursSum = 0.0;

      final List<EmployeeRangeAggregate> aggregates = [];

      for (final empJson in employeesData) {
        final empMap = empJson as Map<String, dynamic>;
        final empId = empMap['id']?.toString() ?? '';
        final empCode = empMap['employee_code']?.toString() ?? '';
        final fullName = empMap['full_name']?.toString() ?? '';
        final designation = empMap['designation'] as String?;
        final defaultShift = (empMap['default_shift'] as String?)?.toLowerCase() ?? 'morning';

        final empRecords = recordsByEmp[empId] ?? [];

        int pCount = 0;
        int aCount = 0;
        int mShifts = 0;
        int nShifts = 0;
        double empHours = 0.0;

        for (final rec in empRecords) {
          if (rec.isPresent) {
            pCount++;
            empHours += rec.hoursWorked;
            if (rec.shift == 'morning') mShifts++;
            if (rec.shift == 'night') nShifts++;
          } else if (rec.isAbsent) {
            aCount++;
          }
        }

        totalPresentRecords += pCount;
        totalAbsentRecords += aCount;
        totalMorningShifts += mShifts;
        totalNightShifts += nShifts;
        totalHoursSum += empHours;

        aggregates.add(EmployeeRangeAggregate(
          employeeId: empId,
          employeeCode: empCode,
          fullName: fullName,
          designation: designation,
          defaultShift: defaultShift,
          daysPresent: pCount,
          daysAbsent: aCount,
          morningShifts: mShifts,
          nightShifts: nShifts,
          totalHours: empHours,
          totalRangeDays: totalDays,
          records: empRecords,
        ));
      }

      final activeCount = aggregates.length;
      final expectedPersonDays = activeCount * totalDays;
      final completion = expectedPersonDays > 0
          ? (totalPresentRecords / expectedPersonDays) * 100.0
          : 0.0;

      final summary = AttendanceSummaryModel(
        date: '$startStr to $endStr',
        totalActiveEmployees: activeCount,
        presentCount: totalPresentRecords,
        absentCount: totalAbsentRecords,
        notMarkedCount: (expectedPersonDays - totalPresentRecords - totalAbsentRecords).clamp(0, expectedPersonDays),
        morningShiftCount: totalMorningShifts,
        nightShiftCount: totalNightShifts,
        totalHoursWorked: totalHoursSum,
        completionPercentage: completion,
      );

      state = state.copyWith(
        isLoading: false,
        rangeAggregates: aggregates,
        summary: () => summary,
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
