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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        color: isPresent
            ? AppColors.presentBg
            : (isAbsent ? AppColors.absentBg : const Color(0xFFF1F5F9)),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPresent
              ? AppColors.presentBorder
              : (isAbsent ? AppColors.absentBorder : AppColors.glassBorder),
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Absent Label
          InkWell(
            onTap: isSaving ? null : () => onStatusChanged('absent'),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                'Absent',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: isAbsent ? FontWeight.w700 : FontWeight.w500,
                  color: isAbsent ? AppColors.absentRose : AppColors.textSubtle,
                ),
              ),
            ),
          ),

          // Sliding Toggle Track & Thumb
          InkWell(
            onTap: isSaving
                ? null
                : () {
                    onStatusChanged(isPresent ? 'absent' : 'present');
                  },
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 36,
              height: 20,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: isPresent
                    ? AppColors.presentEmerald
                    : (isAbsent ? AppColors.absentRose : const Color(0xFFCBD5E1)),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: isPresent ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 3,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Icon(
                    isPresent ? Icons.check_rounded : Icons.close_rounded,
                    size: 11,
                    color: isPresent ? AppColors.presentEmerald : AppColors.absentRose,
                  ),
                ),
              ),
            ),
          ),

          // Present Label
          InkWell(
            onTap: isSaving ? null : () => onStatusChanged('present'),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                'Present',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: isPresent ? FontWeight.w700 : FontWeight.w500,
                  color: isPresent ? AppColors.presentEmerald : AppColors.textSubtle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
