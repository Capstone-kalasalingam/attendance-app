package employees

import (
	"context"
	"errors"
	"fmt"
	"strings"

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

func (r *Repository) CreateEmployee(ctx context.Context, emp *models.Employee) error {
	query := `
		INSERT INTO employees (employee_code, full_name, phone_number, designation, default_shift, notes, is_active)
		VALUES ($1, $2, $3, $4, $5, $6, $7)
		RETURNING id, created_at, updated_at
	`
	return r.pool.QueryRow(ctx, query,
		emp.EmployeeCode,
		emp.FullName,
		emp.PhoneNumber,
		emp.Designation,
		emp.DefaultShift,
		emp.Notes,
		emp.IsActive,
	).Scan(&emp.ID, &emp.CreatedAt, &emp.UpdatedAt)
}

func (r *Repository) GetEmployees(ctx context.Context, search string, activeFilter *bool) ([]models.Employee, error) {
	var conditions []string
	var args []interface{}
	idx := 1

	if activeFilter != nil {
		conditions = append(conditions, fmt.Sprintf("is_active = $%d", idx))
		args = append(args, *activeFilter)
		idx++
	}

	if search != "" {
		searchTerm := "%" + strings.ToLower(search) + "%"
		conditions = append(conditions, fmt.Sprintf("(LOWER(full_name) LIKE $%d OR LOWER(employee_code) LIKE $%d OR LOWER(COALESCE(designation, '')) LIKE $%d)", idx, idx, idx))
		args = append(args, searchTerm)
		idx++
	}

	whereClause := ""
	if len(conditions) > 0 {
		whereClause = "WHERE " + strings.Join(conditions, " AND ")
	}

	query := fmt.Sprintf(`
		SELECT id, employee_code, full_name, phone_number, designation, default_shift, notes, is_active, created_at, updated_at
		FROM employees
		%s
		ORDER BY full_name ASC
	`, whereClause)

	rows, err := r.pool.Query(ctx, query, args...)
	if err != nil {
		return nil, fmt.Errorf("failed querying employees: %w", err)
	}
	defer rows.Close()

	var employees []models.Employee
	for rows.Next() {
		var emp models.Employee
		err := rows.Scan(
			&emp.ID,
			&emp.EmployeeCode,
			&emp.FullName,
			&emp.PhoneNumber,
			&emp.Designation,
			&emp.DefaultShift,
			&emp.Notes,
			&emp.IsActive,
			&emp.CreatedAt,
			&emp.UpdatedAt,
		)
		if err != nil {
			return nil, fmt.Errorf("failed scanning employee: %w", err)
		}
		employees = append(employees, emp)
	}

	if employees == nil {
		employees = []models.Employee{}
	}

	return employees, nil
}

func (r *Repository) GetEmployeeByID(ctx context.Context, id uuid.UUID) (*models.Employee, error) {
	query := `
		SELECT id, employee_code, full_name, phone_number, designation, default_shift, notes, is_active, created_at, updated_at
		FROM employees
		WHERE id = $1
	`
	var emp models.Employee
	err := r.pool.QueryRow(ctx, query, id).Scan(
		&emp.ID,
		&emp.EmployeeCode,
		&emp.FullName,
		&emp.PhoneNumber,
		&emp.Designation,
		&emp.DefaultShift,
		&emp.Notes,
		&emp.IsActive,
		&emp.CreatedAt,
		&emp.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, fmt.Errorf("error querying employee by id: %w", err)
	}
	return &emp, nil
}

func (r *Repository) UpdateEmployee(ctx context.Context, id uuid.UUID, req *models.UpdateEmployeeRequest) (*models.Employee, error) {
	query := `
		UPDATE employees
		SET full_name = $1,
		    phone_number = $2,
		    designation = $3,
		    default_shift = $4,
		    notes = $5,
		    is_active = COALESCE($6, is_active),
		    updated_at = CURRENT_TIMESTAMP
		WHERE id = $7
		RETURNING id, employee_code, full_name, phone_number, designation, default_shift, notes, is_active, created_at, updated_at
	`
	var emp models.Employee
	err := r.pool.QueryRow(ctx, query,
		req.FullName,
		req.PhoneNumber,
		req.Designation,
		req.DefaultShift,
		req.Notes,
		req.IsActive,
		id,
	).Scan(
		&emp.ID,
		&emp.EmployeeCode,
		&emp.FullName,
		&emp.PhoneNumber,
		&emp.Designation,
		&emp.DefaultShift,
		&emp.Notes,
		&emp.IsActive,
		&emp.CreatedAt,
		&emp.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, fmt.Errorf("error updating employee: %w", err)
	}
	return &emp, nil
}

func (r *Repository) SetEmployeeStatus(ctx context.Context, id uuid.UUID, isActive bool) error {
	query := `UPDATE employees SET is_active = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2`
	tag, err := r.pool.Exec(ctx, query, isActive, id)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return errors.New("employee not found")
	}
	return nil
}
