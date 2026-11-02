using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;
using PdksApp.Data;
using PdksApp.Models;

namespace PdksApp.Pages;

public class PuantajRowViewModel
{
    public int EmployeeId { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string Department { get; set; } = string.Empty;
    public int CheckInsCount { get; set; }
    public int CheckOutsCount { get; set; }
    public int ApprovedLeaveDays { get; set; }
    public int RemainingLeaveDays { get; set; }
}

public class PuantajModel : PageModel
{
    private readonly AppDbContext _context;

    public PuantajModel(AppDbContext context)
    {
        _context = context;
    }

    public int SelectedYear { get; set; } = DateTime.UtcNow.Year;
    public int SelectedMonth { get; set; } = DateTime.UtcNow.Month;
    public List<PuantajRowViewModel> Rows { get; set; } = new();

    public async Task OnGetAsync(int? year, int? month)
    {
        SelectedYear = year ?? DateTime.UtcNow.Year;
        SelectedMonth = month ?? DateTime.UtcNow.Month;

        var startDate = new DateTime(SelectedYear, SelectedMonth, 1, 0, 0, 0, DateTimeKind.Utc);
        var endDate = startDate.AddMonths(1).AddTicks(-1);

        var employees = await _context.Employees
            .Include(e => e.AttendanceRecords.Where(r => r.Timestamp >= startDate && r.Timestamp <= endDate))
            .Include(e => e.LeaveRequests.Where(l => l.Status == LeaveStatus.Approved && l.StartDate <= endDate && l.EndDate >= startDate))
            .Where(e => e.IsActive)
            .ToListAsync();

        Rows = employees.Select(e => new PuantajRowViewModel
        {
            EmployeeId = e.Id,
            FullName = e.FullName,
            Department = e.Department,
            CheckInsCount = e.AttendanceRecords.Count(r => r.Type == AttendanceType.CheckIn && r.IsLocationVerified),
            CheckOutsCount = e.AttendanceRecords.Count(r => r.Type == AttendanceType.CheckOut && r.IsLocationVerified),
            ApprovedLeaveDays = e.LeaveRequests.Sum(l => l.TotalDays),
            RemainingLeaveDays = e.AnnualLeaveAllowance - e.UsedLeaveDays
        }).ToList();
    }
}
