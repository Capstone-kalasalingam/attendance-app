-- migrations/005_RDM_create_indexes_and_constraints.sql
CREATE INDEX IF NOT EXISTS idx_attendance_date ON attendance_records (attendance_date);
CREATE INDEX IF NOT EXISTS idx_attendance_emp_date ON attendance_records (employee_id, attendance_date);
CREATE INDEX IF NOT EXISTS idx_attendance_date_shift_status ON attendance_records (attendance_date, shift, status);
CREATE INDEX IF NOT EXISTS idx_employees_code ON employees (employee_code);
CREATE INDEX IF NOT EXISTS idx_employees_active_name ON employees (is_active, full_name);
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_user ON refresh_tokens (user_id);
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_hash ON refresh_tokens (token_hash);
