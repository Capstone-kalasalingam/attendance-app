import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/models/attendance_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_button.dart';
import '../../../core/widgets/glass_panel.dart';
import '../../dashboard/presentation/widgets/date_range_picker_dialog.dart';
import '../../exports/presentation/export_excel_dialog.dart';
import '../providers/salary_provider.dart';
import 'widgets/salary_employee_breakdown_dialog.dart';

class SalaryScreen extends ConsumerStatefulWidget {
  const SalaryScreen({super.key});

  @override
  ConsumerState<SalaryScreen> createState() => _SalaryScreenState();
}

class _SalaryScreenState extends ConsumerState<SalaryScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickCustomDateRange(SalaryState state, SalaryNotifier notifier) async {
    final result = await showAppDateRangePicker(
      context,
      currentSingleDate: state.endDate,
      currentRange: DateTimeRange(start: state.startDate, end: state.endDate),
      initialIsRange: true,
    );

    if (result != null && result.range != null) {
      notifier.setCustomRange(result.range!.start, result.range!.end);
    }
  }

  @override
  Widget build(BuildContext context) {
    final salaryState = ref.watch(salaryNotifierProvider);
    final salaryNotifier = ref.read(salaryNotifierProvider.notifier);

    final formatter = DateFormat('MMM d');
    final yearFormatter = DateFormat('yyyy');
    final startStr = formatter.format(salaryState.startDate);
    final endStr = formatter.format(salaryState.endDate);
    final yearStr = yearFormatter.format(salaryState.endDate);
    final dateRangeLabel = '$startStr – $endStr, $yearStr';

    final filteredList = salaryState.filteredEmployees;
    final payroll = salaryState.payroll;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.mainBackgroundGradient,
        ),
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            color: AppColors.primaryNavy,
            onRefresh: () => salaryNotifier.loadPayroll(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Top App Bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                gradient: AppColors.accentButtonGradient,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: const [AppColors.softGlow],
                              ),
                              child: const Icon(
                                Icons.currency_rupee_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Salary & Payroll',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                Text(
                                  'Shift rate calculations & hours',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        // Excel Export Button
                        GlassButton(
                          text: 'Export Excel',
                          icon: Icons.file_download_outlined,
                          variant: GlassButtonVariant.ghost,
                          height: 36,
                          onPressed: () => ExportExcelDialog.show(
                            context,
                            salaryState.endDate,
                            range: DateTimeRange(start: salaryState.startDate, end: salaryState.endDate),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Date Presets & Custom Date Picker Row
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _PresetChip(
                                label: 'This Month',
                                isSelected: salaryState.preset == SalaryPreset.thisMonth,
                                onTap: () => salaryNotifier.setPreset(SalaryPreset.thisMonth),
                              ),
                              const SizedBox(width: 8),
                              _PresetChip(
                                label: 'This Week',
                                isSelected: salaryState.preset == SalaryPreset.thisWeek,
                                onTap: () => salaryNotifier.setPreset(SalaryPreset.thisWeek),
                              ),
                              const SizedBox(width: 8),
                              _PresetChip(
                                label: 'Last 30 Days',
                                isSelected: salaryState.preset == SalaryPreset.last30Days,
                                onTap: () => salaryNotifier.setPreset(SalaryPreset.last30Days),
                              ),
                              const SizedBox(width: 8),
                              _PresetChip(
                                label: 'Custom Range',
                                isSelected: salaryState.preset == SalaryPreset.custom,
                                icon: Icons.date_range_rounded,
                                onTap: () => _pickCustomDateRange(salaryState, salaryNotifier),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Active Date Range Pill
                        InkWell(
                          onTap: () => _pickCustomDateRange(salaryState, salaryNotifier),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.glassBorder),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_month_rounded, size: 16, color: AppColors.primaryNavy),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    dateRangeLabel,
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                const Text(
                                  'Change',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.primaryNavy,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.primaryNavy),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 14)),

                // Payroll Overview KPI Cards
                if (payroll != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          // Total Payroll Hero Card
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.12),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'TOTAL PAYROLL',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white60,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '₹${payroll.totalPayroll.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 26,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${payroll.employees.length} Active Employees',
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 11,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.payments_rounded,
                                    color: Color(0xFF34D399),
                                    size: 28,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Hours & Shift Metrics Row
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: AppColors.morningAmberBg,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: AppColors.morningAmberBorder),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.wb_sunny_rounded, size: 20, color: AppColors.morningAmber),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${payroll.morningHours.toStringAsFixed(1)} hrs',
                                              style: const TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                            const Text(
                                              'Day Shift Hours',
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 10,
                                                color: AppColors.morningAmber,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: AppColors.nightVioletBg,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: AppColors.nightVioletBorder),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.nightlight_round, size: 20, color: AppColors.nightViolet),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${payroll.nightHours.toStringAsFixed(1)} hrs',
                                              style: const TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                            const Text(
                                              'Night Shift Hours',
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 10,
                                                color: AppColors.nightViolet,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 14)),

                // Search Bar & Employee Count
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.glassBorder),
                            ),
                            child: TextField(
                              controller: _searchController,
                              onChanged: salaryNotifier.setSearchQuery,
                              style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
                              decoration: const InputDecoration(
                                hintText: 'Search employee by name or ID...',
                                hintStyle: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.textMuted),
                                prefixIcon: Icon(Icons.search_rounded, size: 18, color: AppColors.textMuted),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                        ),
                        if (_searchController.text.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18, color: AppColors.textMuted),
                            onPressed: () {
                              _searchController.clear();
                              salaryNotifier.setSearchQuery('');
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 12)),

                // Employee Salary List
                if (salaryState.isLoading)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                    ),
                  )
                else if (filteredList.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(Icons.monetization_on_outlined, size: 48, color: AppColors.textMuted),
                            const SizedBox(height: 12),
                            const Text(
                              'No Employee Records Found',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              salaryState.searchQuery.isNotEmpty
                                  ? 'No employees match "${salaryState.searchQuery}".'
                                  : 'No attendance or salary logged for this period.',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 90), // Bottom padding for floating pill bar
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final emp = filteredList[index];
                          return _EmployeeSalaryCard(
                            emp: emp,
                            dateRangeText: dateRangeLabel,
                          );
                        },
                        childCount: filteredList.length,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;

  const _PresetChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryNavy : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryNavy : AppColors.glassBorder,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryNavy.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmployeeSalaryCard extends StatelessWidget {
  final EmployeeSalaryModel emp;
  final String dateRangeText;

  const _EmployeeSalaryCard({
    required this.emp,
    required this.dateRangeText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: GlassPanel(
        borderRadius: 16,
        surfaceColor: Colors.white,
        borderColor: AppColors.glassBorder,
        padding: const EdgeInsets.all(14),
        onTap: () => SalaryEmployeeBreakdownDialog.show(
          context,
          emp: emp,
          dateRangeText: dateRangeText,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Avatar, Code, Name, Total Salary Pill
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primaryNavy.withOpacity(0.08),
                  child: Text(
                    emp.fullName.isNotEmpty ? emp.fullName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        emp.fullName,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${emp.employeeCode} • ${emp.designation ?? "Staff"}',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                // Total Salary Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.presentEmeraldBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.presentEmeraldBorder),
                  ),
                  child: Text(
                    '₹${emp.totalSalary.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.presentEmerald,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 8),

            // Shifts & Rates Breakdown Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Day Shift Info
                Row(
                  children: [
                    const Icon(Icons.wb_sunny_rounded, size: 14, color: AppColors.morningAmber),
                    const SizedBox(width: 4),
                    Text(
                      '${emp.morningHours.toStringAsFixed(1)}h',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      ' @ ₹${emp.hourlyRateMorning.toStringAsFixed(0)}/h',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),

                // Night Shift Info
                Row(
                  children: [
                    const Icon(Icons.nightlight_round, size: 14, color: AppColors.nightViolet),
                    const SizedBox(width: 4),
                    Text(
                      '${emp.nightHours.toStringAsFixed(1)}h',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      ' @ ₹${emp.hourlyRateNight.toStringAsFixed(0)}/h',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),

                // Total hours & details button
                Row(
                  children: [
                    Text(
                      '${emp.totalHours.toStringAsFixed(1)}h total',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppColors.textMuted),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
