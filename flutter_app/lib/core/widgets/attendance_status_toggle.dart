import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AttendanceStatusToggle extends StatelessWidget {
  final String? currentStatus; // 'present', 'absent', null
  final ValueChanged<String> onStatusChanged;
  final bool isSaving;

  const AttendanceStatusToggle({
    super.key,
    required this.currentStatus,
    required this.onStatusChanged,
    this.isSaving = false,
  });

  @override
  Widget build(BuildContext context) {
    final isPresent = currentStatus == 'present';
    final isAbsent = currentStatus == 'absent';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Present Pill Button
        _StatusButton(
          label: 'Present',
          icon: Icons.check_circle_rounded,
          isSelected: isPresent,
          activeColor: AppColors.presentEmerald,
          activeGlowColor: AppColors.presentGlow,
          onTap: isSaving ? null : () => onStatusChanged('present'),
        ),
        const SizedBox(width: 8),

        // Absent Pill Button
        _StatusButton(
          label: 'Absent',
          icon: Icons.cancel_rounded,
          isSelected: isAbsent,
          activeColor: AppColors.absentRose,
          activeGlowColor: AppColors.absentGlow,
          onTap: isSaving ? null : () => onStatusChanged('absent'),
        ),
      ],
    );
  }
}

class _StatusButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color activeColor;
  final Color activeGlowColor;
  final VoidCallback? onTap;

  const _StatusButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.activeColor,
    required this.activeGlowColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.22) : const Color(0x10FFFFFF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? activeColor : const Color(0x20FFFFFF),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeGlowColor,
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? activeColor : AppColors.textMuted,
            ),
            const SizedBox(width: 5),
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
