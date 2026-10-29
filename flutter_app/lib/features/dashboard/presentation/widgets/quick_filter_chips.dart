import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class QuickFilterChips extends StatelessWidget {
  final String activeFilter;
  final ValueChanged<String> onFilterSelected;

  const QuickFilterChips({
    super.key,
    required this.activeFilter,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    final filters = [
      {'key': 'all', 'label': 'All Employees', 'icon': Icons.grid_view_rounded},
      {'key': 'present', 'label': 'Present', 'icon': Icons.check_circle_rounded},
      {'key': 'absent', 'label': 'Absent', 'icon': Icons.cancel_rounded},
      {'key': 'morning', 'label': 'Morning Shift', 'icon': Icons.wb_sunny_rounded},
      {'key': 'night', 'label': 'Night Shift', 'icon': Icons.nightlight_round},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final isSelected = activeFilter == f['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => onFilterSelected(f['key'] as String),
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF4F46E5) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF4F46E5) : AppColors.glassBorder,
                    width: 1,
                  ),
                  boxShadow: isSelected
                      ? const [
                          BoxShadow(
                            color: Color(0x334F46E5),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ]
                      : const [AppColors.cardShadow],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      f['icon'] as IconData,
                      size: 14,
                      color: isSelected ? Colors.white : AppColors.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      f['label'] as String,
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
            ),
          );
        }).toList(),
      ),
    );
  }
}
