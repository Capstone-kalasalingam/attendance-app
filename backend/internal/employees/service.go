package employees

import (
	"context"
	"errors"
	"fmt"
	"strings"

	"attendance-app/backend/internal/models"
	"github.com/google/uuid"
)

type Service struct {
	repo *Repository
}

func NewService(repo *Repository) *Service {
	return &Service{repo: repo}
}

func (s *Service) CreateEmployee(ctx context.Context, req *models.CreateEmployeeRequest) (*models.Employee, error) {
	code := strings.TrimSpace(req.EmployeeCode)
	name := strings.TrimSpace(req.FullName)

	if code == "" {
		return nil, errors.New("employee code is required")
	}
	if name == "" {
		return nil, errors.New("employee full name is required")
	}

	shift := strings.ToLower(req.DefaultShift)
	if shift != "morning" && shift != "night" {
		shift = "morning"
	}

	emp := &models.Employee{
		EmployeeCode:      code,
		FullName:          name,
		PhoneNumber:       req.PhoneNumber,
		Designation:       req.Designation,
		DefaultShift:      shift,
		Notes:             req.Notes,
		HourlyRateMorning: req.HourlyRateMorning,
		HourlyRateNight:   req.HourlyRateNight,
		IsActive:          true,
	}

	if err := s.repo.CreateEmployee(ctx, emp); err != nil {
		if strings.Contains(err.Error(), "duplicate key") || strings.Contains(err.Error(), "unique") {
			return nil, fmt.Errorf("employee with code '%s' already exists", code)
		}
		return nil, fmt.Errorf("failed to create employee: %w", err)
	}

	return emp, nil
}

func (s *Service) GetEmployees(ctx context.Context, search string, activeFilter *bool) ([]models.Employee, error) {
	return s.repo.GetEmployees(ctx, search, activeFilter)
}

func (s *Service) GetEmployeeByID(ctx context.Context, id uuid.UUID) (*models.Employee, error) {
	return s.repo.GetEmployeeByID(ctx, id)
}

func (s *Service) UpdateEmployee(ctx context.Context, id uuid.UUID, req *models.UpdateEmployeeRequest) (*models.Employee, error) {
	name := strings.TrimSpace(req.FullName)
	if name == "" {
		return nil, errors.New("employee full name cannot be empty")
	}

	shift := strings.ToLower(req.DefaultShift)
	if shift != "morning" && shift != "night" {
		return nil, errors.New("default shift must be 'morning' or 'night'")
	}
	req.DefaultShift = shift

	return s.repo.UpdateEmployee(ctx, id, req)
}

func (s *Service) SetEmployeeStatus(ctx context.Context, id uuid.UUID, isActive bool) error {
	return s.repo.SetEmployeeStatus(ctx, id, isActive)
}
