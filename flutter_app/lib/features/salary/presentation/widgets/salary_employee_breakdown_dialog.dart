import 'package:flutter/material.dart';
import '../../../../core/models/attendance_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_button.dart';
import '../../../../core/widgets/glass_dialog.dart';

class SalaryEmployeeBreakdownDialog extends StatelessWidget {
  final EmployeeSalaryModel emp;
  final String dateRangeText;

  const SalaryEmployeeBreakdownDialog({
    super.key,
    required this.emp,
    required this.dateRangeText,
  });

  static Future<void> show(
    BuildContext context, {
    required EmployeeSalaryModel emp,
    required String dateRangeText,
  }) {
    return GlassDialog.show(
      context: context,
      title: 'Salary Details — ${emp.fullName}',
      titleIcon: Icons.payments_outlined,
      content: SalaryEmployeeBreakdownDialog(
        emp: emp,
        dateRangeText: dateRangeText,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Range & Profile Header
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primaryNavy.withOpacity(0.1),
                child: Text(
                  emp.fullName.isNotEmpty ? emp.fullName[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryNavy,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
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
                    ),
                    Text(
                      '${emp.employeeCode} • ${emp.designation ?? "Staff"}',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: Text(
                  dateRangeText,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Total Salary Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF047857), Color(0xFF10B981)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TOTAL SALARY EARNED',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Based on logged hours',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Text(
                '₹${emp.totalSalary.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Shift Rate & Hours Breakdown
        const Text(
          'Shift Breakdown',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),

        // Day Shift Card
        _ShiftBreakdownTile(
          icon: Icons.wb_sunny_rounded,
          iconColor: AppColors.morningAmber,
          bgColor: AppColors.morningAmberBg,
          borderColor: AppColors.morningAmberBorder,
          shiftTitle: 'Day Shift (Morning)',
          hours: emp.morningHours,
          rate: emp.hourlyRateMorning,
          totalEarned: emp.morningSalary,
        ),
        const SizedBox(height: 8),

        // Night Shift Card
        _ShiftBreakdownTile(
          icon: Icons.nightlight_round,
          iconColor: AppColors.nightViolet,
          bgColor: AppColors.nightVioletBg,
          borderColor: AppColors.nightVioletBorder,
          shiftTitle: 'Night Shift',
          hours: emp.nightHours,
          rate: emp.hourlyRateNight,
          totalEarned: emp.nightSalary,
        ),
        const SizedBox(height: 14),

        // Days Attended Statistics
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(label: 'Total Hours', value: '${emp.totalHours.toStringAsFixed(1)}h'),
              Container(width: 1, height: 28, color: AppColors.glassBorder),
              _StatItem(label: 'Present Days', value: '${emp.presentDays} days', valueColor: AppColors.presentEmerald),
              Container(width: 1, height: 28, color: AppColors.glassBorder),
              _StatItem(label: 'Absent Days', value: '${emp.absentDays} days', valueColor: emp.absentDays > 0 ? AppColors.absentRose : AppColors.textMuted),
            ],
          ),
        ),
        const SizedBox(height: 20),

        Align(
          alignment: Alignment.centerRight,
          child: GlassButton(
            text: 'Close',
            variant: GlassButtonVariant.ghost,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ],
    );
  }
}

class _ShiftBreakdownTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final Color borderColor;
  final String shiftTitle;
  final double hours;
  final double rate;
  final double totalEarned;

  const _ShiftBreakdownTile({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.borderColor,
    required this.shiftTitle,
    required this.hours,
    required this.rate,
    required this.totalEarned,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shiftTitle,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: iconColor,
                  ),
                ),
                Text(
                  '${hours.toStringAsFixed(1)} hrs × ₹${rate.toStringAsFixed(2)}/hr',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '₹${totalEarned.toStringAsFixed(2)}',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _StatItem({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 10,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}
