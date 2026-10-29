import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ShiftSelector extends StatelessWidget {
  final String currentShift; // 'morning' or 'night'
  final ValueChanged<String> onShiftChanged;
  final bool isSaving;

  const ShiftSelector({
    super.key,
    required this.currentShift,
    required this.onShiftChanged,
    this.isSaving = false,
  });

  @override
  Widget build(BuildContext context) {
    final isMorning = currentShift.toLowerCase() == 'morning';

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.glassBorder, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ShiftOption(
            label: 'Day',
            icon: Icons.wb_sunny_rounded,
            isSelected: isMorning,
            activeColor: AppColors.morningAmber,
            activeBgColor: AppColors.morningAmberBg,
            activeBorderColor: AppColors.morningAmberBorder,
            onTap: isSaving ? null : () => onShiftChanged('morning'),
          ),
          _ShiftOption(
            label: 'Night',
            icon: Icons.nightlight_round,
            isSelected: !isMorning,
            activeColor: AppColors.nightViolet,
            activeBgColor: AppColors.nightVioletBg,
            activeBorderColor: AppColors.nightVioletBorder,
            onTap: isSaving ? null : () => onShiftChanged('night'),
          ),
        ],
      ),
    );
  }
}

class _ShiftOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color activeColor;
  final Color activeBgColor;
  final Color activeBorderColor;
  final VoidCallback? onTap;

  const _ShiftOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.activeColor,
    required this.activeBgColor,
    required this.activeBorderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? activeBgColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: activeBorderColor, width: 1)
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withOpacity(0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? activeColor : AppColors.textMuted,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? activeColor : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
