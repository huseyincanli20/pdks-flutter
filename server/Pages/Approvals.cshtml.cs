using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;
using PdksApp.Data;
using PdksApp.Models;

namespace PdksApp.Pages;

public class ApprovalsModel : PageModel
{
    private readonly AppDbContext _context;

    public ApprovalsModel(AppDbContext context)
    {
        _context = context;
    }

    public List<LeaveRequest> PendingLeaves { get; set; } = new();
    public List<OvertimeRecord> PendingOvertimes { get; set; } = new();
    public List<LaborRequest> PendingLabors { get; set; } = new();

    public int TotalPending => PendingLeaves.Count + PendingOvertimes.Count + PendingLabors.Count;

    public async Task OnGetAsync()
    {
        PendingLeaves = await _context.LeaveRequests
            .Include(l => l.Employee)
            .Where(l => l.Status == LeaveStatus.Pending)
            .OrderByDescending(l => l.CreatedAt)
            .ToListAsync();

        PendingOvertimes = await _context.OvertimeRecords
            .Include(o => o.Employee)
            .Where(o => o.Status == ApprovalStatus.Pending)
            .OrderByDescending(o => o.CreatedAt)
            .ToListAsync();

        PendingLabors = await _context.LaborRequests
            .Where(l => l.Status == ApprovalStatus.Pending)
            .OrderByDescending(l => l.CreatedAt)
            .ToListAsync();
    }
}
