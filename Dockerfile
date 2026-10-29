# Production Dockerfile for Go Backend
FROM golang:1.23-alpine AS builder

WORKDIR /app

RUN apk add --no-cache git ca-certificates tzdata

# Copy Go module manifests from backend/
COPY backend/go.mod backend/go.sum ./
RUN go mod download

# Copy backend source code
COPY backend/ ./

# Compile backend server, migration runner, and seeder
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o /app/server ./cmd/api
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o /app/migrate ./cmd/migrate
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o /app/seed ./cmd/seed

# Production runtime image
FROM alpine:3.20

WORKDIR /app

RUN apk add --no-cache ca-certificates tzdata wget

# Copy binaries and database migrations
COPY --from=builder /app/server /app/server
COPY --from=builder /app/migrate /app/migrate
COPY --from=builder /app/seed /app/seed
COPY migrations /app/migrations

ENV PORT=8080
ENV ENVIRONMENT=production
ENV DEFAULT_TIMEZONE=Asia/Kolkata

EXPOSE 8080

HEALTHCHECK --interval=15s --timeout=5s --start-period=5s --retries=3 \
  CMD wget -qO- http://localhost:8080/health || exit 1

CMD ["/app/server"]
