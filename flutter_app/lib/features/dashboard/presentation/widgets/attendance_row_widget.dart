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
                label: Text('${h.toInt()}h', style: const TextStyle(fontFamily: 'Poppins', fontSize: 11)),
                backgroundColor: const Color(0x226366F1),
                side: const BorderSide(color: Color(0x44818CF8)),
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
            backgroundColor: const Color(0xFF6366F1),
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
    final quickTasks = ['Packing', 'Loading', 'Machine operation', 'Cleaning', 'Maintenance', 'Assembly line', 'Dispatch'];

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
                labelText: 'Task / Activity (Optional)',
                hintText: 'e.g. Packing cartons, Machine line 2',
                maxLines: 2,
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
                  return InkWell(
                    onTap: () {
                      controller.text = task;
                      setDialogState(() {});
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: controller.text == task
                            ? const Color(0x446366F1)
                            : const Color(0x15FFFFFF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: controller.text == task
                              ? const Color(0xFF818CF8)
                              : const Color(0x22FFFFFF),
                        ),
                      ),
                      child: Text(
                        task,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: controller.text == task ? Colors.white : AppColors.textSecondary,
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
            backgroundColor: const Color(0xFF6366F1),
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
        final isMobile = constraints.maxWidth < 950;

        if (isMobile) {
          return _buildMobileCard(context);
        } else {
          return _buildDesktopRow(context);
        }
      },
    );
  }

  // DESKTOP & TABLET COMPACT ROW
  Widget _buildDesktopRow(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      margin: const EdgeInsets.only(bottom: 8),
      borderRadius: 14,
      surfaceColor: isSelected ? const Color(0x286366F1) : const Color(0x12FFFFFF),
      borderColor: isSelected ? const Color(0x66818CF8) : const Color(0x1AFFFFFF),
      child: Row(
        children: [
          // Bulk selection checkbox
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: isSelected,
              onChanged: onSelectChanged,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              activeColor: const Color(0xFF6366F1),
              side: const BorderSide(color: Color(0x44FFFFFF), width: 1.2),
            ),
          ),
          const SizedBox(width: 12),

          // Avatar initials badge
          _buildAvatar(),
          const SizedBox(width: 14),

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
                        color: const Color(0x18FFFFFF),
                        borderRadius: BorderRadius.circular(6),
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
          const SizedBox(width: 16),

          // Attendance Status Toggle (Present / Absent)
          AttendanceStatusToggle(
            currentStatus: row.status,
            onStatusChanged: onStatusChanged,
            isSaving: row.isSaving,
          ),
          const SizedBox(width: 16),

          // Hours Worked Pill
          InkWell(
            onTap: () => _showHoursDialog(context),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0x14FFFFFF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0x22FFFFFF)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.timer_outlined, size: 14, color: Color(0xFF38BDF8)),
                  const SizedBox(width: 6),
                  Text(
                    '${row.hoursWorked.toStringAsFixed(1)}h',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.edit_outlined, size: 12, color: AppColors.textMuted),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Work Description Pill
          Expanded(
            flex: 2,
            child: InkWell(
              onTap: () => _showDescriptionDialog(context),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0x10FFFFFF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0x18FFFFFF)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.edit_note_rounded, size: 15, color: AppColors.textMuted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        row.workDescription ?? 'Add task...',
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
      margin: const EdgeInsets.only(bottom: 10),
      borderRadius: 16,
      surfaceColor: isSelected ? const Color(0x286366F1) : const Color(0x12FFFFFF),
      borderColor: isSelected ? const Color(0x66818CF8) : const Color(0x1AFFFFFF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Row: Checkbox, Avatar, Name, Shift, Menu
          Row(
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: Checkbox(
                  value: isSelected,
                  onChanged: onSelectChanged,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  activeColor: const Color(0xFF6366F1),
                  side: const BorderSide(color: Color(0x44FFFFFF), width: 1.2),
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
                        fontSize: 13,
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
                        fontSize: 10,
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
                icon: const Icon(Icons.more_vert_rounded, size: 18, color: AppColors.textMuted),
                splashRadius: 16,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                onPressed: onEditEmployee,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0x1AFFFFFF), height: 1),
          const SizedBox(height: 10),

          // Bottom Controls: Status, Hours, Description
          Row(
            children: [
              // One-tap Present / Absent
              AttendanceStatusToggle(
                currentStatus: row.status,
                onStatusChanged: onStatusChanged,
                isSaving: row.isSaving,
              ),
              const SizedBox(width: 8),

              // Hours Worked
              InkWell(
                onTap: () => _showHoursDialog(context),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0x14FFFFFF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0x22FFFFFF)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer_outlined, size: 13, color: Color(0xFF38BDF8)),
                      const SizedBox(width: 4),
                      Text(
                        '${row.hoursWorked.toStringAsFixed(1)}h',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Work Description
              Expanded(
                child: InkWell(
                  onTap: () => _showDescriptionDialog(context),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0x10FFFFFF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0x18FFFFFF)),
                    ),
                    child: Text(
                      row.workDescription ?? 'Task...',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        fontStyle: row.workDescription == null ? FontStyle.italic : FontStyle.normal,
                        color: row.workDescription == null ? AppColors.textSubtle : AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 6),
              _buildRowStatusIndicator(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    final initials = row.fullName.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join();
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF4F46E5).withOpacity(0.8),
            const Color(0xFF7C3AED).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x44818CF8)),
      ),
      alignment: Alignment.center,
      child: Text(
        initials.toUpperCase(),
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
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
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF818CF8)),
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
      return const Icon(Icons.check_circle_outline_rounded, size: 16, color: AppColors.presentEmeraldLight);
    }
    return const SizedBox(width: 16);
  }
}
