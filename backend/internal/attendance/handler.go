package attendance

import (
	"net/http"

	"attendance-app/backend/internal/models"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type Handler struct {
	service *Service
}

func NewHandler(service *Service) *Handler {
	return &Handler{service: service}
}

func (h *Handler) GetDashboardAttendance(c *gin.Context) {
	dateStr := c.Query("date")
	rows, err := h.service.GetAttendanceDashboard(c.Request.Context(), dateStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, rows)
}

func (h *Handler) GetSummary(c *gin.Context) {
	dateStr := c.Query("date")
	summary, err := h.service.GetAttendanceSummary(c.Request.Context(), dateStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, summary)
}

func (h *Handler) PutAttendance(c *gin.Context) {
	empIDStr := c.Param("employeeId")
	dateStr := c.Param("date")
	shift := c.Param("shift")

	employeeID, err := uuid.Parse(empIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid employee ID format"})
		return
	}

	var req models.MarkAttendanceRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid input: " + err.Error()})
		return
	}

	// Extract admin ID from context
	adminIDVal, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}
	adminID := adminIDVal.(uuid.UUID)

	record, err := h.service.MarkAttendance(c.Request.Context(), employeeID, dateStr, shift, &req, adminID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, record)
}

func (h *Handler) BulkAttendance(c *gin.Context) {
	var req models.BulkAttendanceRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid input: " + err.Error()})
		return
	}

	adminIDVal, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}
	adminID := adminIDVal.(uuid.UUID)

	records, err := h.service.BulkMarkAttendance(c.Request.Context(), &req, adminID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, records)
}

func (h *Handler) GetHistory(c *gin.Context) {
	empIDStr := c.Query("employee_id")
	startDate := c.Query("start_date")
	endDate := c.Query("end_date")

	records, err := h.service.GetAttendanceHistory(c.Request.Context(), empIDStr, startDate, endDate)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, records)
}
