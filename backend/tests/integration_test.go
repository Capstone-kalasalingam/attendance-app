package tests

import (
	"context"
	"testing"
	"time"

	"attendance-app/backend/internal/attendance"
	"attendance-app/backend/internal/auth"
	"attendance-app/backend/internal/config"
	"attendance-app/backend/internal/database"
	"attendance-app/backend/internal/employees"
	"attendance-app/backend/internal/exports"
	"attendance-app/backend/internal/models"
)

func TestLiveDatabaseIntegrationFlows(t *testing.T) {
	cfg := config.LoadConfig()
	ctx, cancel := context.WithTimeout(context.Background(), 25*time.Second)
	defer cancel()

	pool, err := database.NewPostgresPool(ctx, cfg.DatabaseURL)
	if err != nil {
		t.Fatalf("Failed connecting to test database: %v", err)
	}
	defer pool.Close()

	// 1. Test Admin Login
	authRepo := auth.NewRepository(pool)
	authService := auth.NewService(authRepo, cfg)

	loginResp, err := authService.Login(ctx, "admin", "Admin@123456")
	if err != nil {
		t.Fatalf("Admin login failed: %v", err)
	}
	if loginResp.AccessToken == "" || loginResp.User.Role != "admin" {
		t.Fatalf("Invalid login response: %+v", loginResp)
	}

	// 2. Test Fetching Employees
	empRepo := employees.NewRepository(pool)
	empService := employees.NewService(empRepo)

	active := true
	empList, err := empService.GetEmployees(ctx, "", &active)
	if err != nil {
		t.Fatalf("Failed to fetch employees: %v", err)
	}
	if len(empList) == 0 {
		t.Fatal("Expected seeded employees, got 0")
	}

	firstEmp := empList[0]

	// 3. Test Attendance Dashboard Row
	attRepo := attendance.NewRepository(pool)
	attService := attendance.NewService(attRepo)

	today := time.Now().Format("2006-01-02")
	dashboardRows, err := attService.GetAttendanceDashboard(ctx, today)
	if err != nil {
		t.Fatalf("Failed to get attendance dashboard: %v", err)
	}
	if len(dashboardRows) == 0 {
		t.Fatal("Expected dashboard rows for employees, got 0")
	}

	// 4. Test Marking Attendance (Present, 8.5 hours, Morning shift)
	desc := "Integration test machine operation"
	markReq := &models.MarkAttendanceRequest{
		Shift:           "morning",
		Status:          "present",
		HoursWorked:     8.5,
		WorkDescription: &desc,
	}

	rec, err := attService.MarkAttendance(ctx, firstEmp.ID, today, "morning", markReq, loginResp.User.ID)
	if err != nil {
		t.Fatalf("Failed to mark attendance: %v", err)
	}
	if rec.Status != "present" || rec.HoursWorked != 8.5 {
		t.Fatalf("Attendance record mismatch: %+v", rec)
	}

	// 5. Test Summary Calculations
	summary, err := attService.GetAttendanceSummary(ctx, today)
	if err != nil {
		t.Fatalf("Failed to fetch summary: %v", err)
	}
	if summary.TotalActiveEmployees == 0 || summary.PresentCount == 0 {
		t.Fatalf("Summary values unexpected: %+v", summary)
	}

	// 6. Test Excel Export Generation
	excelService := exports.NewExcelService(pool)
	wb, err := excelService.GenerateAttendanceWorkbook(ctx, exports.ExportFilter{
		StartDate: today,
		EndDate:   today,
	})
	if err != nil {
		t.Fatalf("Failed generating Excel workbook: %v", err)
	}
	defer wb.Close()

	sheets := wb.GetSheetList()
	if len(sheets) != 3 {
		t.Fatalf("Expected 3 sheets in Excel, got %d", len(sheets))
	}

	t.Logf("Integration tests passed successfully! Employees: %d, Present: %d, Summary Total Hours: %.2f",
		summary.TotalActiveEmployees, summary.PresentCount, summary.TotalHoursWorked)
}
