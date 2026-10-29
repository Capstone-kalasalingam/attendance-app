package exports

import (
	"fmt"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
)

type Handler struct {
	service *ExcelService
}

func NewHandler(service *ExcelService) *Handler {
	return &Handler{service: service}
}

func (h *Handler) ExportAttendanceExcel(c *gin.Context) {
	filter := ExportFilter{
		StartDate:  c.Query("start_date"),
		EndDate:    c.Query("end_date"),
		EmployeeID: c.Query("employee_id"),
		Shift:      c.Query("shift"),
		Status:     c.Query("status"),
	}

	workbook, err := h.service.GenerateAttendanceWorkbook(c.Request.Context(), filter)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate Excel report: " + err.Error()})
		return
	}
	defer workbook.Close()

	filename := fmt.Sprintf("attendance_report_%s.xlsx", time.Now().Format("20060102_150405"))

	c.Header("Content-Type", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
	c.Header("Content-Disposition", fmt.Sprintf("attachment; filename=\"%s\"", filename))
	c.Header("Content-Transfer-Encoding", "binary")

	if err := workbook.Write(c.Writer); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to stream Excel workbook: " + err.Error()})
		return
	}
}
