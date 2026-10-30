package attendance

import (
	"context"
	"errors"
	"fmt"

	"attendance-app/backend/internal/models"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type Repository struct {
	pool *pgxpool.Pool
}

func NewRepository(pool *pgxpool.Pool) *Repository {
	return &Repository{pool: pool}
}

// GetAttendanceDashboardRows returns all active employees with any existing attendance records for the given date.
// If an employee has a record for that date, it returns the recorded shift and status.
// If multiple shifts exist for that employee on that date, it returns them cleanly.
func (r *Repository) GetAttendanceDashboardRows(ctx context.Context, dateStr string) ([]models.AttendanceRow, error) {
	query := `
		SELECT 
			e.id AS employee_id,
			e.employee_code,
			e.full_name,
			e.designation,
			e.default_shift,
			COALESCE(ar.shift, e.default_shift) AS shift,
			ar.status,
			COALESCE(ar.hours_worked, 0.0) AS hours_worked,
			e.hourly_rate_morning,
			e.hourly_rate_night,
			CASE 
				WHEN ar.status = 'present' THEN
					COALESCE(ar.hours_worked, 0.0) * (CASE WHEN COALESCE(ar.shift, e.default_shift) = 'night' THEN e.hourly_rate_night ELSE e.hourly_rate_morning END)
				ELSE 0.0 
			END AS daily_salary,
			ar.work_description,
			ar.id AS record_id,
			ar.updated_at AS last_updated
		FROM employees e
		LEFT JOIN attendance_records ar 
			ON e.id = ar.employee_id AND ar.attendance_date = $1::date
		WHERE e.is_active = true
		ORDER BY e.full_name ASC, ar.created_at ASC
	`
	rows, err := r.pool.Query(ctx, query, dateStr)
	if err != nil {
		return nil, fmt.Errorf("error querying attendance dashboard rows: %w", err)
	}
	defer rows.Close()

	var result []models.AttendanceRow
	for rows.Next() {
		var row models.AttendanceRow
		err := rows.Scan(
			&row.EmployeeID,
			&row.EmployeeCode,
			&row.FullName,
			&row.Designation,
			&row.DefaultShift,
			&row.Shift,
			&row.Status,
			&row.HoursWorked,
			&row.HourlyRateMorning,
			&row.HourlyRateNight,
			&row.DailySalary,
			&row.WorkDescription,
			&row.RecordID,
			&row.LastUpdated,
		)
		if err != nil {
			return nil, fmt.Errorf("error scanning attendance row: %w", err)
		}
		result = append(result, row)
	}

	if result == nil {
		result = []models.AttendanceRow{}
	}

	return result, nil
}

// GetAttendanceSummary computes live attendance statistics for the date.
func (r *Repository) GetAttendanceSummary(ctx context.Context, dateStr string) (*models.AttendanceSummary, error) {
	summary := &models.AttendanceSummary{Date: dateStr}

	// 1. Total active employees
	err := r.pool.QueryRow(ctx, "SELECT COUNT(*) FROM employees WHERE is_active = true").Scan(&summary.TotalActiveEmployees)
	if err != nil {
		return nil, fmt.Errorf("failed counting active employees: %w", err)
	}

	// 2. Unique present and absent counts for the date
	queryCounts := `
		SELECT 
			COUNT(DISTINCT CASE WHEN status = 'present' THEN employee_id END) AS present_count,
			COUNT(DISTINCT CASE WHEN status = 'absent' THEN employee_id END) AS absent_count,
			COUNT(CASE WHEN shift = 'morning' AND status = 'present' THEN 1 END) AS morning_count,
			COUNT(CASE WHEN shift = 'night' AND status = 'present' THEN 1 END) AS night_count,
			COALESCE(SUM(CASE WHEN status = 'present' THEN hours_worked ELSE 0 END), 0.0) AS total_hours
		FROM attendance_records
		WHERE attendance_date = $1::date
		  AND employee_id IN (SELECT id FROM employees WHERE is_active = true)
	`
	err = r.pool.QueryRow(ctx, queryCounts, dateStr).Scan(
		&summary.PresentCount,
		&summary.AbsentCount,
		&summary.MorningShiftCount,
		&summary.NightShiftCount,
		&summary.TotalHoursWorked,
	)
	if err != nil {
		return nil, fmt.Errorf("failed calculating attendance counts: %w", err)
	}

	// 3. Not marked count = Total active employees - (distinct employees with attendance records today)
	var markedDistinct int
	err = r.pool.QueryRow(ctx, `
		SELECT COUNT(DISTINCT employee_id) 
		FROM attendance_records 
		WHERE attendance_date = $1::date
		  AND employee_id IN (SELECT id FROM employees WHERE is_active = true)
	`, dateStr).Scan(&markedDistinct)
	if err != nil {
		return nil, fmt.Errorf("failed calculating marked distinct: %w", err)
	}

	summary.NotMarkedCount = summary.TotalActiveEmployees - markedDistinct
	if summary.NotMarkedCount < 0 {
		summary.NotMarkedCount = 0
	}

	if summary.TotalActiveEmployees > 0 {
		summary.CompletionPercentage = (float64(markedDistinct) / float64(summary.TotalActiveEmployees)) * 100.0
	}

	return summary, nil
}

// UpsertAttendance creates or updates an attendance record for employee + date + shift.
func (r *Repository) UpsertAttendance(
	ctx context.Context,
	employeeID uuid.UUID,
	dateStr string,
	shift string,
	status string,
	hoursWorked float64,
	workDesc *string,
	adminID uuid.UUID,
) (*models.AttendanceRecord, error) {
	if status == "absent" {
		hoursWorked = 0
	}

	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx)

	// Verify employee is active
	var isActive bool
	err = tx.QueryRow(ctx, "SELECT is_active FROM employees WHERE id = $1", employeeID).Scan(&isActive)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, errors.New("employee not found")
		}
		return nil, err
	}
	if !isActive {
		return nil, errors.New("cannot record attendance for inactive employee")
	}

	query := `
		INSERT INTO attendance_records (
			employee_id, attendance_date, shift, status, hours_worked, work_description, created_by, updated_by
		)
		VALUES ($1, $2::date, $3, $4, $5, $6, $7, $7)
		ON CONFLICT (employee_id, attendance_date, shift)
		DO UPDATE SET
			status = EXCLUDED.status,
			hours_worked = EXCLUDED.hours_worked,
			work_description = EXCLUDED.work_description,
			updated_by = EXCLUDED.updated_by,
			updated_at = CURRENT_TIMESTAMP
		RETURNING id, employee_id, attendance_date::text, shift, status, hours_worked, work_description, created_by, updated_by, created_at, updated_at
	`

	var rec models.AttendanceRecord
	err = tx.QueryRow(ctx, query,
		employeeID,
		dateStr,
		shift,
		status,
		hoursWorked,
		workDesc,
		adminID,
	).Scan(
		&rec.ID,
		&rec.EmployeeID,
		&rec.AttendanceDate,
		&rec.Shift,
		&rec.Status,
		&rec.HoursWorked,
		&rec.WorkDescription,
		&rec.CreatedBy,
		&rec.UpdatedBy,
		&rec.CreatedAt,
		&rec.UpdatedAt,
	)
	if err != nil {
		return nil, fmt.Errorf("error upserting attendance: %w", err)
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}

	return &rec, nil
}

// BulkUpsertAttendance processes multiple records transactionally.
func (r *Repository) BulkUpsertAttendance(
	ctx context.Context,
	dateStr string,
	items []models.BulkAttendanceItem,
	adminID uuid.UUID,
) ([]models.AttendanceRecord, error) {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx)

	var results []models.AttendanceRecord

	query := `
		INSERT INTO attendance_records (
			employee_id, attendance_date, shift, status, hours_worked, work_description, created_by, updated_by
		)
		VALUES ($1, $2::date, $3, $4, $5, $6, $7, $7)
		ON CONFLICT (employee_id, attendance_date, shift)
		DO UPDATE SET
			status = EXCLUDED.status,
			hours_worked = EXCLUDED.hours_worked,
			work_description = EXCLUDED.work_description,
			updated_by = EXCLUDED.updated_by,
			updated_at = CURRENT_TIMESTAMP
		RETURNING id, employee_id, attendance_date::text, shift, status, hours_worked, work_description, created_by, updated_by, created_at, updated_at
	`

	for _, item := range items {
		hw := item.HoursWorked
		if item.Status == "absent" {
			hw = 0
		}

		var rec models.AttendanceRecord
		err := tx.QueryRow(ctx, query,
			item.EmployeeID,
			dateStr,
			item.Shift,
			item.Status,
			hw,
			item.WorkDescription,
			adminID,
		).Scan(
			&rec.ID,
			&rec.EmployeeID,
			&rec.AttendanceDate,
			&rec.Shift,
			&rec.Status,
			&rec.HoursWorked,
			&rec.WorkDescription,
			&rec.CreatedBy,
			&rec.UpdatedBy,
			&rec.CreatedAt,
			&rec.UpdatedAt,
		)
		if err != nil {
			return nil, fmt.Errorf("failed bulk upsert for employee %s: %w", item.EmployeeID, err)
		}
		results = append(results, rec)
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}

	return results, nil
}

// GetAttendanceHistory returns records filtered by employee and/or date range.
func (r *Repository) GetAttendanceHistory(ctx context.Context, employeeID *uuid.UUID, startDate, endDate string) ([]models.AttendanceRecord, error) {
	query := `
		SELECT id, employee_id, attendance_date::text, shift, status, hours_worked, work_description, created_by, updated_by, created_at, updated_at
		FROM attendance_records
		WHERE ($1::uuid IS NULL OR employee_id = $1)
		  AND ($2 = '' OR attendance_date >= $2::date)
		  AND ($3 = '' OR attendance_date <= $3::date)
		ORDER BY attendance_date DESC, created_at DESC
	`
	rows, err := r.pool.Query(ctx, query, employeeID, startDate, endDate)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var records []models.AttendanceRecord
	for rows.Next() {
		var rec models.AttendanceRecord
		err := rows.Scan(
			&rec.ID,
			&rec.EmployeeID,
			&rec.AttendanceDate,
			&rec.Shift,
			&rec.Status,
			&rec.HoursWorked,
			&rec.WorkDescription,
			&rec.CreatedBy,
			&rec.UpdatedBy,
			&rec.CreatedAt,
			&rec.UpdatedAt,
		)
		if err != nil {
			return nil, err
		}
		records = append(records, rec)
	}

	return records, nil
}

func (r *Repository) GetPayrollOverview(ctx context.Context, startDate, endDate string) (*models.PayrollOverviewResponse, error) {
	overview := &models.PayrollOverviewResponse{
		StartDate: startDate,
		EndDate:   endDate,
		Employees: []models.EmployeeSalarySummary{},
	}

	query := `
		SELECT 
			e.id,
			e.employee_code,
			e.full_name,
			e.designation,
			e.hourly_rate_morning,
			e.hourly_rate_night,
			COALESCE(SUM(CASE WHEN ar.shift = 'morning' AND ar.status = 'present' THEN ar.hours_worked ELSE 0 END), 0.0) AS morning_hours,
			COALESCE(SUM(CASE WHEN ar.shift = 'night' AND ar.status = 'present' THEN ar.hours_worked ELSE 0 END), 0.0) AS night_hours,
			COALESCE(SUM(CASE WHEN ar.status = 'present' THEN ar.hours_worked ELSE 0 END), 0.0) AS total_hours,
			COUNT(DISTINCT CASE WHEN ar.status = 'present' THEN ar.attendance_date END) AS present_days,
			COUNT(DISTINCT CASE WHEN ar.status = 'absent' THEN ar.attendance_date END) AS absent_days
		FROM employees e
		LEFT JOIN attendance_records ar 
			ON e.id = ar.employee_id 
			AND ($1 = '' OR ar.attendance_date >= $1::date)
			AND ($2 = '' OR ar.attendance_date <= $2::date)
		WHERE e.is_active = true
		GROUP BY e.id, e.employee_code, e.full_name, e.designation, e.hourly_rate_morning, e.hourly_rate_night
		ORDER BY e.full_name ASC
	`
	rows, err := r.pool.Query(ctx, query, startDate, endDate)
	if err != nil {
		return nil, fmt.Errorf("error querying payroll overview: %w", err)
	}
	defer rows.Close()

	for rows.Next() {
		var emp models.EmployeeSalarySummary
		err := rows.Scan(
			&emp.EmployeeID,
			&emp.EmployeeCode,
			&emp.FullName,
			&emp.Designation,
			&emp.HourlyRateMorning,
			&emp.HourlyRateNight,
			&emp.MorningHours,
			&emp.NightHours,
			&emp.TotalHours,
			&emp.PresentDays,
			&emp.AbsentDays,
		)
		if err != nil {
			return nil, fmt.Errorf("error scanning employee payroll summary: %w", err)
		}

		emp.MorningSalary = emp.MorningHours * emp.HourlyRateMorning
		emp.NightSalary = emp.NightHours * emp.HourlyRateNight
		emp.TotalSalary = emp.MorningSalary + emp.NightSalary

		overview.MorningHours += emp.MorningHours
		overview.NightHours += emp.NightHours
		overview.TotalHours += emp.TotalHours
		overview.TotalPayroll += emp.TotalSalary
		overview.TotalPresent += emp.PresentDays

		overview.Employees = append(overview.Employees, emp)
	}

	return overview, nil
}

