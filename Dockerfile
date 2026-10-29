# ==============================================================================
# Unified Production Multi-Stage Dockerfile for ShiftMaster Attendance System
# Packages Flutter Web UI + Golang Backend + Migrations into a single container
# ==============================================================================

# Stage 1: Build Flutter Web Frontend
FROM ghcr.io/cirruslabs/flutter:stable AS flutter-builder

WORKDIR /app/flutter_app

COPY flutter_app/pubspec.yaml flutter_app/pubspec.lock ./
RUN flutter pub get

COPY flutter_app/ ./
RUN flutter build web --release --dart-define=API_BASE_URL=""

# Stage 2: Build Golang Backend
FROM golang:1.23-alpine AS go-builder

WORKDIR /app/backend

RUN apk add --no-cache git ca-certificates tzdata

COPY backend/go.mod backend/go.sum ./
RUN go mod download

COPY backend/ ./
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o /app/server ./cmd/api
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o /app/migrate ./cmd/migrate
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o /app/seed ./cmd/seed

# Stage 3: Final Production Lightweight Runtime
FROM alpine:3.20

WORKDIR /app

RUN apk add --no-cache ca-certificates tzdata wget

# Copy backend binaries and migrations
COPY --from=go-builder /app/server /app/server
COPY --from=go-builder /app/migrate /app/migrate
COPY --from=go-builder /app/seed /app/seed
COPY migrations /app/migrations

# Copy compiled Flutter Web UI to /app/public
COPY --from=flutter-builder /app/flutter_app/build/web /app/public

ENV PORT=8080
ENV ENVIRONMENT=production
ENV DEFAULT_TIMEZONE=Asia/Kolkata

EXPOSE 8080

HEALTHCHECK --interval=15s --timeout=5s --start-period=5s --retries=3 \
  CMD wget -qO- http://localhost:8080/health || exit 1

CMD ["/app/server"]
