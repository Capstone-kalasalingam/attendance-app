-- migrations/006_RDM_delete_all_employees.sql
-- Remove all attendance records and employees from the database

DELETE FROM attendance_records;
DELETE FROM employees;
