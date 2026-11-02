using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;
using PdksApp.Data;
using PdksApp.Models;

namespace PdksApp.Pages;

public class LeavesModel : PageModel
{
    private readonly AppDbContext _context;

    public LeavesModel(AppDbContext context)
    {
        _context = context;
    }

    public List<LeaveRequest> LeaveRequests { get; set; } = new();
    public List<Employee> Employees { get; set; } = new();

    public int PendingCount { get; set; }
    public int ApprovedCount { get; set; }
    public int RejectedCount { get; set; }

    public async Task OnGetAsync()
    {
        Employees = await _context.Employees.Where(e => e.IsActive).ToListAsync();

        LeaveRequests = await _context.LeaveRequests
            .Include(l => l.Employee)
            .OrderByDescending(l => l.CreatedAt)
            .ToListAsync();

        PendingCount = LeaveRequests.Count(l => l.Status == LeaveStatus.Pending);
        ApprovedCount = LeaveRequests.Count(l => l.Status == LeaveStatus.Approved);
        RejectedCount = LeaveRequests.Count(l => l.Status == LeaveStatus.Rejected);
    }
}
