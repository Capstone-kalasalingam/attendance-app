package config

import (
	"os"
	"strconv"
	"time"

	"github.com/joho/godotenv"
)

type Config struct {
	Port                  string
	DatabaseURL           string
	JWTSecret             string
	JWTExpiryHours        int
	RefreshTokenExpiry    time.Duration
	DefaultTimezone       string
	Environment           string
	AdminBootstrapUser    string
	AdminBootstrapPass    string
	RateLimitPerMinute    int
}

func LoadConfig() *Config {
	// Try loading from .env if present
	_ = godotenv.Load()
	_ = godotenv.Load("../.env")

	port := getEnv("PORT", "8080")
	dbURL := getEnv("DATABASE_URL", "postgres://postgres:1gEQpVj8P8SEtxrbh4H7wmbhsqiqQbpDRIW6V6tWQUqUYJm18beRewqdfCUQOzD1@103.185.75.206:5433/postgres?sslmode=require")
	jwtSecret := getEnv("JWT_SECRET", "super-secret-glassmorphic-attendance-jwt-key-2026")
	
	jwtExpiryHours, err := strconv.Atoi(getEnv("JWT_EXPIRY_HOURS", "24"))
	if err != nil || jwtExpiryHours <= 0 {
		jwtExpiryHours = 24
	}

	refreshExpiryDays, err := strconv.Atoi(getEnv("REFRESH_TOKEN_EXPIRY_DAYS", "7"))
	if err != nil || refreshExpiryDays <= 0 {
		refreshExpiryDays = 7
	}

	tz := getEnv("DEFAULT_TIMEZONE", "Asia/Kolkata")
	env := getEnv("ENVIRONMENT", "development")
	adminUser := getEnv("ADMIN_BOOTSTRAP_USER", "admin")
	adminPass := getEnv("ADMIN_BOOTSTRAP_PASS", "Admin@123456")

	rateLimit, err := strconv.Atoi(getEnv("RATE_LIMIT_PER_MINUTE", "60"))
	if err != nil || rateLimit <= 0 {
		rateLimit = 60
	}

	return &Config{
		Port:               port,
		DatabaseURL:        dbURL,
		JWTSecret:          jwtSecret,
		JWTExpiryHours:     jwtExpiryHours,
		RefreshTokenExpiry: time.Duration(refreshExpiryDays) * 24 * time.Hour,
		DefaultTimezone:    tz,
		Environment:        env,
		AdminBootstrapUser: adminUser,
		AdminBootstrapPass: adminPass,
		RateLimitPerMinute: rateLimit,
	}
}

func getEnv(key, defaultVal string) string {
	val := os.Getenv(key)
	if val == "" {
		return defaultVal
	}
	return val
}
