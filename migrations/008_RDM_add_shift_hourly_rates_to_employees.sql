-- migrations/008_RDM_add_shift_hourly_rates_to_employees.sql
-- Add shift-specific hourly rates (day/morning shift and night shift) to employees table

ALTER TABLE employees
ADD COLUMN IF NOT EXISTS hourly_rate_morning NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
ADD COLUMN IF NOT EXISTS hourly_rate_night NUMERIC(10, 2) NOT NULL DEFAULT 0.00;
