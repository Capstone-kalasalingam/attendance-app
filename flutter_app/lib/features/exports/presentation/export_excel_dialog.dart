import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_button.dart';
import '../../../../core/widgets/glass_dialog.dart';
import '../providers/export_provider.dart';

class ExportExcelDialog extends ConsumerStatefulWidget {
  final DateTime initialDate;
  final DateTimeRange? initialRange;

  const ExportExcelDialog({
    super.key,
    required this.initialDate,
    this.initialRange,
  });

  static Future<void> show(
    BuildContext context,
    DateTime date, {
    DateTimeRange? range,
  }) {
    return GlassDialog.show(
      context: context,
      title: 'Export Attendance to Excel (.xlsx)',
      titleIcon: Icons.table_chart_rounded,
      content: ExportExcelDialog(initialDate: date, initialRange: range),
    );
  }

  @override
  ConsumerState<ExportExcelDialog> createState() => _ExportExcelDialogState();
}

class _ExportExcelDialogState extends ConsumerState<ExportExcelDialog> {
  late DateTime _startDate;
  late DateTime _endDate;
  String _selectedShift = 'all';
  String _selectedStatus = 'all';

  bool _isExporting = false;
  String? _statusMessage;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialRange != null) {
      _startDate = widget.initialRange!.start;
      _endDate = widget.initialRange!.end;
    } else {
      _startDate = widget.initialDate;
      _endDate = widget.initialDate;
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4F46E5),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Future<void> _triggerExport() async {
    setState(() {
      _isExporting = true;
      _statusMessage = null;
      _isSuccess = false;
    });

    try {
      final exportService = ref.read(exportServiceProvider);
      final startStr = DateFormat('yyyy-MM-dd').format(_startDate);
      final endStr = DateFormat('yyyy-MM-dd').format(_endDate);

      final result = await exportService.exportAttendanceExcel(
        startDate: startStr,
        endDate: endStr,
        shift: _selectedShift,
        status: _selectedStatus,
      );

      if (mounted) {
        setState(() {
          _isExporting = false;
          _isSuccess = true;
          _statusMessage = 'Workbook successfully exported! $result';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isExporting = false;
          _isSuccess = false;
          _statusMessage = ApiClient.parseError(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateRangeText = '${DateFormat('MMM d, yyyy').format(_startDate)}  →  ${DateFormat('MMM d, yyyy').format(_endDate)}';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Date Range Selector Pill
        const Text(
          'Date Period',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: _selectDateRange,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.glassBorder),
              boxShadow: const [AppColors.cardShadow],
            ),
            child: Row(
              children: [
                const Icon(Icons.date_range_rounded, size: 18, color: Color(0xFF4F46E5)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    dateRangeText,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_drop_down_rounded, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Quick Date Shortcuts
        Row(
          children: [
            _buildShortcutChip('Today', () {
              setState(() {
                _startDate = DateTime.now();
                _endDate = DateTime.now();
              });
            }),
            const SizedBox(width: 6),
            _buildShortcutChip('This Week', () {
              final now = DateTime.now();
              setState(() {
                _startDate = now.subtract(Duration(days: now.weekday - 1));
                _endDate = now;
              });
            }),
            const SizedBox(width: 6),
            _buildShortcutChip('This Month', () {
              final now = DateTime.now();
              setState(() {
                _startDate = DateTime(now.year, now.month, 1);
                _endDate = now;
              });
            }),
          ],
        ),
        const SizedBox(height: 16),

        // Filters: Shift & Status
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Shift Filter',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedShift,
                        isExpanded: true,
                        dropdownColor: Colors.white,
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('All Shifts', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.textPrimary))),
                          DropdownMenuItem(value: 'morning', child: Text('Morning Shift', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.textPrimary))),
                          DropdownMenuItem(value: 'night', child: Text('Night Shift', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.textPrimary))),
                        ],
                        onChanged: (v) => setState(() => _selectedShift = v!),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Status Filter',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedStatus,
                        isExpanded: true,
                        dropdownColor: Colors.white,
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('All Statuses', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.textPrimary))),
                          DropdownMenuItem(value: 'present', child: Text('Present Only', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.textPrimary))),
                          DropdownMenuItem(value: 'absent', child: Text('Absent Only', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.textPrimary))),
                        ],
                        onChanged: (v) => setState(() => _selectedStatus = v!),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Sheets preview info
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Includes 3 Structured Sheets:',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF4F46E5)),
              ),
              SizedBox(height: 4),
              Text('• Sheet 1: Detailed records with tasks & hours', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textMuted)),
              Text('• Sheet 2: Daily Headcount & Completion %', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textMuted)),
              Text('• Sheet 3: Employee Aggregate Summary', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textMuted)),
            ],
          ),
        ),

        // Feedback / Status message
        if (_statusMessage != null) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _isSuccess ? AppColors.presentBg : AppColors.absentBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isSuccess ? AppColors.presentBorder : AppColors.absentBorder,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _isSuccess ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded,
                  color: _isSuccess ? AppColors.presentEmerald : AppColors.absentRose,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _statusMessage!,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: _isSuccess ? AppColors.presentEmerald : AppColors.absentRose,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 24),

        // Actions
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 10,
          runSpacing: 8,
          children: [
            GlassButton(
              text: 'Close',
              variant: GlassButtonVariant.ghost,
              onPressed: () => Navigator.of(context).pop(),
            ),
            GlassButton(
              text: 'Download .xlsx',
              icon: Icons.download_rounded,
              isLoading: _isExporting,
              onPressed: _triggerExport,
              variant: GlassButtonVariant.primary,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildShortcutChip(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Text(
          label,
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
