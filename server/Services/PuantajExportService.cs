using System;
using System.IO;
using ClosedXML.Excel;
using Microsoft.EntityFrameworkCore;
using PdksApp.Data;
using PdksApp.Models;

namespace PdksApp.Services;

public static class PuantajExportService
{
    public static async Task<byte[]> GenerateExcelPuantajAsync(AppDbContext db, int year, int month)
    {
        var startDate = new DateTime(year, month, 1, 0, 0, 0, DateTimeKind.Utc);
        var endDate = startDate.AddMonths(1).AddTicks(-1);

        var employees = await db.Employees
            .Include(e => e.AttendanceRecords.Where(r => r.Timestamp >= startDate && r.Timestamp <= endDate))
            .Include(e => e.LeaveRequests.Where(l => l.Status == LeaveStatus.Approved && l.StartDate <= endDate && l.EndDate >= startDate))
            .Where(e => e.IsActive)
            .ToListAsync();

        using var workbook = new XLWorkbook();
        var worksheet = workbook.Worksheets.Add($"Puantaj {month}-{year}");

        // Başlık
        worksheet.Cell(1, 1).Value = $"AYLIK PERSONEL PUANTAJ RAPORU ({startDate:MMMM yyyy})";
        worksheet.Cell(1, 1).Style.Font.Bold = true;
        worksheet.Cell(1, 1).Style.Font.FontSize = 14;
        worksheet.Cell(1, 1).Style.Font.FontColor = XLColor.White;
        worksheet.Range(1, 1, 1, 8).Merge().Style.Fill.BackgroundColor = XLColor.FromHtml("#4F46E5");
        worksheet.Row(1).Height = 30;
        worksheet.Row(1).Style.Alignment.Vertical = XLAlignmentVerticalValues.Center;

        // Kolon Başlıkları
        string[] headers = {
            "ID", "Personel Adı", "Departman", "Giriş Sayısı", "Çıkış Sayısı", "Onaylı İzin (Gün)", "Kalan İzin", "Durum"
        };

        for (int i = 0; i < headers.Length; i++)
        {
            var cell = worksheet.Cell(3, i + 1);
            cell.Value = headers[i];
            cell.Style.Font.Bold = true;
            cell.Style.Fill.BackgroundColor = XLColor.FromHtml("#F1F5F9");
            cell.Style.Font.FontColor = XLColor.FromHtml("#1E293B");
            cell.Style.Border.OutsideBorder = XLBorderStyleValues.Thin;
            cell.Style.Border.OutsideBorderColor = XLColor.FromHtml("#CBD5E1");
        }
        worksheet.Row(3).Height = 22;

        int row = 4;
        foreach (var emp in employees)
        {
            int checkIns = emp.AttendanceRecords.Count(r => r.Type == AttendanceType.CheckIn && r.IsLocationVerified);
            int checkOuts = emp.AttendanceRecords.Count(r => r.Type == AttendanceType.CheckOut && r.IsLocationVerified);
            int leaveDays = emp.LeaveRequests.Sum(l => l.TotalDays);
            int remainingLeaves = emp.AnnualLeaveAllowance - emp.UsedLeaveDays;

            worksheet.Cell(row, 1).Value = emp.Id;
            worksheet.Cell(row, 2).Value = emp.FullName;
            worksheet.Cell(row, 3).Value = emp.Department;
            worksheet.Cell(row, 4).Value = checkIns;
            worksheet.Cell(row, 5).Value = checkOuts;
            worksheet.Cell(row, 6).Value = leaveDays;
            worksheet.Cell(row, 7).Value = remainingLeaves;
            worksheet.Cell(row, 8).Value = "Aktif";

            for (int col = 1; col <= 8; col++)
            {
                worksheet.Cell(row, col).Style.Border.OutsideBorder = XLBorderStyleValues.Thin;
                worksheet.Cell(row, col).Style.Border.OutsideBorderColor = XLColor.FromHtml("#E2E8F0");
            }

            row++;
        }

        // Genişlikleri otomatik ayarla
        worksheet.Columns().AdjustToContents();

        using var stream = new MemoryStream();
        workbook.SaveAs(stream);
        return stream.ToArray();
    }
}
