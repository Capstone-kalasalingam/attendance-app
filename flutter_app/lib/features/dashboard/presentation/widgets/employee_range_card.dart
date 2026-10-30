import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/attendance_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_panel.dart';

class EmployeeRangeCard extends StatelessWidget {
  final EmployeeRangeAggregate aggregate;

  const EmployeeRangeCard({
    super.key,
    required this.aggregate,
  });

  void _showHistoryDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.82,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Color(0x26000000),
              blurRadius: 30,
              offset: Offset(0, -6),
            ),
          ],
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Sheet Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFFEEF2FF),
                    child: Text(
                      _getInitials(aggregate.fullName),
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: Color(0xFF4F46E5),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          aggregate.fullName,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${aggregate.employeeCode} • ${aggregate.designation ?? "Staff"}',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.glassBorder),

            // Performance Summary Ribbon inside sheet
            Container(
              color: const Color(0xFFF8FAFC),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSheetStat('Present', '${aggregate.daysPresent} d', AppColors.presentEmerald),
                  _buildSheetStat('Absent', '${aggregate.daysAbsent} d', AppColors.absentRose),
                  _buildSheetStat('Hours', '${aggregate.totalHours.toStringAsFixed(1)} h', const Color(0xFF0284C7)),
                  _buildSheetStat('Rate', '${aggregate.attendancePercentage.toStringAsFixed(0)}%', const Color(0xFF4F46E5)),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.glassBorder),

            // Detailed Record List
            Expanded(
              child: aggregate.records.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.event_busy_rounded, size: 40, color: AppColors.textSubtle),
                          const SizedBox(height: 10),
                          const Text(
                            'No recorded attendance in this date range',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      itemCount: aggregate.records.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (ctx, idx) {
                        final rec = aggregate.records[idx];
                        DateTime? parsedDate = DateTime.tryParse(rec.attendanceDate);
                        final dateStr = parsedDate != null
                            ? DateFormat('EEE, MMM d, yyyy').format(parsedDate)
                            : rec.attendanceDate;

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.glassBorder),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: rec.isPresent
                                      ? AppColors.presentBg
                                      : AppColors.absentBg,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: rec.isPresent
                                        ? AppColors.presentBorder
                                        : AppColors.absentBorder,
                                  ),
                                ),
                                child: Text(
                                  rec.status.toUpperCase(),
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: rec.isPresent
                                        ? AppColors.presentEmerald
                                        : AppColors.absentRose,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      dateStr,
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    if (rec.workDescription != null && rec.workDescription!.isNotEmpty)
                                      Text(
                                        rec.workDescription!,
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${rec.hoursWorked.toStringAsFixed(1)}h',
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    rec.shift.toUpperCase(),
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: rec.shift == 'morning'
                                          ? AppColors.morningAmber
                                          : AppColors.nightViolet,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSheetStat(String title, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  static String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return 'EM';
  }

  @override
  Widget build(BuildContext context) {
    final pct = aggregate.attendancePercentage;

    return GlassPanel(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 12),
      borderRadius: 16,
      surfaceColor: Colors.white,
      borderColor: AppColors.glassBorder,
      child: InkWell(
        onTap: () => _showHistoryDetails(context),
        borderRadius: BorderRadius.circular(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Row 1: Employee Header & Info
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFFEEF2FF),
                  child: Text(
                    _getInitials(aggregate.fullName),
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: Color(0xFF4F46E5),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        aggregate.fullName,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${aggregate.employeeCode} • ${aggregate.designation ?? "Staff"}',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: aggregate.defaultShift == 'morning'
                        ? AppColors.morningAmberBg
                        : AppColors.nightVioletBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: aggregate.defaultShift == 'morning'
                          ? AppColors.morningAmberBorder
                          : AppColors.nightVioletBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        aggregate.defaultShift == 'morning'
                            ? Icons.wb_sunny_rounded
                            : Icons.nightlight_round,
                        size: 12,
                        color: aggregate.defaultShift == 'morning'
                            ? AppColors.morningAmber
                            : AppColors.nightViolet,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        aggregate.defaultShift.toUpperCase(),
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: aggregate.defaultShift == 'morning'
                              ? AppColors.morningAmber
                              : AppColors.nightViolet,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textMuted),
              ],
            ),
            const SizedBox(height: 12),

            // Row 2: Attendance Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (pct / 100.0).clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: const Color(0xFFF1F5F9),
                valueColor: AlwaysStoppedAnimation<Color>(
                  pct >= 90
                      ? AppColors.presentEmerald
                      : pct >= 75
                          ? const Color(0xFF4F46E5)
                          : pct >= 50
                              ? AppColors.morningAmber
                              : AppColors.absentRose,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Row 3: 4 Key Aggregated Metrics
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _buildMetricChip(
                  icon: Icons.check_circle_rounded,
                  label: '${aggregate.daysPresent} Days Present',
                  color: AppColors.presentEmerald,
                  bg: AppColors.presentBg,
                  border: AppColors.presentBorder,
                ),
                _buildMetricChip(
                  icon: Icons.cancel_rounded,
                  label: '${aggregate.daysAbsent} Days Absent',
                  color: AppColors.absentRose,
                  bg: AppColors.absentBg,
                  border: AppColors.absentBorder,
                ),
                _buildMetricChip(
                  icon: Icons.timer_outlined,
                  label: '${aggregate.totalHours.toStringAsFixed(1)} Hours Total',
                  color: const Color(0xFF0284C7),
                  bg: const Color(0xFFF0F9FF),
                  border: const Color(0xFFBAE6FD),
                ),
                _buildMetricChip(
                  icon: Icons.insights_rounded,
                  label: '${pct.toStringAsFixed(0)}% Rate',
                  color: const Color(0xFF4F46E5),
                  bg: const Color(0xFFEEF2FF),
                  border: const Color(0xFFC7D2FE),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricChip({
    required IconData icon,
    required String label,
    required Color color,
    required Color bg,
    required Color border,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
