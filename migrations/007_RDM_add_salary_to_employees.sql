-- migrations/007_RDM_add_salary_to_employees.sql
-- Add salary configuration fields to employees table

ALTER TABLE employees
ADD COLUMN IF NOT EXISTS daily_rate NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
ADD COLUMN IF NOT EXISTS salary_type VARCHAR(20) NOT NULL DEFAULT 'daily' CHECK (salary_type IN ('daily', 'hourly', 'monthly'));
