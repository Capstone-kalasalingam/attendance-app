import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_button.dart';
import '../../../../core/widgets/glass_panel.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../../auth/providers/auth_provider.dart';
import '../../employees/presentation/add_employee_dialog.dart';
import '../../employees/presentation/edit_employee_dialog.dart';
import '../../exports/presentation/export_excel_dialog.dart';
import '../providers/dashboard_provider.dart';
import 'widgets/attendance_row_widget.dart';
import 'widgets/dashboard_stats_header.dart';
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

  Future<void> _pickDate(DateTime currentDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF6366F1),
              onPrimary: Colors.white,
              surface: Color(0xFF1E1B4B),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      ref.read(dashboardNotifierProvider.notifier).setDate(picked);
    }
  }

  void _confirmBulkPresent(Set<String> selectedIds) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1B4B),
        title: const Text('Mark Selected Present?', style: TextStyle(color: Colors.white, fontFamily: 'Poppins')),
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
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.presentEmerald),
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
                  color: const Color(0xFF818CF8),
                  backgroundColor: const Color(0xFF1E1B4B),
                  onRefresh: () => dashboardNotifier.loadData(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Today's Live Summary Cards
                        DashboardStatsHeader(
                          summary: dashboardState.summary,
                          isLoading: dashboardState.isLoading,
                        ),
                        const SizedBox(height: 20),

                        // Search & Filter Toolbar
                        _buildFilterToolbar(dashboardState, dashboardNotifier),
                        const SizedBox(height: 16),

                        // Bulk Action Bar (if items selected)
                        if (dashboardState.selectedEmployeeIds.isNotEmpty) ...[
                          _buildBulkActionBar(dashboardState, dashboardNotifier),
                          const SizedBox(height: 14),
                        ],

                        // Main Attendance List
                        if (dashboardState.isLoading && dashboardState.allRows.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(40),
                            child: Center(
                              child: CircularProgressIndicator(color: Color(0xFF818CF8)),
                            ),
                          )
                        else if (dashboardState.error != null && dashboardState.allRows.isEmpty)
                          ErrorStateWidget(
                            message: dashboardState.error!,
                            onRetry: () => dashboardNotifier.loadData(),
                          )
                        else if (dashboardState.filteredRows.isEmpty)
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

  // TOP BAR
  Widget _buildTopBar(
    BuildContext context,
    AuthState authState,
    DashboardState dashboardState,
    DashboardNotifier dashboardNotifier,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 750;

        return GlassPanel(
          borderRadius: 0,
          borderWidth: 0,
          surfaceColor: const Color(0x220F172A),
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
                      const Text(
                        'ShiftMaster',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Attendance System',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textMuted.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),

                  // Date Picker & Navigator
                  if (!isMobile) ...[
                    _buildDateNavigator(dashboardState, dashboardNotifier),
                  ],

                  const Spacer(),

                  // Action Buttons
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
                      onPressed: () => ExportExcelDialog.show(context, dashboardState.selectedDate),
                      variant: GlassButtonVariant.secondary,
                    ),
                    const SizedBox(width: 12),
                  ],

                  // User Profile & Logout Menu
                  PopupMenuButton<String>(
                    tooltip: 'Admin profile',
                    color: const Color(0xFF1E1B4B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: AppColors.glassBorderStrong),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0x18FFFFFF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.glassBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircleAvatar(
                            radius: 12,
                            backgroundColor: Color(0xFF6366F1),
                            child: Icon(Icons.admin_panel_settings_rounded, size: 14, color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            authState.user?.username ?? 'Admin',
                            style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                          const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.textMuted),
                        ],
                      ),
                    ),
                    onSelected: (val) {
                      if (val == 'logout') {
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
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(Icons.logout_rounded, size: 16, color: AppColors.absentRoseLight),
                            SizedBox(width: 8),
                            Text('Logout', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.absentRoseLight)),
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
                    Expanded(child: _buildDateNavigator(dashboardState, dashboardNotifier)),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF818CF8)),
                      onPressed: () => AddEmployeeDialog.show(context),
                      tooltip: 'Add Employee',
                    ),
                    IconButton(
                      icon: const Icon(Icons.file_download_outlined, color: Colors.white),
                      onPressed: () => ExportExcelDialog.show(context, dashboardState.selectedDate),
                      tooltip: 'Export Excel',
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

  Widget _buildDateNavigator(DashboardState state, DashboardNotifier notifier) {
    final isToday = DateFormat('yyyy-MM-dd').format(state.selectedDate) ==
        DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0x18FFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, size: 20, color: Colors.white),
            splashRadius: 18,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
            onPressed: () {
              notifier.setDate(state.selectedDate.subtract(const Duration(days: 1)));
            },
          ),
          InkWell(
            onTap: () => _pickDate(state.selectedDate),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF818CF8)),
                  const SizedBox(width: 6),
                  Text(
                    state.formattedDateTitle,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.white),
            splashRadius: 18,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
            onPressed: () {
              notifier.setDate(state.selectedDate.add(const Duration(days: 1)));
            },
          ),
          if (!isToday) ...[
            const SizedBox(width: 4),
            InkWell(
              onTap: () => notifier.setDate(DateTime.now()),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Today',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF818CF8)),
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
        color: const Color(0x14FFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (q) => notifier.setSearchQuery(q),
        style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.white),
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        ),
      ),
    );
  }

  // BULK ACTION BAR
  Widget _buildBulkActionBar(DashboardState state, DashboardNotifier notifier) {
    final count = state.selectedEmployeeIds.length;

    return GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      borderRadius: 12,
      surfaceColor: const Color(0xFF1E1B4B).withOpacity(0.9),
      borderColor: const Color(0xFF818CF8),
      child: Row(
        children: [
          const Icon(Icons.checklist_rounded, color: Color(0xFF818CF8), size: 20),
          const SizedBox(width: 10),
          Text(
            '$count employees selected',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onPressed: () => _confirmBulkPresent(state.selectedEmployeeIds),
            icon: const Icon(Icons.check_rounded, size: 16),
            label: const Text('Mark Present (8h)', style: TextStyle(fontFamily: 'Poppins', fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
