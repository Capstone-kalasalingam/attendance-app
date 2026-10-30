package attendance

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"

	"attendance-app/backend/internal/models"
	"github.com/google/uuid"
)

type Service struct {
	repo *Repository
}

func NewService(repo *Repository) *Service {
	return &Service{repo: repo}
}

func (s *Service) validateDate(dateStr string) error {
	_, err := time.Parse("2006-01-02", dateStr)
	if err != nil {
		return errors.New("date must be in YYYY-MM-DD format")
	}
	return nil
}

func (s *Service) GetAttendanceDashboard(ctx context.Context, dateStr string) ([]models.AttendanceRow, error) {
	if dateStr == "" {
		dateStr = time.Now().Format("2006-01-02")
	}
	if err := s.validateDate(dateStr); err != nil {
		return nil, err
	}
	return s.repo.GetAttendanceDashboardRows(ctx, dateStr)
}

func (s *Service) GetAttendanceSummary(ctx context.Context, dateStr string) (*models.AttendanceSummary, error) {
	if dateStr == "" {
		dateStr = time.Now().Format("2006-01-02")
	}
	if err := s.validateDate(dateStr); err != nil {
		return nil, err
	}
	return s.repo.GetAttendanceSummary(ctx, dateStr)
}

func (s *Service) MarkAttendance(
	ctx context.Context,
	employeeID uuid.UUID,
	dateStr string,
	shift string,
	req *models.MarkAttendanceRequest,
	adminID uuid.UUID,
) (*models.AttendanceRecord, error) {
	if err := s.validateDate(dateStr); err != nil {
		return nil, err
	}

	shift = strings.ToLower(shift)
	if shift != "morning" && shift != "night" {
		return nil, errors.New("shift must be 'morning' or 'night'")
	}

	status := strings.ToLower(req.Status)
	if status != "present" && status != "absent" {
		return nil, errors.New("status must be 'present' or 'absent'")
	}

	hours := req.HoursWorked
	if status == "absent" {
		hours = 0
	} else {
		if hours < 0 || hours > 24 {
			return nil, errors.New("hours worked must be between 0 and 24")
		}
	}

	return s.repo.UpsertAttendance(ctx, employeeID, dateStr, shift, status, hours, req.WorkDescription, adminID)
}

func (s *Service) BulkMarkAttendance(
	ctx context.Context,
	req *models.BulkAttendanceRequest,
	adminID uuid.UUID,
) ([]models.AttendanceRecord, error) {
	if err := s.validateDate(req.Date); err != nil {
		return nil, err
	}

	if len(req.Items) == 0 {
		return nil, errors.New("at least one attendance item required")
	}

	// Validate items
	for i, item := range req.Items {
		item.Shift = strings.ToLower(item.Shift)
		if item.Shift != "morning" && item.Shift != "night" {
			return nil, fmt.Errorf("item %d: invalid shift '%s'", i+1, item.Shift)
		}
		item.Status = strings.ToLower(item.Status)
		if item.Status != "present" && item.Status != "absent" {
			return nil, fmt.Errorf("item %d: invalid status '%s'", i+1, item.Status)
		}
		if item.HoursWorked < 0 || item.HoursWorked > 24 {
			return nil, fmt.Errorf("item %d: hours worked must be between 0 and 24", i+1)
		}
		req.Items[i] = item
	}

	return s.repo.BulkUpsertAttendance(ctx, req.Date, req.Items, adminID)
}

func (s *Service) GetAttendanceHistory(ctx context.Context, empIDStr, startDate, endDate string) ([]models.AttendanceRecord, error) {
	var empID *uuid.UUID
	if empIDStr != "" {
		id, err := uuid.Parse(empIDStr)
		if err != nil {
			return nil, errors.New("invalid employee ID format")
		}
		empID = &id
	}

	if startDate != "" {
		if err := s.validateDate(startDate); err != nil {
			return nil, errors.New("start_date must be in YYYY-MM-DD format")
		}
	}
	if endDate != "" {
		if err := s.validateDate(endDate); err != nil {
			return nil, errors.New("end_date must be in YYYY-MM-DD format")
		}
	}

	return s.repo.GetAttendanceHistory(ctx, empID, startDate, endDate)
}

func (s *Service) GetPayrollOverview(ctx context.Context, startDate, endDate string) (*models.PayrollOverviewResponse, error) {
	if startDate != "" {
		if err := s.validateDate(startDate); err != nil {
			return nil, errors.New("start_date must be in YYYY-MM-DD format")
		}
	}
	if endDate != "" {
		if err := s.validateDate(endDate); err != nil {
			return nil, errors.New("end_date must be in YYYY-MM-DD format")
		}
	}
	return s.repo.GetPayrollOverview(ctx, startDate, endDate)
}

