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

const apiLandingHTML = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>ShiftMaster API — Attendance Management</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap" rel="stylesheet">
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: 'Poppins', sans-serif;
      min-height: 100vh;
      background: radial-gradient(circle at 10% 20%, #1e1b4b 0%, #0f172a 40%, #080b16 100%);
      color: #ffffff;
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 24px;
    }
    .glass-card {
      background: rgba(255, 255, 255, 0.05);
      backdrop-filter: blur(20px);
      -webkit-backdrop-filter: blur(20px);
      border: 1px solid rgba(255, 255, 255, 0.15);
      border-radius: 24px;
      max-width: 720px;
      width: 100%;
      padding: 36px;
      box-shadow: 0 20px 40px rgba(0, 0, 0, 0.5), 0 0 40px rgba(99, 102, 241, 0.15);
    }
    .header {
      display: flex;
      align-items: center;
      gap: 16px;
      margin-bottom: 24px;
      padding-bottom: 20px;
      border-bottom: 1px solid rgba(255, 255, 255, 0.1);
    }
    .logo-badge {
      width: 52px;
      height: 52px;
      border-radius: 14px;
      background: linear-gradient(135deg, #4f46e5 0%, #7c3aed 100%);
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 26px;
      box-shadow: 0 8px 16px rgba(79, 70, 229, 0.4);
    }
    .title-group h1 { font-size: 22px; font-weight: 700; letter-spacing: -0.3px; }
    .title-group p { font-size: 13px; color: #94a3b8; }
    .status-pill {
      display: inline-flex;
      align-items: center;
      gap: 8px;
      background: rgba(16, 185, 129, 0.15);
      border: 1px solid rgba(16, 185, 129, 0.4);
      color: #34d399;
      padding: 6px 14px;
      border-radius: 20px;
      font-size: 12px;
      font-weight: 600;
      margin-bottom: 24px;
    }
    .status-dot {
      width: 8px;
      height: 8px;
      border-radius: 50%;
      background: #10b981;
      box-shadow: 0 0 8px #10b981;
    }
    .grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
      gap: 14px;
      margin-bottom: 24px;
    }
    .item {
      background: rgba(255, 255, 255, 0.03);
      border: 1px solid rgba(255, 255, 255, 0.08);
      border-radius: 14px;
      padding: 14px 16px;
      transition: all 0.2s ease;
    }
    .item:hover {
      background: rgba(255, 255, 255, 0.07);
      border-color: rgba(129, 140, 248, 0.4);
      transform: translateY(-2px);
    }
    .method {
      display: inline-block;
      font-size: 10px;
      font-weight: 700;
      padding: 2px 6px;
      border-radius: 6px;
      margin-right: 6px;
    }
    .method-get { background: rgba(56, 189, 248, 0.2); color: #38bdf8; }
    .method-post { background: rgba(16, 185, 129, 0.2); color: #34d399; }
    .endpoint { font-family: monospace; font-size: 12px; color: #cbd5e1; }
    .desc { font-size: 11px; color: #94a3b8; margin-top: 4px; }
    .info-box {
      background: rgba(99, 102, 241, 0.1);
      border: 1px solid rgba(129, 140, 248, 0.3);
      border-radius: 14px;
      padding: 16px;
      font-size: 12px;
      color: #c7d2fe;
      line-height: 1.6;
    }
    .code-tag {
      background: rgba(0, 0, 0, 0.3);
      padding: 2px 6px;
      border-radius: 6px;
      font-family: monospace;
      color: #a5b4fc;
    }
    a { color: #818cf8; text-decoration: none; }
    a:hover { text-decoration: underline; }
  </style>
</head>
<body>
  <div class="glass-card">
    <div class="header">
      <div class="logo-badge">⏱️</div>
      <div class="title-group">
        <h1>ShiftMaster Attendance API</h1>
        <p>Production Golang & PostgreSQL Backend Service</p>
      </div>
    </div>

    <div class="status-pill">
      <span class="status-dot"></span> Backend API is Live & Operational
    </div>

    <div class="grid">
      <a href="/health" target="_blank" class="item">
        <div><span class="method method-get">GET</span><span class="endpoint">/health</span></div>
        <div class="desc">System health check & liveness probe</div>
      </a>
      <div class="item">
        <div><span class="method method-post">POST</span><span class="endpoint">/api/v1/auth/login</span></div>
        <div class="desc">Administrator authentication (JWT tokens)</div>
      </div>
      <div class="item">
        <div><span class="method method-get">GET</span><span class="endpoint">/api/v1/attendance</span></div>
        <div class="desc">Single-screen attendance & shift records</div>
      </div>
      <div class="item">
        <div><span class="method method-get">GET</span><span class="endpoint">/api/v1/attendance/summary</span></div>
        <div class="desc">Live headcount, shifts & hours metrics</div>
      </div>
      <div class="item">
        <div><span class="method method-get">GET</span><span class="endpoint">/api/v1/employees</span></div>
        <div class="desc">Employee directory & shift assignments</div>
      </div>
      <div class="item">
        <div><span class="method method-get">GET</span><span class="endpoint">/api/v1/exports/attendance.xlsx</span></div>
        <div class="desc">Multi-sheet Excel workbook export</div>
      </div>
    </div>

    <div class="info-box">
      <strong>Connecting the Flutter Application:</strong><br>
      To run your Flutter app pointing to this backend, run:<br>
      <span class="code-tag">flutter run --dart-define=API_BASE_URL=http://6zw5w6pyiv17takt0903hayt.51.79.133.26.sslip.io</span><br><br>
      <strong>Default Administrator Credentials:</strong><br>
      Username: <span class="code-tag">admin</span> | Password: <span class="code-tag">Admin@123456</span>
    </div>
  </div>
</body>
</html>`

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

	// Health check endpoint
	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status":    "healthy",
			"timestamp": time.Now().UTC(),
		})
	})

	// Root endpoint: Serve Flutter SPA if present in public/, otherwise show API status landing page
	r.GET("/", func(c *gin.Context) {
		for _, dir := range []string{"public", "web", "../flutter_app/build/web"} {
			if info, err := os.Stat(filepath.Join(dir, "index.html")); err == nil && !info.IsDir() {
				c.File(filepath.Join(dir, "index.html"))
				return
			}
		}

		c.Header("Content-Type", "text/html; charset=utf-8")
		c.String(http.StatusOK, apiLandingHTML)
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
			attGroup.GET("/payroll", attHandler.GetPayrollOverview)
		}

		// Exports
		exportGroup := protected.Group("/exports")
		{
			exportGroup.GET("/attendance.xlsx", exportHandler.ExportAttendanceExcel)
		}
	}

	// Catch-all route handler
	r.NoRoute(func(c *gin.Context) {
		for _, dir := range []string{"public", "web", "../flutter_app/build/web"} {
			if _, err := os.Stat(dir); err == nil {
				if !strings.HasPrefix(c.Request.URL.Path, "/api") && !strings.HasPrefix(c.Request.URL.Path, "/health") {
					filePath := filepath.Join(dir, filepath.Clean(c.Request.URL.Path))
					if info, err := os.Stat(filePath); err == nil && !info.IsDir() {
						c.File(filePath)
						return
					}
					c.File(filepath.Join(dir, "index.html"))
					return
				}
			}
		}

		c.JSON(http.StatusNotFound, gin.H{
			"error": "Route not found",
			"path":  c.Request.URL.Path,
			"hint":  "Explore available endpoints at / or check system health at /health",
		})
	})

	return r
}
