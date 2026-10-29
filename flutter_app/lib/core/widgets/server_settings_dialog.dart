import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../theme/app_colors.dart';
import '../../features/auth/providers/auth_provider.dart';
import 'glass_button.dart';
import 'glass_dialog.dart';
import 'glass_panel.dart';
import 'glass_text_field.dart';

class ServerSettingsDialog extends ConsumerStatefulWidget {
  const ServerSettingsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (ctx) => const ServerSettingsDialog(),
    );
  }

  @override
  ConsumerState<ServerSettingsDialog> createState() => _ServerSettingsDialogState();
}

class _ServerSettingsDialogState extends ConsumerState<ServerSettingsDialog> {
  late final TextEditingController _urlController;
  bool _isTesting = false;
  String? _testResult;
  bool _testSuccess = false;

  @override
  void initState() {
    super.initState();
    final currentUrl = ref.read(apiBaseUrlProvider);
    _urlController = TextEditingController(text: currentUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    final targetUrl = AppConfig.cleanUrl(_urlController.text);
    if (targetUrl.isEmpty) {
      setState(() {
        _testResult = 'Please enter a valid URL';
        _testSuccess = false;
      });
      return;
    }

    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    final stopwatch = Stopwatch()..start();
    try {
      final testDio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );

      final response = await testDio.get('$targetUrl/health');
      stopwatch.stop();

      if (response.statusCode == 200) {
        setState(() {
          _isTesting = false;
          _testSuccess = true;
          _testResult = 'Connected successfully (${stopwatch.elapsedMilliseconds}ms) • Server healthy';
        });
      } else {
        setState(() {
          _isTesting = false;
          _testSuccess = false;
          _testResult = 'Server returned HTTP ${response.statusCode}';
        });
      }
    } catch (e) {
      stopwatch.stop();
      setState(() {
        _isTesting = false;
        _testSuccess = false;
        _testResult = 'Connection failed: Cannot reach $targetUrl';
      });
    }
  }

  void _applyNewAddress() {
    final targetUrl = AppConfig.cleanUrl(_urlController.text);
    if (targetUrl.isNotEmpty) {
      ref.read(apiBaseUrlProvider.notifier).setBaseUrl(targetUrl);
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.textPrimary,
          content: Text(
            'API server connected to: $targetUrl',
            style: const TextStyle(fontFamily: 'Poppins', color: Colors.white),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _resetDefault() {
    _urlController.text = AppConfig.defaultApiBaseUrl;
    ref.read(apiBaseUrlProvider.notifier).resetToDefault();
    setState(() {
      _testResult = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GlassDialog(
      title: 'Server Settings',
      maxWidth: 520,
      titleIcon: Icons.dns_rounded,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Subtitle info
          const Text(
            'Dynamically configure your backend host URL. Changes persist automatically and require no app recompilation.',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppColors.textMuted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),

          // URL input field
          GlassTextField(
            controller: _urlController,
            labelText: 'Backend API Base URL',
            hintText: 'http://your-server-ip-or-domain:8080',
            prefixIcon: Icons.dns_rounded,
          ),
          const SizedBox(height: 12),

          // Presets chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildPresetChip(
                label: '☁️ Cloud Server',
                url: AppConfig.defaultApiBaseUrl,
                isSelected: _urlController.text == AppConfig.defaultApiBaseUrl,
              ),
              _buildPresetChip(
                label: '💻 Localhost',
                url: 'http://localhost:8080',
                isSelected: _urlController.text == 'http://localhost:8080',
              ),
              _buildPresetChip(
                label: '📱 Android Emulator',
                url: 'http://10.0.2.2:8080',
                isSelected: _urlController.text == 'http://10.0.2.2:8080',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Test connection button & results panel
          GlassPanel(
            borderRadius: 12,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            surfaceColor: const Color(0xFFF8FAFC),
            borderColor: AppColors.glassBorder,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Live Probe: ${_urlController.text.isNotEmpty ? _urlController.text : "None"}',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    InkWell(
                      onTap: _isTesting ? null : _testConnection,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isTesting)
                              const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF4F46E5),
                                ),
                              )
                            else
                              const Icon(Icons.wifi_tethering_rounded, size: 14, color: Color(0xFF4F46E5)),
                            const SizedBox(width: 6),
                            const Text(
                              'Test Ping',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF4F46E5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (_testResult != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _testSuccess ? AppColors.presentBg : AppColors.absentBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _testSuccess ? AppColors.presentBorder : AppColors.absentBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _testSuccess ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded,
                          size: 16,
                          color: _testSuccess ? AppColors.presentEmerald : AppColors.absentRose,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _testResult!,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: _testSuccess ? AppColors.presentEmerald : AppColors.absentRose,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: _resetDefault,
                child: const Text(
                  'Reset Default',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GlassButton(
                    text: 'Save & Connect',
                    icon: Icons.check_rounded,
                    onPressed: _applyNewAddress,
                    variant: GlassButtonVariant.primary,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPresetChip({
    required String label,
    required String url,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () {
        setState(() {
          _urlController.text = url;
          _testResult = null;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEEF2FF) : const Color(0xFFF1F5F9),
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
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? const Color(0xFF4F46E5) : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
