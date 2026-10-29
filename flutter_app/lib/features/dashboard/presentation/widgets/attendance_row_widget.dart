import 'package:flutter/material.dart';
import '../../../../core/models/attendance_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/attendance_status_toggle.dart';
import '../../../../core/widgets/glass_dialog.dart';
import '../../../../core/widgets/glass_panel.dart';
import '../../../../core/widgets/glass_text_field.dart';
import '../../../../core/widgets/shift_selector.dart';

class AttendanceRowWidget extends StatelessWidget {
  final AttendanceRowModel row;
  final bool isSelected;
  final ValueChanged<bool?> onSelectChanged;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onShiftChanged;
  final ValueChanged<double> onHoursChanged;
  final ValueChanged<String> onDescriptionChanged;
  final VoidCallback onEditEmployee;

  const AttendanceRowWidget({
    super.key,
    required this.row,
    required this.isSelected,
    required this.onSelectChanged,
    required this.onStatusChanged,
    required this.onShiftChanged,
    required this.onHoursChanged,
    required this.onDescriptionChanged,
    required this.onEditEmployee,
  });

  void _showHoursDialog(BuildContext context) {
    final controller = TextEditingController(text: row.hoursWorked.toStringAsFixed(1));
    GlassDialog.show(
      context: context,
      title: 'Hours Worked — ${row.fullName}',
      titleIcon: Icons.timer_outlined,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassTextField(
            controller: controller,
            labelText: 'Duration in Hours (0 - 24)',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            children: [4.0, 8.0, 9.0, 10.0, 12.0].map((h) {
              return ActionChip(
                label: Text('${h.toInt()}h', style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w600)),
                backgroundColor: const Color(0xFFF1F5F9),
                side: const BorderSide(color: AppColors.glassBorder),
                onPressed: () {
                  controller.text = h.toString();
                },
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4F46E5),
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            final val = double.tryParse(controller.text);
            if (val != null && val >= 0 && val <= 24) {
              onHoursChanged(val);
              Navigator.of(context).pop();
            }
          },
          child: const Text('Save Hours'),
        ),
      ],
    );
  }

  void _showDescriptionDialog(BuildContext context) {
    final controller = TextEditingController(text: row.workDescription ?? '');
    final quickTasks = ['Packing cartons', 'Loading & Dispatch', 'Machine line operation', 'Cleaning & Inspection', 'Maintenance duty', 'Assembly line work'];

    GlassDialog.show(
      context: context,
      title: 'Work Description — ${row.fullName}',
      titleIcon: Icons.description_outlined,
      content: StatefulBuilder(
        builder: (context, setDialogState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GlassTextField(
                controller: controller,
                labelText: 'Task / Activity Done Today',
                hintText: 'Type complete details of tasks completed...',
                maxLines: 3,
                autofocus: true,
              ),
              const SizedBox(height: 14),
              const Text(
                'Quick Suggestions:',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: quickTasks.map((task) {
                  final isSelected = controller.text == task;
                  return InkWell(
                    onTap: () {
                      controller.text = task;
                      setDialogState(() {});
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFEEF2FF) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF4F46E5) : AppColors.glassBorder,
                        ),
                      ),
                      child: Text(
                        task,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected ? const Color(0xFF4F46E5) : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4F46E5),
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            onDescriptionChanged(controller.text);
            Navigator.of(context).pop();
          },
          child: const Text('Save Description'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 950) {
          return _buildMobileCard(context);
        }
        return _buildTableRow(context);
      },
    );
  }

  // DESKTOP TABLE ROW
  Widget _buildTableRow(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(bottom: 8),
      borderRadius: 14,
      surfaceColor: isSelected ? const Color(0xFFF0F4FF) : Colors.white,
      borderColor: isSelected ? const Color(0xFF818CF8) : AppColors.glassBorder,
      child: Row(
        children: [
          // Bulk selection checkbox
          SizedBox(
            width: 22,
            height: 22,
            child: Checkbox(
              value: isSelected,
              onChanged: onSelectChanged,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              activeColor: const Color(0xFF4F46E5),
              side: const BorderSide(color: AppColors.glassBorderStrong, width: 1.2),
            ),
          ),
          const SizedBox(width: 12),

          // Avatar initials badge
          _buildAvatar(),
          const SizedBox(width: 12),

          // Employee Info
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        row.fullName,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.glassBorder),
                      ),
                      child: Text(
                        row.employeeCode,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                if (row.designation != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    row.designation!,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: AppColors.textSubtle,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          // Shift Selector
          ShiftSelector(
            currentShift: row.shift,
            onShiftChanged: onShiftChanged,
            isSaving: row.isSaving,
          ),
          const SizedBox(width: 14),

          // Attendance Status Toggle Switch
          AttendanceStatusToggle(
            currentStatus: row.status,
            onStatusChanged: onStatusChanged,
            isSaving: row.isSaving,
          ),
          const SizedBox(width: 14),

          // Timings & Hours Stepper
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () {
                    final newHours = (row.hoursWorked - 0.5).clamp(0.0, 24.0);
                    onHoursChanged(double.parse(newHours.toStringAsFixed(1)));
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: const Icon(Icons.remove_rounded, size: 14, color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(width: 6),
                InkWell(
                  onTap: () => _showHoursDialog(context),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF0284C7)),
                        const SizedBox(width: 4),
                        Text(
                          '${row.hoursWorked.toStringAsFixed(1)}h',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                InkWell(
                  onTap: () {
                    final newHours = (row.hoursWorked + 0.5).clamp(0.0, 24.0);
                    onHoursChanged(double.parse(newHours.toStringAsFixed(1)));
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: const Icon(Icons.add_rounded, size: 14, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Work Description (Spacious Flex 3)
          Expanded(
            flex: 3,
            child: InkWell(
              onTap: () => _showDescriptionDialog(context),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.edit_note_rounded, size: 15, color: Color(0xFF4F46E5)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        row.workDescription ?? 'Add work description...',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontStyle: row.workDescription == null ? FontStyle.italic : FontStyle.normal,
                          color: row.workDescription == null ? AppColors.textSubtle : AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Status & Action indicators
          _buildRowStatusIndicator(),

          // Menu popup (Edit Employee)
          IconButton(
            icon: const Icon(Icons.more_vert_rounded, size: 18, color: AppColors.textMuted),
            splashRadius: 18,
            onPressed: onEditEmployee,
            tooltip: 'Edit Employee',
          ),
        ],
      ),
    );
  }

  // MOBILE RESPONSIVE CARD
  Widget _buildMobileCard(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 12),
      borderRadius: 16,
      surfaceColor: isSelected ? const Color(0xFFF0F4FF) : Colors.white,
      borderColor: isSelected ? const Color(0xFF818CF8) : AppColors.glassBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Top Row: Checkbox, Avatar, Name & Code, Shift Selector, Menu
          Row(
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: Checkbox(
                  value: isSelected,
                  onChanged: onSelectChanged,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  activeColor: const Color(0xFF4F46E5),
                  side: const BorderSide(color: AppColors.glassBorderStrong, width: 1.2),
                ),
              ),
              const SizedBox(width: 8),
              _buildAvatar(),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.fullName,
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
                      '${row.employeeCode}${row.designation != null ? ' • ${row.designation}' : ''}',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              ShiftSelector(
                currentShift: row.shift,
                onShiftChanged: onShiftChanged,
                isSaving: row.isSaving,
              ),
              IconButton(
                icon: const Icon(Icons.more_vert_rounded, size: 20, color: AppColors.textMuted),
                splashRadius: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                onPressed: onEditEmployee,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.glassBorder, height: 1),
          const SizedBox(height: 10),

          // 2. Middle Row: Present/Absent Toggle Switch & Timings Stepper
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Attendance Status Toggle Switch
              AttendanceStatusToggle(
                currentStatus: row.status,
                onStatusChanged: onStatusChanged,
                isSaving: row.isSaving,
              ),

              // Timings & Hours Stepper with ample room
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Quick Decrement
                    InkWell(
                      onTap: () {
                        final newHours = (row.hoursWorked - 0.5).clamp(0.0, 24.0);
                        onHoursChanged(double.parse(newHours.toStringAsFixed(1)));
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.glassBorder),
                        ),
                        child: const Icon(Icons.remove_rounded, size: 14, color: AppColors.textSecondary),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Tap to edit hours directly
                    InkWell(
                      onTap: () => _showHoursDialog(context),
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF0284C7)),
                            const SizedBox(width: 4),
                            Text(
                              '${row.hoursWorked.toStringAsFixed(1)}h',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Quick Increment
                    InkWell(
                      onTap: () {
                        final newHours = (row.hoursWorked + 0.5).clamp(0.0, 24.0);
                        onHoursChanged(double.parse(newHours.toStringAsFixed(1)));
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.glassBorder),
                        ),
                        child: const Icon(Icons.add_rounded, size: 14, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 3. Bottom Row: Dedicated Full-Width Spacious Work Description Field
          InkWell(
            onTap: () => _showDescriptionDialog(context),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(Icons.edit_note_rounded, size: 16, color: Color(0xFF4F46E5)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      row.workDescription?.isNotEmpty == true
                          ? row.workDescription!
                          : 'Tap to enter work description & tasks done today...',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontStyle: (row.workDescription == null || row.workDescription!.isEmpty)
                            ? FontStyle.italic
                            : FontStyle.normal,
                        color: (row.workDescription == null || row.workDescription!.isEmpty)
                            ? AppColors.textSubtle
                            : AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    final initials = row.fullName.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join();
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFC7D2FE)),
      ),
      alignment: Alignment.center,
      child: Text(
        initials.toUpperCase(),
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFF4F46E5),
        ),
      ),
    );
  }

  Widget _buildRowStatusIndicator() {
    if (row.isSaving) {
      return const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
        ),
      );
    }
    if (row.saveError != null) {
      return Tooltip(
        message: row.saveError!,
        child: const Icon(Icons.error_outline_rounded, size: 18, color: AppColors.absentRose),
      );
    }
    if (row.saveSuccess) {
      return const Icon(Icons.check_circle_outline_rounded, size: 16, color: AppColors.presentEmerald);
    }
    return const SizedBox(width: 16);
  }
}
