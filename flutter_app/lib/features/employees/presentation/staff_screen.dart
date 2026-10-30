import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/attendance_model.dart';
import '../../../core/models/employee_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_button.dart';
import '../../../core/widgets/glass_panel.dart';
import '../providers/employee_provider.dart';
import 'add_employee_dialog.dart';
import 'edit_employee_dialog.dart';

class StaffScreen extends ConsumerStatefulWidget {
  const StaffScreen({super.key});

  @override
  ConsumerState<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends ConsumerState<StaffScreen> {
  final _searchController = TextEditingController();
  bool? _activeFilter = true; // true = Active, false = Inactive, null = All

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(employeesListProvider);

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
            onRefresh: () async => ref.invalidate(employeesListProvider),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Header
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
                                Icons.people_alt_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Staff Management',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                Text(
                                  'Employees, hourly rates & shifts',
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
                        GlassButton(
                          text: 'Add Staff',
                          icon: Icons.person_add_rounded,
                          variant: GlassButtonVariant.primary,
                          height: 36,
                          onPressed: () => AddEmployeeDialog.show(context),
                        ),
                      ],
                    ),
                  ),
                ),

                // Search & Filter Bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        // Search bar
                        Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.glassBorder),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (_) => setState(() {}),
                            style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Search staff by name or code...',
                              hintStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.textMuted),
                              prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.textMuted),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear_rounded, size: 16),
                                      onPressed: () => setState(() => _searchController.clear()),
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Filter Chips
                        Row(
                          children: [
                            _StaffFilterChip(
                              label: 'Active Staff',
                              isSelected: _activeFilter == true,
                              onTap: () => setState(() => _activeFilter = true),
                            ),
                            const SizedBox(width: 8),
                            _StaffFilterChip(
                              label: 'Inactive',
                              isSelected: _activeFilter == false,
                              onTap: () => setState(() => _activeFilter = false),
                            ),
                            const SizedBox(width: 8),
                            _StaffFilterChip(
                              label: 'All Staff',
                              isSelected: _activeFilter == null,
                              onTap: () => setState(() => _activeFilter = null),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 14)),

                // Employee List
                employeesAsync.when(
                  loading: () => const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
                    ),
                  ),
                  error: (err, _) => SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                      child: Center(
                        child: Text(
                          'Error loading staff: $err',
                          style: const TextStyle(color: AppColors.absentRose, fontFamily: 'Poppins'),
                        ),
                      ),
                    ),
                  ),
                  data: (employees) {
                    final query = _searchController.text.toLowerCase().trim();
                    final filtered = employees.where((e) {
                      if (_activeFilter != null && e.isActive != _activeFilter) {
                        return false;
                      }
                      if (query.isNotEmpty) {
                        final name = e.fullName.toLowerCase();
                        final code = e.employeeCode.toLowerCase();
                        final des = (e.designation ?? '').toLowerCase();
                        if (!name.contains(query) && !code.contains(query) && !des.contains(query)) {
                          return false;
                        }
                      }
                      return true;
                    }).toList();

                    if (filtered.isEmpty) {
                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                          child: Center(
                            child: Column(
                              children: [
                                const Icon(Icons.people_outline_rounded, size: 48, color: AppColors.textMuted),
                                const SizedBox(height: 12),
                                const Text(
                                  'No Staff Members Found',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  query.isNotEmpty
                                      ? 'No staff matched "$query".'
                                      : 'Click "+ Add Staff" to add your first employee.',
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    return SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final emp = filtered[index];
                            return _StaffCard(emp: emp);
                          },
                          childCount: filtered.length,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StaffFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _StaffFilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryNavy : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryNavy : AppColors.glassBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _StaffCard extends ConsumerWidget {
  final EmployeeModel emp;

  const _StaffCard({required this.emp});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isNight = emp.defaultShift == 'night';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: GlassPanel(
        borderRadius: 16,
        surfaceColor: Colors.white,
        borderColor: AppColors.glassBorder,
        padding: const EdgeInsets.all(14),
        onTap: () {
          // Convert EmployeeModel to AttendanceRowModel for EditEmployeeDialog
          final dummyRow = AttendanceRowModel(
            employeeId: emp.id,
            employeeCode: emp.employeeCode,
            fullName: emp.fullName,
            designation: emp.designation,
            defaultShift: emp.defaultShift,
            shift: emp.defaultShift,
            hoursWorked: 0,
            hourlyRateMorning: emp.hourlyRateMorning,
            hourlyRateNight: emp.hourlyRateNight,
          );
          EditEmployeeDialog.show(context, dummyRow);
        },
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: emp.isActive
                      ? AppColors.primaryNavy.withOpacity(0.08)
                      : const Color(0xFFF1F5F9),
                  child: Text(
                    emp.fullName.isNotEmpty ? emp.fullName[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      color: emp.isActive ? AppColors.primaryNavy : AppColors.textMuted,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              emp.fullName,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: emp.isActive ? AppColors.textPrimary : AppColors.textMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isNight ? AppColors.nightVioletBg : AppColors.morningAmberBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isNight ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                                  size: 10,
                                  color: isNight ? AppColors.nightViolet : AppColors.morningAmber,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  isNight ? 'Night' : 'Morning',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: isNight ? AppColors.nightViolet : AppColors.morningAmber,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${emp.employeeCode} • ${emp.designation ?? "Staff"}${emp.phoneNumber != null ? " • ${emp.phoneNumber}" : ""}',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primaryNavy),
                  onPressed: () {
                    final dummyRow = AttendanceRowModel(
                      employeeId: emp.id,
                      employeeCode: emp.employeeCode,
                      fullName: emp.fullName,
                      designation: emp.designation,
                      defaultShift: emp.defaultShift,
                      shift: emp.defaultShift,
                      hoursWorked: 0,
                      hourlyRateMorning: emp.hourlyRateMorning,
                      hourlyRateNight: emp.hourlyRateNight,
                    );
                    EditEmployeeDialog.show(context, dummyRow);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 8),
            // Hourly Rates Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.wb_sunny_rounded, size: 13, color: AppColors.morningAmber),
                    const SizedBox(width: 4),
                    Text(
                      'Day Rate: ₹${emp.hourlyRateMorning.toStringAsFixed(2)}/hr',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.nightlight_round, size: 13, color: AppColors.nightViolet),
                    const SizedBox(width: 4),
                    Text(
                      'Night Rate: ₹${emp.hourlyRateNight.toStringAsFixed(2)}/hr',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
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
