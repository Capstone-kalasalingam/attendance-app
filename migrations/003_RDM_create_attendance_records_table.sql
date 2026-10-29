-- migrations/003_RDM_create_attendance_records_table.sql
CREATE TABLE IF NOT EXISTS attendance_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    employee_id UUID NOT NULL REFERENCES employees(id) ON DELETE RESTRICT,
    attendance_date DATE NOT NULL,
    shift VARCHAR(20) NOT NULL CHECK (shift IN ('morning', 'night')),
    status VARCHAR(20) NOT NULL CHECK (status IN ('present', 'absent')),
    hours_worked NUMERIC(5, 2) NOT NULL DEFAULT 0.00 CHECK (hours_worked >= 0 AND hours_worked <= 24.00),
    work_description TEXT,
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    updated_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_attendance_emp_date_shift UNIQUE (employee_id, attendance_date, shift),
    CONSTRAINT chk_absent_hours CHECK ((status = 'absent' AND hours_worked = 0) OR (status = 'present'))
);
