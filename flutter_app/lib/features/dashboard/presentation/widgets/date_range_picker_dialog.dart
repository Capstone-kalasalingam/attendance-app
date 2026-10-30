import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';

class DateRangeSelectionResult {
  final bool isRange;
  final DateTime? singleDate;
  final DateTimeRange? range;

  DateRangeSelectionResult.single(this.singleDate)
      : isRange = false,
        range = null;

  DateRangeSelectionResult.range(this.range)
      : isRange = true,
        singleDate = null;
}

Future<DateRangeSelectionResult?> showAppDateRangePicker(
  BuildContext context, {
  required DateTime currentSingleDate,
  DateTimeRange? currentRange,
  bool initialIsRange = false,
}) {
  return AppDateRangePickerDialog.show(
    context,
    currentSingleDate: currentSingleDate,
    currentRange: currentRange,
    initialIsRange: initialIsRange,
  );
}

class AppDateRangePickerDialog extends StatefulWidget {
  final DateTime currentSingleDate;
  final DateTimeRange? currentRange;
  final bool initialIsRange;

  const AppDateRangePickerDialog({
    super.key,
    required this.currentSingleDate,
    this.currentRange,
    this.initialIsRange = false,
  });

  static Future<DateRangeSelectionResult?> show(
    BuildContext context, {
    required DateTime currentSingleDate,
    DateTimeRange? currentRange,
    bool initialIsRange = false,
  }) {
    return showDialog<DateRangeSelectionResult>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: AppDateRangePickerDialog(
          currentSingleDate: currentSingleDate,
          currentRange: currentRange,
          initialIsRange: initialIsRange,
        ),
      ),
    );
  }

  @override
  State<AppDateRangePickerDialog> createState() => _AppDateRangePickerDialogState();
}

class _AppDateRangePickerDialogState extends State<AppDateRangePickerDialog> {
  late bool _isRangeMode;
  late DateTime _selectedSingleDate;
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    _isRangeMode = widget.initialIsRange;
    _selectedSingleDate = widget.currentSingleDate;

    final now = DateTime.now();
    if (widget.currentRange != null) {
      _startDate = widget.currentRange!.start;
      _endDate = widget.currentRange!.end;
    } else {
      // Default range: last 7 days
      _endDate = DateTime(now.year, now.month, now.day);
      _startDate = _endDate.subtract(const Duration(days: 6));
    }
  }

  Future<void> _pickCustomRange() async {
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
        _isRangeMode = true;
      });
    }
  }

  Future<void> _pickCustomSingleDay() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedSingleDate,
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
        _selectedSingleDate = picked;
        _isRangeMode = false;
      });
    }
  }

  void _applyPresetRange(DateTime start, DateTime end) {
    setState(() {
      _startDate = start;
      _endDate = end;
      _isRangeMode = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Common range presets
    final thisWeekStart = today.subtract(Duration(days: today.weekday - 1));
    final thisWeekEnd = thisWeekStart.add(const Duration(days: 6));
    final last7DaysStart = today.subtract(const Duration(days: 6));
    final thisMonthStart = DateTime(today.year, today.month, 1);
    final thisMonthEnd = DateTime(today.year, today.month + 1, 0);
    final last30DaysStart = today.subtract(const Duration(days: 29));

    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.glassBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 28,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.date_range_rounded, size: 20, color: Color(0xFF4F46E5)),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Date / Range',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Choose single day marking or date range reports',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textMuted),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Mode Selector Switch (Single Day vs Date Range)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _isRangeMode = false),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: !_isRangeMode ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: !_isRangeMode ? const [AppColors.cardShadow] : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 14,
                            color: !_isRangeMode ? const Color(0xFF4F46E5) : AppColors.textMuted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Single Day',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: !_isRangeMode ? FontWeight.w600 : FontWeight.w500,
                              color: !_isRangeMode ? const Color(0xFF4F46E5) : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _isRangeMode = true),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _isRangeMode ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: _isRangeMode ? const [AppColors.cardShadow] : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.insights_rounded,
                            size: 14,
                            color: _isRangeMode ? const Color(0xFF4F46E5) : AppColors.textMuted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Date Range Report',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: _isRangeMode ? FontWeight.w600 : FontWeight.w500,
                              color: _isRangeMode ? const Color(0xFF4F46E5) : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Content based on selected mode
          if (!_isRangeMode) ...[
            // Single day quick options
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildPresetChip(
                  label: 'Today',
                  isSelected: _selectedSingleDate.year == today.year &&
                      _selectedSingleDate.month == today.month &&
                      _selectedSingleDate.day == today.day,
                  onTap: () => setState(() => _selectedSingleDate = today),
                ),
                _buildPresetChip(
                  label: 'Yesterday',
                  isSelected: _selectedSingleDate.year == today.subtract(const Duration(days: 1)).year &&
                      _selectedSingleDate.month == today.subtract(const Duration(days: 1)).month &&
                      _selectedSingleDate.day == today.subtract(const Duration(days: 1)).day,
                  onTap: () => setState(() => _selectedSingleDate = today.subtract(const Duration(days: 1))),
                ),
              ],
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickCustomSingleDay,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.edit_calendar_rounded, size: 18, color: Color(0xFF4F46E5)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        DateFormat('EEEE, MMMM d, yyyy').format(_selectedSingleDate),
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textMuted),
                  ],
                ),
              ),
            ),
          ] else ...[
            // Date range presets
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildPresetChip(
                  label: 'This Week',
                  isSelected: _startDate == thisWeekStart && _endDate == thisWeekEnd,
                  onTap: () => _applyPresetRange(thisWeekStart, thisWeekEnd),
                ),
                _buildPresetChip(
                  label: 'Last 7 Days',
                  isSelected: _startDate == last7DaysStart && _endDate == today,
                  onTap: () => _applyPresetRange(last7DaysStart, today),
                ),
                _buildPresetChip(
                  label: 'This Month',
                  isSelected: _startDate == thisMonthStart && _endDate == thisMonthEnd,
                  onTap: () => _applyPresetRange(thisMonthStart, thisMonthEnd),
                ),
                _buildPresetChip(
                  label: 'Last 30 Days',
                  isSelected: _startDate == last30DaysStart && _endDate == today,
                  onTap: () => _applyPresetRange(last30DaysStart, today),
                ),
              ],
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickCustomRange,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF818CF8)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.date_range_rounded, size: 18, color: Color(0xFF4F46E5)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${DateFormat('MMM d, yyyy').format(_startDate)} – ${DateFormat('MMM d, yyyy').format(_endDate)}',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '${_endDate.difference(_startDate).inDays + 1} days selected (tap to customize)',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              color: Color(0xFF4F46E5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.edit_calendar_rounded, size: 18, color: Color(0xFF4F46E5)),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),

          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Cancel',
                  style: TextStyle(fontFamily: 'Poppins', color: AppColors.textMuted),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  elevation: 0,
                ),
                onPressed: () {
                  if (_isRangeMode) {
                    Navigator.of(context).pop(
                      DateRangeSelectionResult.range(
                        DateTimeRange(start: _startDate, end: _endDate),
                      ),
                    );
                  } else {
                    Navigator.of(context).pop(
                      DateRangeSelectionResult.single(_selectedSingleDate),
                    );
                  }
                },
                icon: const Icon(Icons.check_rounded, size: 16),
                label: Text(
                  _isRangeMode ? 'View Range Report' : 'View Day',
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPresetChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEEF2FF) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF4F46E5) : AppColors.glassBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? const Color(0xFF4F46E5) : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
