package http

import (
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"

	"attendance-app/backend/internal/attendance"
	"attendance-app/backend/internal/auth"
	"attendance-app/backend/internal/config"
	"attendance-app/backend/internal/employees"
	"attendance-app/backend/internal/exports"
	"attendance-app/backend/internal/middleware"
	"github.com/gin-gonic/gin"
)

func SetupRouter(
	cfg *config.Config,
	authHandler *auth.Handler,
	empHandler *employees.Handler,
	attHandler *attendance.Handler,
	exportHandler *exports.Handler,
) *gin.Engine {
	if cfg.Environment == "production" {
		gin.SetMode(gin.ReleaseMode)
	}

	r := gin.New()
	r.Use(gin.Recovery())
	r.Use(middleware.StructuredLogger())
	r.Use(middleware.CORSMiddleware())

	// Health check
	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status":    "healthy",
			"timestamp": time.Now().UTC(),
		})
	})

	apiV1 := r.Group("/api/v1")

	// Rate limiter for auth endpoints
	authLimiter := middleware.NewRateLimiter(cfg.RateLimitPerMinute, time.Minute)

	// Public Auth endpoints
	authGroup := apiV1.Group("/auth")
	{
		authGroup.POST("/login", authLimiter.Middleware(), authHandler.Login)
		authGroup.POST("/refresh", authHandler.Refresh)
		authGroup.POST("/logout", authHandler.Logout)
	}

	// Protected routes
	protected := apiV1.Group("")
	protected.Use(middleware.AuthMiddleware(cfg.JWTSecret))
	{
		// Current user
		protected.GET("/auth/me", authHandler.Me)

		// Employees
		empGroup := protected.Group("/employees")
		{
			empGroup.GET("", empHandler.GetEmployees)
			empGroup.POST("", empHandler.CreateEmployee)
			empGroup.GET("/:id", empHandler.GetEmployeeByID)
			empGroup.PATCH("/:id", empHandler.UpdateEmployee)
			empGroup.PATCH("/:id/status", empHandler.SetStatus)
		}

		// Attendance
		attGroup := protected.Group("/attendance")
		{
			attGroup.GET("", attHandler.GetDashboardAttendance)
			attGroup.GET("/summary", attHandler.GetSummary)
			attGroup.PUT("/:employeeId/:date/:shift", attHandler.PutAttendance)
			attGroup.POST("/bulk", attHandler.BulkAttendance)
			attGroup.GET("/history", attHandler.GetHistory)
		}

		// Exports
		exportGroup := protected.Group("/exports")
		{
			exportGroup.GET("/attendance.xlsx", exportHandler.ExportAttendanceExcel)
		}
	}

	// Serve static Flutter Web build if present in ./public
	publicDirs := []string{"public", "web", "../flutter_app/build/web"}
	for _, dir := range publicDirs {
		if _, err := os.Stat(dir); err == nil {
			r.NoRoute(func(c *gin.Context) {
				if !strings.HasPrefix(c.Request.URL.Path, "/api") && !strings.HasPrefix(c.Request.URL.Path, "/health") {
					filePath := filepath.Join(dir, filepath.Clean(c.Request.URL.Path))
					if info, err := os.Stat(filePath); err == nil && !info.IsDir() {
						c.File(filePath)
						return
					}
					c.File(filepath.Join(dir, "index.html"))
					return
				}
				c.JSON(http.StatusNotFound, gin.H{"error": "Endpoint not found"})
			})
			break
		}
	}

	return r
}
