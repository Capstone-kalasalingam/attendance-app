import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_button.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../../../../core/widgets/server_settings_dialog.dart';
import '../../auth/providers/auth_provider.dart';
import '../../employees/presentation/add_employee_dialog.dart';
import '../../employees/presentation/edit_employee_dialog.dart';
import '../../exports/presentation/export_excel_dialog.dart';
import '../providers/dashboard_provider.dart';
import 'widgets/attendance_row_widget.dart';
import 'widgets/dashboard_stats_header.dart';
import 'widgets/date_range_picker_dialog.dart';
import 'widgets/employee_range_card.dart';
import 'widgets/quick_filter_chips.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openDateOrRangePicker(DashboardState state, DashboardNotifier notifier) async {
    final result = await showAppDateRangePicker(
      context,
      currentSingleDate: state.selectedDate,
      currentRange: state.isRangeMode && state.startDate != null && state.endDate != null
          ? DateTimeRange(start: state.startDate!, end: state.endDate!)
          : null,
      initialIsRange: state.isRangeMode,
    );

    if (result != null) {
      if (result.isRange && result.range != null) {
        notifier.setDateRange(result.range!.start, result.range!.end);
      } else if (!result.isRange && result.singleDate != null) {
        notifier.setDate(result.singleDate!);
      }
    }
  }

  void _confirmBulkPresent(Set<String> selectedIds) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.glassBorder),
        ),
        title: const Text(
          'Mark Selected Present?',
          style: TextStyle(color: AppColors.textPrimary, fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Mark ${selectedIds.length} selected employees as Present with standard 8.0 hours?',
          style: const TextStyle(color: AppColors.textSecondary, fontFamily: 'Poppins'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.presentEmerald,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(dashboardNotifierProvider.notifier).bulkMarkSelectedPresent(hours: 8.0);
            },
            child: const Text('Confirm Present'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final dashboardState = ref.watch(dashboardNotifierProvider);
    final dashboardNotifier = ref.read(dashboardNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.mainBackgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 1. TOP APP BAR
              _buildTopBar(context, authState, dashboardState, dashboardNotifier),

              // 2. MAIN SCROLLABLE DASHBOARD
              Expanded(
                child: RefreshIndicator(
                  color: const Color(0xFF4F46E5),
                  backgroundColor: Colors.white,
                  onRefresh: () => dashboardNotifier.loadData(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Today's Live Summary Cards (Zero overflow)
                        DashboardStatsHeader(
                          summary: dashboardState.summary,
                          isLoading: dashboardState.isLoading,
                          isRangeMode: dashboardState.isRangeMode,
                        ),
                        const SizedBox(height: 18),

                        // Search & Filter Toolbar
                        _buildFilterToolbar(dashboardState, dashboardNotifier),
                        const SizedBox(height: 16),

                        // Bulk Action Bar or Range Mode Info Banner
                        if (dashboardState.isRangeMode) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFC7D2FE)),
                              boxShadow: const [AppColors.cardShadow],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFFC7D2FE)),
                                  ),
                                  child: const Icon(Icons.insights_rounded, size: 18, color: Color(0xFF4F46E5)),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${dashboardState.totalRangeDays}-Day Attendance Report',
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF312E81),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        dashboardState.fullRangeTitle,
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF4F46E5),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () => dashboardNotifier.clearDateRange(),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFC7D2FE)),
                                      boxShadow: const [AppColors.cardShadow],
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.today_rounded, size: 13, color: Color(0xFF4F46E5)),
                                        SizedBox(width: 4),
                                        Text(
                                          'Today',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF4F46E5),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                        ] else if (dashboardState.selectedEmployeeIds.isNotEmpty) ...[
                          _buildBulkActionBar(dashboardState, dashboardNotifier),
                          const SizedBox(height: 14),
                        ],

                        // Main Attendance List
                        if (dashboardState.isLoading &&
                            ((dashboardState.isRangeMode && dashboardState.rangeAggregates.isEmpty) ||
                             (!dashboardState.isRangeMode && dashboardState.allRows.isEmpty)))
                          const Padding(
                            padding: EdgeInsets.all(40),
                            child: Center(
                              child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
                            ),
                          )
                        else if (dashboardState.error != null &&
                            ((dashboardState.isRangeMode && dashboardState.rangeAggregates.isEmpty) ||
                             (!dashboardState.isRangeMode && dashboardState.allRows.isEmpty)))
                          ErrorStateWidget(
                            message: dashboardState.error!,
                            onRetry: () => dashboardNotifier.loadData(),
                          )
                        else if (dashboardState.isRangeMode) ...[
                          if (dashboardState.filteredRangeAggregates.isEmpty)
                            EmptyStateWidget(
                              title: dashboardState.searchQuery.isNotEmpty
                                  ? 'No matching employees'
                                  : 'No records found',
                              description: 'No attendance data found in the selected date range.',
                              icon: Icons.date_range_rounded,
                              actionLabel: 'Reset to Today',
                              onAction: () => dashboardNotifier.clearDateRange(),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: dashboardState.filteredRangeAggregates.length,
                              itemBuilder: (context, index) {
                                final agg = dashboardState.filteredRangeAggregates[index];
                                return EmployeeRangeCard(aggregate: agg);
                              },
                            ),
                        ] else ...[
                          if (dashboardState.filteredRows.isEmpty)
                            EmptyStateWidget(
                              title: dashboardState.searchQuery.isNotEmpty
                                  ? 'No matching employees'
                                  : 'No employees found',
                              description: dashboardState.searchQuery.isNotEmpty
                                  ? 'No employee matched "${dashboardState.searchQuery}". Try clearing filters.'
                                  : 'Click "Add Employee" to create your first team member.',
                              icon: Icons.person_search_rounded,
                              actionLabel: dashboardState.searchQuery.isNotEmpty ? 'Clear Search' : 'Add Employee',
                              onAction: () {
                                if (dashboardState.searchQuery.isNotEmpty) {
                                  _searchController.clear();
                                  dashboardNotifier.setSearchQuery('');
                                } else {
                                  AddEmployeeDialog.show(context);
                                }
                              },
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: dashboardState.filteredRows.length,
                              itemBuilder: (context, index) {
                                final row = dashboardState.filteredRows[index];
                                final isSelected = dashboardState.selectedEmployeeIds.contains(row.employeeId);

                                return AttendanceRowWidget(
                                  row: row,
                                  isSelected: isSelected,
                                  onSelectChanged: (_) => dashboardNotifier.toggleEmployeeSelection(row.employeeId),
                                  onStatusChanged: (status) => dashboardNotifier.markStatus(row.employeeId, status),
                                  onShiftChanged: (shift) => dashboardNotifier.changeShift(row.employeeId, shift),
                                  onHoursChanged: (hours) => dashboardNotifier.updateHours(row.employeeId, hours),
                                  onDescriptionChanged: (desc) => dashboardNotifier.updateWorkDescription(row.employeeId, desc),
                                  onEditEmployee: () => EditEmployeeDialog.show(context, row),
                                );
                              },
                            ),
                        ],
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // TOP NAVIGATION & ACTION BAR
  Widget _buildTopBar(
    BuildContext context,
    AuthState authState,
    DashboardState dashboardState,
    DashboardNotifier dashboardNotifier,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 750;

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppColors.glassBorder)),
            boxShadow: [AppColors.cardShadow],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            children: [
              Row(
                children: [
                  // Logo & App Name
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: AppColors.accentButtonGradient,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [AppColors.softGlow],
                    ),
                    child: const Icon(Icons.access_time_filled_rounded, size: 20, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'ShiftMaster',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFC7D2FE), width: 0.8),
                            ),
                            child: const Text(
                              'v${AppConfig.appVersion}',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF4F46E5),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Text(
                        'Attendance System',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),

                  // Date Picker & Navigator (Desktop)
                  if (!isMobile) ...[
                    _buildDateNavigator(dashboardState, dashboardNotifier, isMobile: false),
                  ],

                  const Spacer(),

                  // Action Buttons (Desktop)
                  if (!isMobile) ...[
                    GlassButton(
                      text: 'Add Employee',
                      icon: Icons.person_add_alt_1_rounded,
                      onPressed: () => AddEmployeeDialog.show(context),
                      variant: GlassButtonVariant.primary,
                    ),
                    const SizedBox(width: 10),
                    GlassButton(
                      text: 'Export Excel',
                      icon: Icons.file_download_outlined,
                      onPressed: () => ExportExcelDialog.show(
                        context,
                        dashboardState.selectedDate,
                        range: dashboardState.isRangeMode && dashboardState.startDate != null && dashboardState.endDate != null
                            ? DateTimeRange(start: dashboardState.startDate!, end: dashboardState.endDate!)
                            : null,
                      ),
                      variant: GlassButtonVariant.secondary,
                    ),
                    const SizedBox(width: 12),
                  ],

                  // User Profile & Settings Menu
                  PopupMenuButton<String>(
                    tooltip: 'Admin profile',
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: AppColors.glassBorder),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.glassBorder),
                        boxShadow: const [AppColors.cardShadow],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircleAvatar(
                            radius: 12,
                            backgroundColor: Color(0xFF4F46E5),
                            child: Icon(Icons.admin_panel_settings_rounded, size: 14, color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            authState.user?.username ?? 'Admin',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.textMuted),
                        ],
                      ),
                    ),
                    onSelected: (val) {
                      if (val == 'server_settings') {
                        ServerSettingsDialog.show(context);
                      } else if (val == 'logout') {
                        ref.read(authNotifierProvider.notifier).logout();
                      }
                    },
                    itemBuilder: (ctx) => [
                      PopupMenuItem(
                        enabled: false,
                        child: Text(
                          'Signed in as ${authState.user?.username ?? "admin"} (${authState.user?.role ?? "admin"})',
                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textMuted),
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'server_settings',
                        child: Row(
                          children: [
                            Icon(Icons.dns_rounded, size: 16, color: Color(0xFF4F46E5)),
                            SizedBox(width: 8),
                            Text(
                              'Server Settings',
                              style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(Icons.logout_rounded, size: 16, color: AppColors.absentRose),
                            SizedBox(width: 8),
                            Text(
                              'Logout',
                              style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.absentRose),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Mobile Date & Action bar
              if (isMobile) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildDateNavigator(dashboardState, dashboardNotifier, isMobile: true)),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.person_add_alt_1_rounded, size: 18, color: Color(0xFF4F46E5)),
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      padding: EdgeInsets.zero,
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFEEF2FF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(color: Color(0xFFC7D2FE)),
                        ),
                      ),
                      tooltip: 'Add Employee',
                      onPressed: () => AddEmployeeDialog.show(context),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(Icons.file_download_outlined, size: 18, color: AppColors.textSecondary),
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      padding: EdgeInsets.zero,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(color: AppColors.glassBorder),
                        ),
                      ),
                      tooltip: 'Export Excel',
                      onPressed: () => ExportExcelDialog.show(
                        context,
                        dashboardState.selectedDate,
                        range: dashboardState.isRangeMode && dashboardState.startDate != null && dashboardState.endDate != null
                            ? DateTimeRange(start: dashboardState.startDate!, end: dashboardState.endDate!)
                            : null,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // DATE NAVIGATOR CAPSULE
  Widget _buildDateNavigator(
    DashboardState state,
    DashboardNotifier notifier, {
    required bool isMobile,
  }) {
    final now = DateTime.now();
    final isToday = !state.isRangeMode &&
        state.selectedDate.year == now.year &&
        state.selectedDate.month == now.month &&
        state.selectedDate.day == now.day;
    final dateLabel = state.isRangeMode
        ? (isMobile ? state.compactRangeTitle : state.rangeTitle)
        : (isMobile ? state.compactDateTitle : state.formattedDateTitle);

    final datePickerButton = InkWell(
      onTap: () => _openDateOrRangePicker(state, notifier),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 4 : 8, vertical: 4),
        child: Row(
          mainAxisSize: isMobile ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              state.isRangeMode ? Icons.date_range_rounded : Icons.calendar_today_rounded,
              size: isMobile ? 13 : 14,
              color: const Color(0xFF4F46E5),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                dateLabel,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: isMobile ? 11 : 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (state.isRangeMode) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${state.totalRangeDays}d',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4F46E5),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 2 : 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: state.isRangeMode ? const Color(0xFF818CF8) : AppColors.glassBorder),
        boxShadow: const [AppColors.cardShadow],
      ),
      child: Row(
        mainAxisSize: isMobile ? MainAxisSize.max : MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, size: 18, color: AppColors.textPrimary),
            splashRadius: 16,
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(minWidth: isMobile ? 22 : 28, minHeight: isMobile ? 24 : 28),
            onPressed: () {
              if (state.isRangeMode && state.startDate != null && state.endDate != null) {
                final days = state.totalRangeDays;
                notifier.setDateRange(
                  state.startDate!.subtract(Duration(days: days)),
                  state.endDate!.subtract(Duration(days: days)),
                );
              } else {
                notifier.setDate(state.selectedDate.subtract(const Duration(days: 1)));
              }
            },
          ),
          if (isMobile)
            Expanded(child: datePickerButton)
          else
            datePickerButton,
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textPrimary),
            splashRadius: 16,
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(minWidth: isMobile ? 22 : 28, minHeight: isMobile ? 24 : 28),
            onPressed: () {
              if (state.isRangeMode && state.startDate != null && state.endDate != null) {
                final days = state.totalRangeDays;
                notifier.setDateRange(
                  state.startDate!.add(Duration(days: days)),
                  state.endDate!.add(Duration(days: days)),
                );
              } else {
                notifier.setDate(state.selectedDate.add(const Duration(days: 1)));
              }
            },
          ),
          if (state.isRangeMode) ...[
            const SizedBox(width: 2),
            InkWell(
              onTap: () => notifier.clearDateRange(),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 5 : 7,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.close_rounded, size: 11, color: AppColors.absentRose),
                    if (!isMobile) ...[
                      const SizedBox(width: 2),
                      const Text(
                        'Day',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.absentRose,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ] else if (!isToday) ...[
            const SizedBox(width: 2),
            InkWell(
              onTap: () => notifier.setDate(DateTime.now()),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 5 : 7,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFC7D2FE)),
                ),
                child: Text(
                  'Today',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: isMobile ? 9 : 10,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF4F46E5),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // SEARCH AND FILTER TOOLBAR
  Widget _buildFilterToolbar(DashboardState state, DashboardNotifier notifier) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 650;

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSearchBox(notifier),
              const SizedBox(height: 10),
              QuickFilterChips(
                activeFilter: state.quickFilter,
                onFilterSelected: (f) => notifier.setQuickFilter(f),
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: _buildSearchBox(notifier)),
            const SizedBox(width: 16),
            QuickFilterChips(
              activeFilter: state.quickFilter,
              onFilterSelected: (f) => notifier.setQuickFilter(f),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchBox(DashboardNotifier notifier) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.glassBorder),
        boxShadow: const [AppColors.cardShadow],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (q) => notifier.setSearchQuery(q),
        style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: 'Search by employee name or ID...',
          hintStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.textSubtle),
          prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.textMuted),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 16, color: AppColors.textMuted),
                  onPressed: () {
                    _searchController.clear();
                    notifier.setSearchQuery('');
                  },
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        ),
      ),
    );
  }

  // BULK ACTION BAR
  Widget _buildBulkActionBar(DashboardState state, DashboardNotifier notifier) {
    final count = state.selectedEmployeeIds.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF818CF8)),
        boxShadow: const [AppColors.cardShadow],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 460;

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.checklist_rounded, color: Color(0xFF4F46E5), size: 16),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$count employee${count > 1 ? "s" : ""} selected',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => notifier.selectAllFiltered(false),
                      child: const Text(
                        'Deselect All',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.presentEmerald,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    elevation: 0,
                  ),
                  onPressed: () => _confirmBulkPresent(state.selectedEmployeeIds),
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: const Text(
                    'Mark Present (8h)',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          }

          return Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.checklist_rounded, color: Color(0xFF4F46E5), size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                '$count employee${count > 1 ? "s" : ""} selected',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => notifier.selectAllFiltered(false),
                child: const Text('Deselect All', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.presentEmerald,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  elevation: 0,
                ),
                onPressed: () => _confirmBulkPresent(state.selectedEmployeeIds),
                icon: const Icon(Icons.check_rounded, size: 16),
                label: const Text(
                  'Mark Present (8h)',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
