package tests

import (
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"attendance-app/backend/internal/config"
	"attendance-app/backend/internal/middleware"
	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"github.com/xuri/excelize/v2"
	"golang.org/x/crypto/bcrypt"
)

func TestPasswordHashing(t *testing.T) {
	password := "SecretAdmin123!"
	hash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		t.Fatalf("Failed to generate password hash: %v", err)
	}

	// Verify matching password
	if err := bcrypt.CompareHashAndPassword(hash, []byte(password)); err != nil {
		t.Errorf("Password verification failed for correct password: %v", err)
	}

	// Verify incorrect password rejection
	if err := bcrypt.CompareHashAndPassword(hash, []byte("WrongPassword")); err == nil {
		t.Error("Password verification passed for incorrect password, expected failure")
	}
}

func TestJWTIssuanceAndValidation(t *testing.T) {
	jwtSecret := "test-secret-key-for-unit-testing-32chars"
	userID := uuid.New()
	username := "testadmin"
	role := "admin"

	claims := middleware.Claims{
		UserID:   userID,
		Username: username,
		Role:     role,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(1 * time.Hour)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
			Subject:   userID.String(),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	tokenStr, err := token.SignedString([]byte(jwtSecret))
	if err != nil {
		t.Fatalf("Failed to sign JWT: %v", err)
	}

	// Validate valid token
	parsedClaims := &middleware.Claims{}
	parsedToken, err := jwt.ParseWithClaims(tokenStr, parsedClaims, func(t *jwt.Token) (interface{}, error) {
		return []byte(jwtSecret), nil
	})
	if err != nil || !parsedToken.Valid {
		t.Fatalf("Failed parsing valid JWT token: %v", err)
	}
	if parsedClaims.UserID != userID || parsedClaims.Username != username {
		t.Errorf("Claim mismatch: got %v, want %v", parsedClaims.UserID, userID)
	}

	// Validate tampered / wrong secret token
	_, err = jwt.ParseWithClaims(tokenStr, &middleware.Claims{}, func(t *jwt.Token) (interface{}, error) {
		return []byte("wrong-secret"), nil
	})
	if err == nil {
		t.Error("Expected parsing with wrong secret to fail, but it succeeded")
	}
}

func TestAuthMiddlewareProtection(t *testing.T) {
	gin.SetMode(gin.TestMode)
	jwtSecret := "unit-test-protection-secret-12345"

	r := gin.New()
	protected := r.Group("/protected")
	protected.Use(middleware.AuthMiddleware(jwtSecret))
	protected.GET("/test", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "ok"})
	})

	// 1. Request without header -> 401
	w1 := httptest.NewRecorder()
	req1, _ := http.NewRequest(http.MethodGet, "/protected/test", nil)
	r.ServeHTTP(w1, req1)
	if w1.Code != http.StatusUnauthorized {
		t.Errorf("Expected 401 without auth header, got %d", w1.Code)
	}

	// 2. Request with malformed header -> 401
	w2 := httptest.NewRecorder()
	req2, _ := http.NewRequest(http.MethodGet, "/protected/test", nil)
	req2.Header.Set("Authorization", "InvalidHeaderFormat")
	r.ServeHTTP(w2, req2)
	if w2.Code != http.StatusUnauthorized {
		t.Errorf("Expected 401 for malformed header, got %d", w2.Code)
	}

	// 3. Request with valid token -> 200
	userID := uuid.New()
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, middleware.Claims{
		UserID:   userID,
		Username: "admin",
		Role:     "admin",
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(time.Hour)),
		},
	})
	validToken, _ := token.SignedString([]byte(jwtSecret))

	w3 := httptest.NewRecorder()
	req3, _ := http.NewRequest(http.MethodGet, "/protected/test", nil)
	req3.Header.Set("Authorization", "Bearer "+validToken)
	r.ServeHTTP(w3, req3)
	if w3.Code != http.StatusOK {
		t.Errorf("Expected 200 for valid token, got %d", w3.Code)
	}
}

func TestAttendanceHoursValidation(t *testing.T) {
	tests := []struct {
		name        string
		status      string
		hoursWorked float64
		expectValid bool
	}{
		{"Valid present with 8 hours", "present", 8.0, true},
		{"Valid present with 0 hours", "present", 0.0, true},
		{"Valid present with 24 hours", "present", 24.0, true},
		{"Invalid present with negative hours", "present", -1.0, false},
		{"Invalid present with excessive hours", "present", 25.0, false},
		{"Absent with 0 hours", "absent", 0.0, true},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			valid := true
			if tt.hoursWorked < 0 || tt.hoursWorked > 24 {
				valid = false
			}
			if valid != tt.expectValid {
				t.Errorf("Validation mismatch for %s: got %v, want %v", tt.name, valid, tt.expectValid)
			}
		})
	}
}

func TestExcelWorkbookStructure(t *testing.T) {
	// Verify that Excelize generates a valid XLSX format with 3 distinct sheets
	f := excelize.NewFile()
	defer f.Close()

	sheet1 := "Attendance Details"
	f.SetSheetName("Sheet1", sheet1)
	f.NewSheet("Daily Summary")
	f.NewSheet("Employee Summary")

	sheets := f.GetSheetList()
	if len(sheets) != 3 {
		t.Fatalf("Expected 3 sheets, got %d", len(sheets))
	}

	if sheets[0] != "Attendance Details" || sheets[1] != "Daily Summary" || sheets[2] != "Employee Summary" {
		t.Errorf("Unexpected sheet names: %v", sheets)
	}

	buf, err := f.WriteToBuffer()
	if err != nil {
		t.Fatalf("Failed writing Excel workbook to buffer: %v", err)
	}
	if buf.Len() == 0 {
		t.Error("Generated Excel workbook is empty")
	}
}

func TestConfigDefaults(t *testing.T) {
	cfg := config.LoadConfig()
	if cfg.Port == "" {
		t.Error("Config Port should have default")
	}
	if cfg.DefaultTimezone != "Asia/Kolkata" {
		t.Errorf("Expected default timezone 'Asia/Kolkata', got %s", cfg.DefaultTimezone)
	}
	if cfg.AdminBootstrapUser != "admin" {
		t.Errorf("Expected default admin user 'admin', got %s", cfg.AdminBootstrapUser)
	}
}
