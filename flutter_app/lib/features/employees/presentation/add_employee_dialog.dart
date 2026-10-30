import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_button.dart';
import '../../../core/widgets/glass_dialog.dart';
import '../../../core/widgets/glass_text_field.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../salary/providers/salary_provider.dart';
import '../providers/employee_provider.dart';

class AddEmployeeDialog extends ConsumerStatefulWidget {
  const AddEmployeeDialog({super.key});

  static Future<void> show(BuildContext context) {
    return GlassDialog.show(
      context: context,
      title: 'Add New Employee',
      titleIcon: Icons.person_add_alt_1_rounded,
      content: const AddEmployeeDialog(),
    );
  }

  @override
  ConsumerState<AddEmployeeDialog> createState() => _AddEmployeeDialogState();
}

class _AddEmployeeDialogState extends ConsumerState<AddEmployeeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _designationController = TextEditingController();
  final _morningRateController = TextEditingController(text: '0.00');
  final _nightRateController = TextEditingController(text: '0.00');
  final _notesController = TextEditingController();

  String _defaultShift = 'morning';
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _designationController.dispose();
    _morningRateController.dispose();
    _nightRateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final morningRate = double.tryParse(_morningRateController.text.trim()) ?? 0.0;
      final nightRate = double.tryParse(_nightRateController.text.trim()) ?? 0.0;

      final service = ref.read(employeeServiceProvider);
      await service.createEmployee(
        code: _codeController.text,
        name: _nameController.text,
        phone: _phoneController.text,
        designation: _designationController.text,
        defaultShift: _defaultShift,
        hourlyRateMorning: morningRate,
        hourlyRateNight: nightRate,
        notes: _notesController.text,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ref.read(dashboardNotifierProvider.notifier).loadData();
        ref.invalidate(employeesListProvider);
        ref.read(salaryNotifierProvider.notifier).loadPayroll();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Employee "${_nameController.text}" added successfully!'),
            backgroundColor: AppColors.presentEmerald,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = ApiClient.parseError(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.absentBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.absentBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, size: 18, color: AppColors.absentRose),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: AppColors.absentRose,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: GlassTextField(
                  controller: _nameController,
                  labelText: 'Full Name *',
                  hintText: 'e.g. Aarav Sharma',
                  prefixIcon: Icons.person_outline_rounded,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Full name is required' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: GlassTextField(
                  controller: _codeController,
                  labelText: 'Employee ID *',
                  hintText: 'EMP-011',
                  prefixIcon: Icons.badge_outlined,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'ID required' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: GlassTextField(
                  controller: _designationController,
                  labelText: 'Designation',
                  hintText: 'e.g. Machine Operator',
                  prefixIcon: Icons.work_outline_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GlassTextField(
                  controller: _phoneController,
                  labelText: 'Phone Number',
                  hintText: '+91 98765 43210',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Hourly Rates Row
          Row(
            children: [
              Expanded(
                child: GlassTextField(
                  controller: _morningRateController,
                  labelText: 'Day Rate (₹/hr)',
                  hintText: 'e.g. 100',
                  prefixIcon: Icons.wb_sunny_outlined,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GlassTextField(
                  controller: _nightRateController,
                  labelText: 'Night Rate (₹/hr)',
                  hintText: 'e.g. 120',
                  prefixIcon: Icons.nightlight_outlined,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Default shift radio/toggle
          const Text(
            'Default Assigned Shift *',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _defaultShift = 'morning'),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _defaultShift == 'morning'
                          ? AppColors.morningAmberBg
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _defaultShift == 'morning'
                            ? AppColors.morningAmberBorder
                            : AppColors.glassBorder,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.wb_sunny_rounded,
                          size: 16,
                          color: _defaultShift == 'morning' ? AppColors.morningAmber : AppColors.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Morning Shift',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: _defaultShift == 'morning' ? FontWeight.w600 : FontWeight.w500,
                            color: _defaultShift == 'morning' ? AppColors.morningAmber : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _defaultShift = 'night'),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _defaultShift == 'night'
                          ? AppColors.nightVioletBg
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _defaultShift == 'night'
                            ? AppColors.nightVioletBorder
                            : AppColors.glassBorder,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.nightlight_round,
                          size: 16,
                          color: _defaultShift == 'night' ? AppColors.nightViolet : AppColors.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Night Shift',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: _defaultShift == 'night' ? FontWeight.w600 : FontWeight.w500,
                            color: _defaultShift == 'night' ? AppColors.nightViolet : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          GlassTextField(
            controller: _notesController,
            labelText: 'Notes / Remarks',
            hintText: 'Optional notes regarding employment',
            maxLines: 2,
          ),
          const SizedBox(height: 24),

          // Actions
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 10,
            runSpacing: 8,
            children: [
              GlassButton(
                text: 'Cancel',
                variant: GlassButtonVariant.ghost,
                onPressed: () => Navigator.of(context).pop(),
              ),
              GlassButton(
                text: 'Save Employee',
                icon: Icons.check_rounded,
                isLoading: _isLoading,
                onPressed: _submit,
                variant: GlassButtonVariant.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
