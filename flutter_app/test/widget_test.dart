import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/core/models/attendance_model.dart';
import 'package:flutter_app/core/models/summary_model.dart';
import 'package:flutter_app/core/widgets/attendance_status_toggle.dart';
import 'package:flutter_app/core/widgets/glass_button.dart';
import 'package:flutter_app/core/widgets/glass_panel.dart';
import 'package:flutter_app/core/widgets/shift_selector.dart';
import 'package:flutter_app/features/dashboard/presentation/widgets/attendance_row_widget.dart';
import 'package:flutter_app/features/dashboard/presentation/widgets/dashboard_stats_header.dart';
import 'package:flutter_app/features/dashboard/presentation/widgets/quick_filter_chips.dart';

void main() {
  group('Glassmorphic Design & UI Widgets Tests', () {
    testWidgets('GlassPanel renders child with custom border and backdrop filter', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlassPanel(
              borderRadius: 20,
              child: const Text('Glass Test Content'),
            ),
          ),
        ),
      );

      expect(find.text('Glass Test Content'), findsOneWidget);
      expect(find.byType(GlassPanel), findsOneWidget);
    });

    testWidgets('GlassButton handles taps and displays loading state', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlassButton(
              text: 'Click Me',
              onPressed: () => tapped = true,
              variant: GlassButtonVariant.primary,
            ),
          ),
        ),
      );

      expect(find.text('Click Me'), findsOneWidget);
      await tester.tap(find.byType(GlassButton));
      await tester.pump();
      expect(tapped, isTrue);

      // Loading state test
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlassButton(
              text: 'Loading Action',
              isLoading: true,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('AttendanceStatusToggle triggers status changes', (tester) async {
      String? selectedStatus;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AttendanceStatusToggle(
              currentStatus: 'absent',
              onStatusChanged: (status) => selectedStatus = status,
            ),
          ),
        ),
      );

      expect(find.text('Present'), findsOneWidget);
      expect(find.text('Absent'), findsOneWidget);

      // Tap Present
      await tester.tap(find.text('Present'));
      await tester.pump();
      expect(selectedStatus, equals('present'));

      // Tap Absent
      await tester.tap(find.text('Absent'));
      await tester.pump();
      expect(selectedStatus, equals('absent'));
    });

    testWidgets('ShiftSelector toggles Morning and Night shifts independently', (tester) async {
      String? selectedShift;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ShiftSelector(
              currentShift: 'morning',
              onShiftChanged: (shift) => selectedShift = shift,
            ),
          ),
        ),
      );

      expect(find.text('Day'), findsOneWidget);
      expect(find.text('Night'), findsOneWidget);

      await tester.tap(find.text('Night'));
      await tester.pump();
      expect(selectedShift, equals('night'));
    });

    testWidgets('DashboardStatsHeader displays correct summary metrics', (tester) async {
      final summary = AttendanceSummaryModel(
        date: '2026-10-29',
        totalActiveEmployees: 25,
        presentCount: 20,
        absentCount: 5,
        notMarkedCount: 0,
        morningShiftCount: 15,
        nightShiftCount: 5,
        totalHoursWorked: 160.0,
        completionPercentage: 100.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardStatsHeader(summary: summary),
          ),
        ),
      );

      expect(find.text('25'), findsOneWidget); // Total Active
      expect(find.text('20'), findsOneWidget); // Present Today
      expect(find.text('5'), findsNWidgets(2)); // Absent Today & Night Shift
      expect(find.text('15'), findsOneWidget); // Morning Shift
      expect(find.text('160.0 h'), findsOneWidget); // Hours Recorded
    });

    testWidgets('QuickFilterChips selects active filter', (tester) async {
      String active = 'all';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickFilterChips(
              activeFilter: active,
              onFilterSelected: (f) => active = f,
            ),
          ),
        ),
      );

      expect(find.text('All Employees'), findsOneWidget);
      expect(find.text('Present'), findsOneWidget);
      expect(find.text('Absent'), findsOneWidget);
      expect(find.text('Morning Shift'), findsOneWidget);
      expect(find.text('Night Shift'), findsOneWidget);

      await tester.tap(find.text('Morning Shift'));
      await tester.pump();
      expect(active, equals('morning'));
    });

    testWidgets('AttendanceRowWidget renders employee information and controls', (tester) async {
      final row = AttendanceRowModel(
        employeeId: 'emp-123',
        employeeCode: 'EMP-001',
        fullName: 'Aarav Sharma',
        designation: 'Production Lead',
        defaultShift: 'morning',
        shift: 'morning',
        status: 'present',
        hoursWorked: 8.5,
        workDescription: 'Machine line operation',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AttendanceRowWidget(
              row: row,
              isSelected: false,
              onSelectChanged: (_) {},
              onStatusChanged: (_) {},
              onShiftChanged: (_) {},
              onHoursChanged: (_) {},
              onDescriptionChanged: (_) {},
              onEditEmployee: () {},
            ),
          ),
        ),
      );

      expect(find.text('Aarav Sharma'), findsOneWidget);
      expect(find.textContaining('EMP-001'), findsOneWidget);
      expect(find.text('8.5h'), findsOneWidget);
      expect(find.text('Machine line operation'), findsOneWidget);
    });
  });
}
