import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_html/html.dart' as html;
import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';
import '../../auth/providers/auth_provider.dart';

final exportServiceProvider = Provider<ExportService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ExportService(apiClient: apiClient);
});

class ExportService {
  final ApiClient apiClient;

  ExportService({required this.apiClient});

  Future<String> exportAttendanceExcel({
    String? startDate,
    String? endDate,
    String? employeeId,
    String? shift,
    String? status,
  }) async {
    final queryParams = <String, dynamic>{};
    if (startDate != null && startDate.isNotEmpty) queryParams['start_date'] = startDate;
    if (endDate != null && endDate.isNotEmpty) queryParams['end_date'] = endDate;
    if (employeeId != null && employeeId.isNotEmpty) queryParams['employee_id'] = employeeId;
    if (shift != null && shift.isNotEmpty && shift != 'all') queryParams['shift'] = shift;
    if (status != null && status.isNotEmpty && status != 'all') queryParams['status'] = status;

    final response = await apiClient.dio.get<List<int>>(
      Endpoints.exportExcel,
      queryParameters: queryParams,
      options: Options(
        responseType: ResponseType.bytes,
      ),
    );

    final bytes = response.data;
    if (bytes == null || bytes.isEmpty) {
      throw Exception('Received empty Excel file from server');
    }

    final filename = 'attendance_report_${DateTime.now().millisecondsSinceEpoch}.xlsx';

    if (kIsWeb) {
      final blob = html.Blob([bytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', filename)
        ..click();
      html.Url.revokeObjectUrl(url);
      return 'Downloaded $filename';
    } else {
      Directory? dir;
      if (Platform.isAndroid) {
        dir = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
      } else {
        dir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
      }

      final filePath = '${dir.path}/$filename';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      // Attempt to open file
      try {
        await OpenFilex.open(filePath);
      } catch (_) {}

      return 'Saved to: $filePath';
    }
  }
}
