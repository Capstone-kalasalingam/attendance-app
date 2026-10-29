# ShiftMaster — Production Glassmorphic Attendance Management System

A modern, high-performance, full-stack employee attendance and shift management application crafted with a premium **Glassmorphic Design System**. Built with a **Golang Gin backend**, **PostgreSQL database (pgx)**, and a **Flutter frontend (Material 3 + Riverpod + GoRouter)**.

Designed around the core principle: **Maximum functionality with minimum clicks**.

---

## 🚀 Key Features

- **Everything in One View Dashboard**: Manage daily attendance, morning/night shifts, working hours, and work descriptions without navigating between multiple pages.
- **One-Tap Attendance Controls**: Instant Present and Absent toggles with optimistic UI updates and real-time backend synchronization.
- **Independent Shift Selection**: Easily switch between Morning and Night shifts per employee independently.
- **Inline Hours & Task Tracking**: Rapidly adjust working hours (0–24 hours validation) and enter optional work descriptions with quick suggestions (e.g., Packing, Machine operation, Maintenance).
- **Live Summary Metrics**: Real-time cards displaying total active headcount, present, absent, morning shift, night shift, total hours worked, and completion percentage.
- **Real Excel (.xlsx) Export**: Generates 3-sheet `.xlsx` workbooks on the backend with frozen headers, formatted tables, and auto-adjusted columns using `excelize/v2`.
- **Offline Poppins Typography**: Bundled local Poppins font weights (`Light`, `Regular`, `Medium`, `SemiBold`, `Bold`, `ExtraBold`) running completely offline without external Google Fonts dependencies.
- **Production-Ready Security**: Salted bcrypt password hashing, JWT access tokens with configurable expiration, refresh-token rotation, and IP rate limiting for brute-force protection.
- **Transactional Migrations**: Robust version-controlled SQL migrations adhering to strict naming conventions (`migrations/00X_RDM_*.sql`).

---

## 🛠️ Technology Stack

### Backend
- **Language**: Go 1.23+
- **HTTP Framework**: [Gin](https://github.com/gin-gonic/gin)
- **Database Engine**: PostgreSQL 15+
- **Driver & Pool**: [pgx/v5](https://github.com/jackc/pgx) connection pooling
- **Authentication**: JWT access tokens ([golang-jwt/jwt/v5](https://github.com/golang-jwt/jwt)) + bcrypt
- **Excel Generation**: [Excelize v2](https://github.com/xuri/excelize)
- **Architecture**: Modular DDD-style layered architecture (HTTP Handlers → Services → Repositories)

### Frontend
- **Framework**: Flutter Stable (Dart 3.x with null-safety)
- **State Management**: [Riverpod 2.6](https://riverpod.dev)
- **Navigation**: [GoRouter 14](https://pub.dev/packages/go_router)
- **HTTP Client**: [Dio 5](https://pub.dev/packages/dio) with automatic refresh-token rotation interceptor
- **Storage**: `flutter_secure_storage` with fallback to `shared_preferences`
- **Design System**: Custom Glassmorphism (BackdropFilter blur, translucent borders, navy/blue/violet glow gradients)

---

## 📁 Repository Structure

```text
attendance-app/
├── backend/
│   ├── cmd/
│   │   ├── api/          # Server main entry point with graceful shutdown
│   │   ├── migrate/      # Standalone CLI migration & bootstrap runner
│   │   └── seed/         # Demo data populator
│   ├── internal/
│   │   ├── attendance/   # Attendance logic, summaries, bulk operations
│   │   ├── auth/         # Authentication, JWT, bcrypt, refresh tokens
│   │   ├── config/       # Environment configuration loader
│   │   ├── database/     # pgx connection pool and transactional migration runner
│   │   ├── employees/    # Employee CRUD and soft deactivation
│   │   ├── exports/      # Excelize 3-sheet XLSX workbook generator
│   │   ├── http/         # Gin router setup and endpoints
│   │   ├── middleware/   # JWT auth, CORS, RateLimiter, StructuredLogger
│   │   └── models/       # Shared domain models and DTOs
│   ├── tests/            # Go unit and live database integration tests
│   ├── Dockerfile        # Production multi-stage Docker build
│   ├── go.mod
│   └── .env.example
├── flutter_app/
│   ├── assets/
│   │   └── fonts/        # Offline Poppins TTF font files
│   ├── lib/
│   │   ├── core/
│   │   │   ├── auth/     # TokenManager
│   │   │   ├── config/   # AppConfig
│   │   │   ├── models/   # Attendance, Employee, Summary, User models
│   │   │   ├── network/  # ApiClient (Dio) and Endpoints
│   │   │   ├── theme/    # AppColors and GlassTheme
│   │   │   └── widgets/  # GlassPanel, GlassButton, StatCard, StatusToggle, etc.
│   │   ├── features/
│   │   │   ├── auth/     # LoginScreen and AuthNotifier
│   │   │   ├── dashboard/# DashboardScreen, AttendanceRow, StatsHeader
│   │   │   ├── employees/# AddEmployeeDialog, EditEmployeeDialog
│   │   │   └── exports/  # ExportExcelDialog and ExportService
│   │   ├── app.dart      # MaterialApp.router and GoRouter setup
│   │   └── main.dart     # App entry point
│   ├── pubspec.yaml
│   └── test/             # Flutter widget and unit tests
├── migrations/           # Versioned SQL migrations with RDM naming standard
│   ├── 001_RDM_create_users_table.sql
│   ├── 002_RDM_create_employees_table.sql
│   ├── 003_RDM_create_attendance_records_table.sql
│   ├── 004_RDM_create_refresh_tokens_table.sql
│   └── 005_RDM_create_indexes_and_constraints.sql
├── docker-compose.yml
├── .env.example
└── README.md
```

---

## ⚙️ Quick Start & Local Development

### 1. Database Configuration

You can use the remote PostgreSQL database or spin up a local instance.

Edit `.env` (copy from `.env.example`):
```bash
PORT=8080
DATABASE_URL=postgres://postgres:1gEQpVj8P8SEtxrbh4H7wmbhsqiqQbpDRIW6V6tWQUqUYJm18beRewqdfCUQOzD1@103.185.75.206:5433/postgres?sslmode=require
JWT_SECRET=super-secret-glassmorphic-attendance-jwt-key-2026-production
DEFAULT_TIMEZONE=Asia/Kolkata
ENVIRONMENT=development
ADMIN_BOOTSTRAP_USER=admin
ADMIN_BOOTSTRAP_PASS=Admin@123456
```

### 2. Run Database Migrations & Seed Demo Data

Run the database migration command:
```bash
cd backend
go run ./cmd/migrate
```

*(Optional)* Seed sample employees and attendance:
```bash
go run ./cmd/seed
```

### 3. Start the Backend API Server

```bash
cd backend
go run ./cmd/api
```
The server will start on port `8080` (or `PORT` specified in `.env`). Health check: `http://localhost:8080/health`.

### 4. Run the Flutter Frontend

```bash
cd flutter_app
flutter pub get
flutter run
```

To connect to a custom backend URL (for Android emulator, physical device, or remote host):
```bash
# Android Emulator (points to host localhost)
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080

# Physical Device on local Wi-Fi or Production URL
flutter run --dart-define=API_BASE_URL=https://attendance.example.com
```

---

## 🔐 Default Credentials

- **Username**: `admin`
- **Password**: `Admin@123456`

*(The Login screen includes a one-tap helper button to auto-fill these credentials for swift evaluation).*

---

## 🧪 Running Automated Tests

### Backend Tests
```bash
cd backend

# Run all unit tests
go test -v ./tests/...

# Run live database integration tests
go test -v -run TestLiveDatabaseIntegrationFlows ./tests/...
```

### Flutter Tests & Static Analysis
```bash
cd flutter_app

# Analyze static code
flutter analyze

# Execute widget test suite
flutter test
```

---

## 📊 REST API Reference

All requests and responses use JSON. Authenticated endpoints require `Authorization: Bearer <token>`.

### Authentication
- `POST /api/v1/auth/login`: Authenticate admin, returns access and refresh tokens.
- `POST /api/v1/auth/refresh`: Rotate refresh token and obtain new access token.
- `POST /api/v1/auth/logout`: Revoke active refresh token.
- `GET /api/v1/auth/me`: Get current admin profile.

### Employees
- `GET /api/v1/employees?search=...&active=true`: Search & list employees.
- `POST /api/v1/employees`: Create new employee with unique code, name, designation, default shift.
- `GET /api/v1/employees/:id`: Get employee details.
- `PATCH /api/v1/employees/:id`: Update employee info.
- `PATCH /api/v1/employees/:id/status`: Soft activate/deactivate employee.

### Attendance
- `GET /api/v1/attendance?date=YYYY-MM-DD`: Get unified attendance grid rows.
- `GET /api/v1/attendance/summary?date=YYYY-MM-DD`: Get live headcount and hours statistics.
- `PUT /api/v1/attendance/:employeeId/:date/:shift`: Mark/update attendance record transactionally.
- `POST /api/v1/attendance/bulk`: Mark multiple employees in a single transaction.
- `GET /api/v1/attendance/history?employee_id=...&start_date=...&end_date=...`: Chronological history.

### Excel Export
- `GET /api/v1/exports/attendance.xlsx`: Stream authentic `.xlsx` workbook with query parameters (`start_date`, `end_date`, `shift`, `status`, `employee_id`).

---

## 🐳 Docker & Production Deployment

Run with Docker Compose:
```bash
docker compose up -d --build
```

Health checks and automatic restarts ensure seamless container operations.
