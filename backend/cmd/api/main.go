package main

import (
	"context"
	"errors"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"attendance-app/backend/internal/auth"
	"attendance-app/backend/internal/attendance"
	"attendance-app/backend/internal/config"
	"attendance-app/backend/internal/database"
	"attendance-app/backend/internal/employees"
	"attendance-app/backend/internal/exports"
	appHttp "attendance-app/backend/internal/http"
)

func main() {
	log.Println("Starting Glassmorphic Attendance Management Backend...")

	cfg := config.LoadConfig()

	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()

	pool, err := database.NewPostgresPool(ctx, cfg.DatabaseURL)
	if err != nil {
		log.Fatalf("Database connection failed: %v", err)
	}
	defer pool.Close()

	// Locate migrations directory (try ../migrations then migrations)
	migrationsDir := "migrations"
	if _, err := os.Stat(migrationsDir); os.IsNotExist(err) {
		migrationsDir = "../migrations"
	}
	if _, err := os.Stat(migrationsDir); os.IsNotExist(err) {
		migrationsDir = "../../migrations"
	}

	log.Printf("Executing database migrations from: %s", migrationsDir)
	if err := database.RunMigrations(context.Background(), pool, migrationsDir); err != nil {
		log.Fatalf("Migration execution failed: %v", err)
	}

	// Bootstrap default administrator if not present
	if err := database.BootstrapAdmin(context.Background(), pool, cfg.AdminBootstrapUser, cfg.AdminBootstrapPass); err != nil {
		log.Fatalf("Admin bootstrap failed: %v", err)
	}

	// Initialize repositories
	authRepo := auth.NewRepository(pool)
	empRepo := employees.NewRepository(pool)
	attRepo := attendance.NewRepository(pool)
	excelService := exports.NewExcelService(pool)

	// Initialize services
	authService := auth.NewService(authRepo, cfg)
	empService := employees.NewService(empRepo)
	attService := attendance.NewService(attRepo)

	// Initialize handlers
	authHandler := auth.NewHandler(authService)
	empHandler := employees.NewHandler(empService)
	attHandler := attendance.NewHandler(attService)
	exportHandler := exports.NewHandler(excelService)

	// Build router
	router := appHttp.SetupRouter(cfg, authHandler, empHandler, attHandler, exportHandler)

	srv := &http.Server{
		Addr:         ":" + cfg.Port,
		Handler:      router,
		ReadTimeout:  30 * time.Second,
		WriteTimeout: 60 * time.Second,
		IdleTimeout:  120 * time.Second,
	}

	go func() {
		log.Printf("Server listening on port :%s (env: %s)", cfg.Port, cfg.Environment)
		if err := srv.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			log.Fatalf("Server error: %v", err)
		}
	}()

	// Graceful shutdown
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit
	log.Println("Shutting down server gracefully...")

	shutdownCtx, shutdownCancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer shutdownCancel()

	if err := srv.Shutdown(shutdownCtx); err != nil {
		log.Fatalf("Server forced to shutdown: %v", err)
	}

	log.Println("Server exited cleanly.")
}
