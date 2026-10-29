package main

import (
	"context"
	"log"
	"os"
	"time"

	"attendance-app/backend/internal/config"
	"attendance-app/backend/internal/database"
)

func main() {
	log.Println("Starting Database Migration Runner...")

	cfg := config.LoadConfig()
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	pool, err := database.NewPostgresPool(ctx, cfg.DatabaseURL)
	if err != nil {
		log.Fatalf("Database connection failed: %v", err)
	}
	defer pool.Close()

	migrationsDir := "migrations"
	if _, err := os.Stat(migrationsDir); os.IsNotExist(err) {
		migrationsDir = "../migrations"
	}
	if _, err := os.Stat(migrationsDir); os.IsNotExist(err) {
		migrationsDir = "../../migrations"
	}

	log.Printf("Executing migrations from directory: %s", migrationsDir)
	if err := database.RunMigrations(ctx, pool, migrationsDir); err != nil {
		log.Fatalf("Migration failed: %v", err)
	}

	if err := database.BootstrapAdmin(ctx, pool, cfg.AdminBootstrapUser, cfg.AdminBootstrapPass); err != nil {
		log.Fatalf("Admin bootstrap failed: %v", err)
	}

	log.Println("Migrations and admin bootstrap completed successfully!")
}
