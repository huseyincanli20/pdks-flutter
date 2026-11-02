using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;
using PdksApp.Data;
using PdksApp.Models;

namespace PdksApp.Pages;

public class IndexModel : PageModel
{
    private readonly AppDbContext _context;

    public IndexModel(AppDbContext context)
    {
        _context = context;
    }

    public Company? Company { get; set; }
    public List<Employee> Employees { get; set; } = new();
    public List<AttendanceRecord> RecentRecords { get; set; } = new();

    public int TodayCheckInsCount { get; set; }
    public int TotalEmployeesCount { get; set; }

    public async Task OnGetAsync()
    {
        Company = await _context.Companies.FirstOrDefaultAsync(c => c.Id == 1);
        Employees = await _context.Employees.Where(e => e.IsActive).ToListAsync();
        TotalEmployeesCount = Employees.Count;

        var today = DateTime.UtcNow.Date;
        RecentRecords = await _context.AttendanceRecords
            .Include(r => r.Employee)
            .OrderByDescending(r => r.Timestamp)
            .Take(15)
            .ToListAsync();

        TodayCheckInsCount = await _context.AttendanceRecords
            .Where(r => r.Timestamp >= today && r.Type == AttendanceType.CheckIn)
            .Select(r => r.EmployeeId)
            .Distinct()
            .CountAsync();
    }
}
