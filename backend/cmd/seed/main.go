package main

import (
	"context"
	"fmt"
	"log"
	"math/rand"
	"time"

	"attendance-app/backend/internal/config"
	"attendance-app/backend/internal/database"
)

func main() {
	log.Println("Seeding sample development data...")

	cfg := config.LoadConfig()
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	pool, err := database.NewPostgresPool(ctx, cfg.DatabaseURL)
	if err != nil {
		log.Fatalf("Database connection failed: %v", err)
	}
	defer pool.Close()

	sampleEmployees := []struct {
		code  string
		name  string
		phone string
		desig string
		shift string
	}{
		{"EMP-001", "Aarav Sharma", "+91 98765 43210", "Production Lead", "morning"},
		{"EMP-002", "Priya Patel", "+91 98765 43211", "Machine Operator", "morning"},
		{"EMP-003", "Rahul Verma", "+91 98765 43212", "Quality Inspector", "morning"},
		{"EMP-004", "Ananya Iyer", "+91 98765 43213", "Assembly Technician", "morning"},
		{"EMP-005", "Vikram Singh", "+91 98765 43214", "Logistics Executive", "night"},
		{"EMP-006", "Sneha Reddy", "+91 98765 43215", "Packaging Supervisor", "morning"},
		{"EMP-007", "Rohan Das", "+91 98765 43216", "Maintenance Engineer", "night"},
		{"EMP-008", "Kavita Joshi", "+91 98765 43217", "Store In-charge", "morning"},
		{"EMP-009", "Amit Kumar", "+91 98765 43218", "Forklift Driver", "night"},
		{"EMP-010", "Pooja Hegde", "+91 98765 43219", "Safety Officer", "morning"},
	}

	for _, emp := range sampleEmployees {
		_, err := pool.Exec(ctx, `
			INSERT INTO employees (employee_code, full_name, phone_number, designation, default_shift, is_active)
			VALUES ($1, $2, $3, $4, $5, true)
			ON CONFLICT (employee_code) DO NOTHING
		`, emp.code, emp.name, emp.phone, emp.desig, emp.shift)
		if err != nil {
			log.Printf("Error inserting %s: %v", emp.code, err)
		}
	}

	// Optionally seed attendance for today
	today := time.Now().Format("2006-01-02")
	rows, err := pool.Query(ctx, "SELECT id, default_shift FROM employees WHERE is_active = true")
	if err == nil {
		defer rows.Close()
		r := rand.New(rand.NewSource(time.Now().UnixNano()))

		descriptions := []string{"Packing", "Loading", "Machine operation", "Maintenance", "Assembly line"}

		for rows.Next() {
			var empID string
			var defShift string
			if err := rows.Scan(&empID, &defShift); err == nil {
				// Mark 80% present, 20% absent
				status := "present"
				hours := 8.0
				var desc *string
				if r.Float32() < 0.2 {
					status = "absent"
					hours = 0.0
				} else {
					d := descriptions[r.Intn(len(descriptions))]
					desc = &d
				}

				_, _ = pool.Exec(ctx, `
					INSERT INTO attendance_records (employee_id, attendance_date, shift, status, hours_worked, work_description)
					VALUES ($1, $2::date, $3, $4, $5, $6)
					ON CONFLICT (employee_id, attendance_date, shift) DO NOTHING
				`, empID, today, defShift, status, hours, desc)
			}
		}
	}

	fmt.Println("Seed completed successfully!")
}
