import 'package:flutter/material.dart';
import '../../../../core/models/summary_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/stat_card.dart';

class DashboardStatsHeader extends StatelessWidget {
  final AttendanceSummaryModel? summary;
  final bool isLoading;

  const DashboardStatsHeader({
    super.key,
    required this.summary,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final s = summary;

    final totalActive = s?.totalActiveEmployees ?? 0;
    final present = s?.presentCount ?? 0;
    final absent = s?.absentCount ?? 0;
    final notMarked = s?.notMarkedCount ?? 0;
    final morning = s?.morningShiftCount ?? 0;
    final night = s?.nightShiftCount ?? 0;
    final hours = s?.totalHoursWorked ?? 0.0;
    final completion = s?.completionPercentage ?? 0.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;
        final isMedium = constraints.maxWidth > 600;

        int crossAxisCount = 2;
        if (isWide) {
          crossAxisCount = 6;
        } else if (isMedium) {
          crossAxisCount = 3;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GridView.count(
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: isWide ? 2.1 : (isMedium ? 2.3 : 2.5),
              children: [
                StatCard(
                  title: 'Total Active',
                  value: '$totalActive',
                  icon: Icons.people_alt_rounded,
                  accentColor: const Color(0xFF6366F1),
                  subtext: notMarked > 0 ? '$notMarked unmarked' : 'All accounted',
                ),
                StatCard(
                  title: 'Present Today',
                  value: '$present',
                  icon: Icons.check_circle_outline_rounded,
                  accentColor: AppColors.presentEmeraldLight,
                  subtext: '${completion.toStringAsFixed(0)}% completion',
                ),
                StatCard(
                  title: 'Absent Today',
                  value: '$absent',
                  icon: Icons.cancel_outlined,
                  accentColor: AppColors.absentRoseLight,
                  subtext: totalActive > 0 ? '${((absent / totalActive) * 100).toStringAsFixed(0)}% rate' : null,
                ),
                StatCard(
                  title: 'Morning Shift',
                  value: '$morning',
                  icon: Icons.wb_sunny_outlined,
                  accentColor: AppColors.morningAmber,
                  subtext: 'Day duty',
                ),
                StatCard(
                  title: 'Night Shift',
                  value: '$night',
                  icon: Icons.nightlight_outlined,
                  accentColor: AppColors.nightViolet,
                  subtext: 'Evening duty',
                ),
                StatCard(
                  title: 'Hours Recorded',
                  value: '${hours.toStringAsFixed(1)} h',
                  icon: Icons.timer_outlined,
                  accentColor: const Color(0xFF38BDF8),
                  subtext: present > 0 ? 'Avg ${(hours / present).toStringAsFixed(1)} h/person' : null,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
