import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/attendance_model.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_button.dart';
import '../../../../core/widgets/glass_dialog.dart';
import '../../../../core/widgets/glass_text_field.dart';
import '../providers/employee_provider.dart';

class EditEmployeeDialog extends ConsumerStatefulWidget {
  final AttendanceRowModel row;

  const EditEmployeeDialog({
    super.key,
    required this.row,
  });

  static Future<void> show(BuildContext context, AttendanceRowModel row) {
    return GlassDialog.show(
      context: context,
      title: 'Edit Employee — ${row.fullName}',
      titleIcon: Icons.manage_accounts_rounded,
      content: EditEmployeeDialog(row: row),
    );
  }

  @override
  ConsumerState<EditEmployeeDialog> createState() => _EditEmployeeDialogState();
}

class _EditEmployeeDialogState extends ConsumerState<EditEmployeeDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _designationController;
  late final TextEditingController _notesController;

  late String _defaultShift;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.row.fullName);
    _phoneController = TextEditingController();
    _designationController = TextEditingController(text: widget.row.designation ?? '');
    _notesController = TextEditingController();
    _defaultShift = widget.row.defaultShift;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _designationController.dispose();
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
      final service = ref.read(employeeServiceProvider);
      await service.updateEmployee(
        id: widget.row.employeeId,
        name: _nameController.text,
        phone: _phoneController.text,
        designation: _designationController.text,
        defaultShift: _defaultShift,
        notes: _notesController.text,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Employee "${_nameController.text}" updated successfully!'),
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

  Future<void> _deactivate() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.glassBorder),
        ),
        title: const Text(
          'Deactivate Employee?',
          style: TextStyle(color: AppColors.textPrimary, fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Deactivating "${widget.row.fullName}" will hide them from future attendance lists while preserving all historical records.',
          style: const TextStyle(color: AppColors.textSecondary, fontFamily: 'Poppins'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.absentRose),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final service = ref.read(employeeServiceProvider);
        await service.setEmployeeStatus(id: widget.row.employeeId, isActive: false);
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Employee deactivated.')),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _errorMessage = ApiClient.parseError(e));
        }
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
              child: Text(
                _errorMessage!,
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.absentRose),
              ),
            ),
          ],

          GlassTextField(
            controller: _nameController,
            labelText: 'Full Name *',
            prefixIcon: Icons.person_outline_rounded,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Full name required' : null,
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: GlassTextField(
                  controller: _designationController,
                  labelText: 'Designation',
                  prefixIcon: Icons.work_outline_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GlassTextField(
                  controller: _phoneController,
                  labelText: 'Phone Number',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          const Text(
            'Default Shift',
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
                        color: _defaultShift == 'morning' ? AppColors.morningAmberBorder : AppColors.glassBorder,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Morning Shift',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: _defaultShift == 'morning' ? FontWeight.w600 : FontWeight.w500,
                          color: _defaultShift == 'morning' ? AppColors.morningAmber : AppColors.textSecondary,
                        ),
                      ),
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
                        color: _defaultShift == 'night' ? AppColors.nightVioletBorder : AppColors.glassBorder,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Night Shift',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: _defaultShift == 'night' ? FontWeight.w600 : FontWeight.w500,
                          color: _defaultShift == 'night' ? AppColors.nightViolet : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Actions
          Row(
            children: [
              TextButton.icon(
                onPressed: _deactivate,
                icon: const Icon(Icons.person_off_rounded, size: 16, color: AppColors.absentRose),
                label: const Text('Deactivate', style: TextStyle(color: AppColors.absentRose, fontSize: 12)),
              ),
              const Spacer(),
              GlassButton(
                text: 'Cancel',
                variant: GlassButtonVariant.ghost,
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: 10),
              GlassButton(
                text: 'Update',
                icon: Icons.save_rounded,
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
