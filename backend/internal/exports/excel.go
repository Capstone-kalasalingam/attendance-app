package exports

import (
	"context"
	"fmt"
	"strings"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/xuri/excelize/v2"
)

type ExcelService struct {
	pool *pgxpool.Pool
}

func NewExcelService(pool *pgxpool.Pool) *ExcelService {
	return &ExcelService{pool: pool}
}

type ExportFilter struct {
	StartDate  string
	EndDate    string
	EmployeeID string
	Shift      string
	Status     string
}

func (s *ExcelService) GenerateAttendanceWorkbook(ctx context.Context, filter ExportFilter) (*excelize.File, error) {
	f := excelize.NewFile()
	defer func() {
		// Default sheet 'Sheet1' will be renamed or replaced
	}()

	// Define cell styles
	headerStyle, err := f.NewStyle(&excelize.Style{
		Font: &excelize.Font{
			Bold:   true,
			Color:  "FFFFFF",
			Size:   11,
			Family: "Calibri",
		},
		Fill: excelize.Fill{
			Type:    "pattern",
			Color:   []string{"1E3A8A"}, // Deep Navy Blue
			Pattern: 1,
		},
		Alignment: &excelize.Alignment{
			Horizontal: "center",
			Vertical:   "center",
			WrapText:   true,
		},
		Border: []excelize.Border{
			{Type: "bottom", Color: "000000", Style: 1},
			{Type: "top", Color: "000000", Style: 1},
		},
	})
	if err != nil {
		return nil, fmt.Errorf("error creating header style: %w", err)
	}

	dataStyle, err := f.NewStyle(&excelize.Style{
		Alignment: &excelize.Alignment{
			Vertical: "center",
		},
		Border: []excelize.Border{
			{Type: "bottom", Color: "E5E7EB", Style: 1},
		},
	})
	if err != nil {
		return nil, fmt.Errorf("error creating data style: %w", err)
	}

	// -------------------------------------------------------------
	// SHEET 1: Attendance Details
	// -------------------------------------------------------------
	sheet1 := "Attendance Details"
	f.SetSheetName("Sheet1", sheet1)

	headers1 := []string{"Date", "Employee ID", "Employee Name", "Shift", "Status", "Hours Worked", "Work Description", "Last Updated"}
	for colIdx, h := range headers1 {
		cell, _ := excelize.CoordinatesToCellName(colIdx+1, 1)
		f.SetCellValue(sheet1, cell, h)
	}
	_ = f.SetRowStyle(sheet1, 1, 1, headerStyle)
	_ = f.SetRowHeight(sheet1, 1, 26)
	_ = f.SetPanes(sheet1, &excelize.Panes{
		Freeze:      true,
		Split:       false,
		XSplit:      0,
		YSplit:      1,
		TopLeftCell: "A2",
		ActivePane:  "bottomLeft",
	})

	// Build query with filters
	var conditions []string
	var args []interface{}
	idx := 1

	if filter.StartDate != "" {
		conditions = append(conditions, fmt.Sprintf("ar.attendance_date >= $%d::date", idx))
		args = append(args, filter.StartDate)
		idx++
	}
	if filter.EndDate != "" {
		conditions = append(conditions, fmt.Sprintf("ar.attendance_date <= $%d::date", idx))
		args = append(args, filter.EndDate)
		idx++
	}
	if filter.EmployeeID != "" {
		conditions = append(conditions, fmt.Sprintf("ar.employee_id = $%d::uuid", idx))
		args = append(args, filter.EmployeeID)
		idx++
	}
	if filter.Shift != "" {
		conditions = append(conditions, fmt.Sprintf("ar.shift = $%d", idx))
		args = append(args, strings.ToLower(filter.Shift))
		idx++
	}
	if filter.Status != "" {
		conditions = append(conditions, fmt.Sprintf("ar.status = $%d", idx))
		args = append(args, strings.ToLower(filter.Status))
		idx++
	}

	whereClause := ""
	if len(conditions) > 0 {
		whereClause = "WHERE " + strings.Join(conditions, " AND ")
	}

	query1 := fmt.Sprintf(`
		SELECT 
			ar.attendance_date::text,
			e.employee_code,
			e.full_name,
			UPPER(SUBSTRING(ar.shift FROM 1 FOR 1)) || SUBSTRING(ar.shift FROM 2),
			UPPER(SUBSTRING(ar.status FROM 1 FOR 1)) || SUBSTRING(ar.status FROM 2),
			ar.hours_worked,
			COALESCE(ar.work_description, ''),
			to_char(ar.updated_at, 'YYYY-MM-DD HH24:MI:SS')
		FROM attendance_records ar
		JOIN employees e ON ar.employee_id = e.id
		%s
		ORDER BY ar.attendance_date DESC, e.full_name ASC
	`, whereClause)

	rows1, err := s.pool.Query(ctx, query1, args...)
	if err != nil {
		return nil, fmt.Errorf("error querying attendance export data: %w", err)
	}
	defer rows1.Close()

	rowIdx1 := 2
	for rows1.Next() {
		var date, code, name, shift, status, desc, updated string
		var hours float64
		if err := rows1.Scan(&date, &code, &name, &shift, &status, &hours, &desc, &updated); err != nil {
			return nil, err
		}

		f.SetCellValue(sheet1, fmt.Sprintf("A%d", rowIdx1), date)
		f.SetCellValue(sheet1, fmt.Sprintf("B%d", rowIdx1), code)
		f.SetCellValue(sheet1, fmt.Sprintf("C%d", rowIdx1), name)
		f.SetCellValue(sheet1, fmt.Sprintf("D%d", rowIdx1), shift)
		f.SetCellValue(sheet1, fmt.Sprintf("E%d", rowIdx1), status)
		f.SetCellValue(sheet1, fmt.Sprintf("F%d", rowIdx1), hours)
		f.SetCellValue(sheet1, fmt.Sprintf("G%d", rowIdx1), desc)
		f.SetCellValue(sheet1, fmt.Sprintf("H%d", rowIdx1), updated)
		_ = f.SetRowStyle(sheet1, rowIdx1, rowIdx1, dataStyle)
		rowIdx1++
	}

	// Auto-fit column widths
	colWidths1 := map[string]float64{
		"A": 14, "B": 16, "C": 24, "D": 14, "E": 14, "F": 16, "G": 28, "H": 22,
	}
	for col, width := range colWidths1 {
		_ = f.SetColWidth(sheet1, col, col, width)
	}

	// -------------------------------------------------------------
	// SHEET 2: Daily Summary
	// -------------------------------------------------------------
	sheet2 := "Daily Summary"
	f.NewSheet(sheet2)

	headers2 := []string{
		"Date", "Total Active Employees", "Present", "Absent", "Not Marked",
		"Morning Shift Count", "Night Shift Count", "Total Hours Worked", "Attendance Completion %",
	}
	for colIdx, h := range headers2 {
		cell, _ := excelize.CoordinatesToCellName(colIdx+1, 1)
		f.SetCellValue(sheet2, cell, h)
	}
	_ = f.SetRowStyle(sheet2, 1, 1, headerStyle)
	_ = f.SetRowHeight(sheet2, 1, 26)
	_ = f.SetPanes(sheet2, &excelize.Panes{
		Freeze:      true,
		Split:       false,
		XSplit:      0,
		YSplit:      1,
		TopLeftCell: "A2",
		ActivePane:  "bottomLeft",
	})

	query2 := `
		SELECT 
			ar.attendance_date::text,
			(SELECT COUNT(*) FROM employees WHERE is_active = true) AS total_active,
			COUNT(DISTINCT CASE WHEN ar.status = 'present' THEN ar.employee_id END) AS present_count,
			COUNT(DISTINCT CASE WHEN ar.status = 'absent' THEN ar.employee_id END) AS absent_count,
			COUNT(CASE WHEN ar.shift = 'morning' AND ar.status = 'present' THEN 1 END) AS morning_count,
			COUNT(CASE WHEN ar.shift = 'night' AND ar.status = 'present' THEN 1 END) AS night_count,
			COALESCE(SUM(CASE WHEN ar.status = 'present' THEN ar.hours_worked ELSE 0 END), 0.0) AS total_hours
		FROM attendance_records ar
		WHERE ($1 = '' OR ar.attendance_date >= $1::date)
		  AND ($2 = '' OR ar.attendance_date <= $2::date)
		GROUP BY ar.attendance_date
		ORDER BY ar.attendance_date DESC
	`
	rows2, err := s.pool.Query(ctx, query2, filter.StartDate, filter.EndDate)
	if err != nil {
		return nil, fmt.Errorf("error querying daily summary: %w", err)
	}
	defer rows2.Close()

	rowIdx2 := 2
	for rows2.Next() {
		var date string
		var totalActive, present, absent, morning, night int
		var totalHours float64

		if err := rows2.Scan(&date, &totalActive, &present, &absent, &morning, &night, &totalHours); err != nil {
			return nil, err
		}

		notMarked := totalActive - (present + absent)
		if notMarked < 0 {
			notMarked = 0
		}
		completion := 0.0
		if totalActive > 0 {
			completion = (float64(present+absent) / float64(totalActive)) * 100.0
		}

		f.SetCellValue(sheet2, fmt.Sprintf("A%d", rowIdx2), date)
		f.SetCellValue(sheet2, fmt.Sprintf("B%d", rowIdx2), totalActive)
		f.SetCellValue(sheet2, fmt.Sprintf("C%d", rowIdx2), present)
		f.SetCellValue(sheet2, fmt.Sprintf("D%d", rowIdx2), absent)
		f.SetCellValue(sheet2, fmt.Sprintf("E%d", rowIdx2), notMarked)
		f.SetCellValue(sheet2, fmt.Sprintf("F%d", rowIdx2), morning)
		f.SetCellValue(sheet2, fmt.Sprintf("G%d", rowIdx2), night)
		f.SetCellValue(sheet2, fmt.Sprintf("H%d", rowIdx2), totalHours)
		f.SetCellValue(sheet2, fmt.Sprintf("I%d", rowIdx2), fmt.Sprintf("%.1f%%", completion))
		_ = f.SetRowStyle(sheet2, rowIdx2, rowIdx2, dataStyle)
		rowIdx2++
	}

	colWidths2 := map[string]float64{
		"A": 14, "B": 22, "C": 12, "D": 12, "E": 14, "F": 20, "G": 18, "H": 18, "I": 24,
	}
	for col, width := range colWidths2 {
		_ = f.SetColWidth(sheet2, col, col, width)
	}

	// -------------------------------------------------------------
	// SHEET 3: Employee Summary
	// -------------------------------------------------------------
	sheet3 := "Employee Summary"
	f.NewSheet(sheet3)

	headers3 := []string{
		"Employee ID", "Employee Name", "Designation", "Total Present Days",
		"Total Absent Days", "Total Hours Worked", "Morning Shift Count", "Night Shift Count",
	}
	for colIdx, h := range headers3 {
		cell, _ := excelize.CoordinatesToCellName(colIdx+1, 1)
		f.SetCellValue(sheet3, cell, h)
	}
	_ = f.SetRowStyle(sheet3, 1, 1, headerStyle)
	_ = f.SetRowHeight(sheet3, 1, 26)
	_ = f.SetPanes(sheet3, &excelize.Panes{
		Freeze:      true,
		Split:       false,
		XSplit:      0,
		YSplit:      1,
		TopLeftCell: "A2",
		ActivePane:  "bottomLeft",
	})

	query3 := `
		SELECT 
			e.employee_code,
			e.full_name,
			COALESCE(e.designation, ''),
			COUNT(DISTINCT CASE WHEN ar.status = 'present' THEN ar.attendance_date END) AS present_days,
			COUNT(DISTINCT CASE WHEN ar.status = 'absent' THEN ar.attendance_date END) AS absent_days,
			COALESCE(SUM(CASE WHEN ar.status = 'present' THEN ar.hours_worked ELSE 0 END), 0.0) AS total_hours,
			COUNT(CASE WHEN ar.shift = 'morning' AND ar.status = 'present' THEN 1 END) AS morning_count,
			COUNT(CASE WHEN ar.shift = 'night' AND ar.status = 'present' THEN 1 END) AS night_count
		FROM employees e
		LEFT JOIN attendance_records ar 
			ON e.id = ar.employee_id 
			AND ($1 = '' OR ar.attendance_date >= $1::date)
			AND ($2 = '' OR ar.attendance_date <= $2::date)
		WHERE e.is_active = true
		  AND ($3 = '' OR e.id = $3::uuid)
		GROUP BY e.id, e.employee_code, e.full_name, e.designation
		ORDER BY e.full_name ASC
	`
	rows3, err := s.pool.Query(ctx, query3, filter.StartDate, filter.EndDate, filter.EmployeeID)
	if err != nil {
		return nil, fmt.Errorf("error querying employee summary: %w", err)
	}
	defer rows3.Close()

	rowIdx3 := 2
	for rows3.Next() {
		var code, name, designation string
		var presentDays, absentDays, morningCount, nightCount int
		var totalHours float64

		if err := rows3.Scan(&code, &name, &designation, &presentDays, &absentDays, &totalHours, &morningCount, &nightCount); err != nil {
			return nil, err
		}

		f.SetCellValue(sheet3, fmt.Sprintf("A%d", rowIdx3), code)
		f.SetCellValue(sheet3, fmt.Sprintf("B%d", rowIdx3), name)
		f.SetCellValue(sheet3, fmt.Sprintf("C%d", rowIdx3), designation)
		f.SetCellValue(sheet3, fmt.Sprintf("D%d", rowIdx3), presentDays)
		f.SetCellValue(sheet3, fmt.Sprintf("E%d", rowIdx3), absentDays)
		f.SetCellValue(sheet3, fmt.Sprintf("F%d", rowIdx3), totalHours)
		f.SetCellValue(sheet3, fmt.Sprintf("G%d", rowIdx3), morningCount)
		f.SetCellValue(sheet3, fmt.Sprintf("H%d", rowIdx3), nightCount)
		_ = f.SetRowStyle(sheet3, rowIdx3, rowIdx3, dataStyle)
		rowIdx3++
	}

	colWidths3 := map[string]float64{
		"A": 16, "B": 24, "C": 20, "D": 18, "E": 18, "F": 18, "G": 20, "H": 18,
	}
	for col, width := range colWidths3 {
		_ = f.SetColWidth(sheet3, col, col, width)
	}

	return f, nil
}
