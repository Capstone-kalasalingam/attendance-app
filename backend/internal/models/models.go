package models

import (
	"time"

	"github.com/google/uuid"
)

type User struct {
	ID           uuid.UUID `json:"id"`
	Username     string    `json:"username"`
	Email        *string   `json:"email"`
	PasswordHash string    `json:"-"`
	Role         string    `json:"role"`
	IsActive     bool      `json:"is_active"`
	CreatedAt    time.Time `json:"created_at"`
	UpdatedAt    time.Time `json:"updated_at"`
}

type Employee struct {
	ID           uuid.UUID `json:"id"`
	EmployeeCode string    `json:"employee_code"`
	FullName     string    `json:"full_name"`
	PhoneNumber  *string   `json:"phone_number"`
	Designation  *string   `json:"designation"`
	DefaultShift string    `json:"default_shift"` // "morning" or "night"
	Notes        *string   `json:"notes"`
	IsActive     bool      `json:"is_active"`
	CreatedAt    time.Time `json:"created_at"`
	UpdatedAt    time.Time `json:"updated_at"`
}

type AttendanceRecord struct {
	ID              uuid.UUID  `json:"id"`
	EmployeeID      uuid.UUID  `json:"employee_id"`
	AttendanceDate  string     `json:"attendance_date"` // YYYY-MM-DD
	Shift           string     `json:"shift"`           // "morning" or "night"
	Status          string     `json:"status"`          // "present" or "absent"
	HoursWorked     float64    `json:"hours_worked"`
	WorkDescription *string    `json:"work_description"`
	CreatedBy       *uuid.UUID `json:"created_by,omitempty"`
	UpdatedBy       *uuid.UUID `json:"updated_by,omitempty"`
	CreatedAt       time.Time  `json:"created_at"`
	UpdatedAt       time.Time  `json:"updated_at"`
}

// AttendanceRow provides everything needed in the single dashboard view for an employee
type AttendanceRow struct {
	EmployeeID      uuid.UUID `json:"employee_id"`
	EmployeeCode    string    `json:"employee_code"`
	FullName        string    `json:"full_name"`
	Designation     *string   `json:"designation"`
	DefaultShift    string    `json:"default_shift"`
	Shift           string    `json:"shift"`          // Active/assigned shift for this record or default
	Status          *string   `json:"status"`         // "present", "absent", or nil (not marked)
	HoursWorked     float64   `json:"hours_worked"`   // 0.0 if absent or not marked
	WorkDescription *string   `json:"work_description"`
	RecordID        *uuid.UUID `json:"record_id"`
	LastUpdated     *time.Time `json:"last_updated"`
}

type AttendanceSummary struct {
	Date                 string  `json:"date"`
	TotalActiveEmployees int     `json:"total_active_employees"`
	PresentCount         int     `json:"present_count"`
	AbsentCount          int     `json:"absent_count"`
	NotMarkedCount       int     `json:"not_marked_count"`
	MorningShiftCount    int     `json:"morning_shift_count"`
	NightShiftCount      int     `json:"night_shift_count"`
	TotalHoursWorked     float64 `json:"total_hours_worked"`
	CompletionPercentage float64 `json:"completion_percentage"`
}

// DTOs
type LoginRequest struct {
	Username string `json:"username" binding:"required"`
	Password string `json:"password" binding:"required"`
}

type LoginResponse struct {
	AccessToken  string `json:"access_token"`
	RefreshToken string `json:"refresh_token"`
	ExpiresIn    int64  `json:"expires_in"` // seconds
	User         User   `json:"user"`
}

type RefreshRequest struct {
	RefreshToken string `json:"refresh_token" binding:"required"`
}

type CreateEmployeeRequest struct {
	EmployeeCode string  `json:"employee_code" binding:"required"`
	FullName     string  `json:"full_name" binding:"required"`
	PhoneNumber  *string `json:"phone_number"`
	Designation  *string `json:"designation"`
	DefaultShift string  `json:"default_shift" binding:"required,oneof=morning night"`
	Notes        *string `json:"notes"`
}

type UpdateEmployeeRequest struct {
	FullName     string  `json:"full_name" binding:"required"`
	PhoneNumber  *string `json:"phone_number"`
	Designation  *string `json:"designation"`
	DefaultShift string  `json:"default_shift" binding:"required,oneof=morning night"`
	Notes        *string `json:"notes"`
	IsActive     *bool   `json:"is_active"`
}

type MarkAttendanceRequest struct {
	Shift           string  `json:"shift" binding:"required,oneof=morning night"`
	Status          string  `json:"status" binding:"required,oneof=present absent"`
	HoursWorked     float64 `json:"hours_worked" binding:"min=0,max=24"`
	WorkDescription *string `json:"work_description"`
}

type BulkAttendanceItem struct {
	EmployeeID      uuid.UUID `json:"employee_id" binding:"required"`
	Shift           string    `json:"shift" binding:"required,oneof=morning night"`
	Status          string    `json:"status" binding:"required,oneof=present absent"`
	HoursWorked     float64   `json:"hours_worked" binding:"min=0,max=24"`
	WorkDescription *string   `json:"work_description"`
}

type BulkAttendanceRequest struct {
	Date  string               `json:"date" binding:"required"`
	Items []BulkAttendanceItem `json:"items" binding:"required,min=1"`
}
