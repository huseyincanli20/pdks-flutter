using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;
using PdksApp.Data;
using PdksApp.Models;

namespace PdksApp.Pages;

public class OvertimeModel : PageModel
{
    private readonly AppDbContext _context;

    public OvertimeModel(AppDbContext context)
    {
        _context = context;
    }

    public List<OvertimeRecord> Records { get; set; } = new();
    public List<Employee> Employees { get; set; } = new();
    public double TotalPendingHours { get; set; }
    public decimal TotalEstimatedPay { get; set; }

    public async Task OnGetAsync()
    {
        Employees = await _context.Employees.Where(e => e.IsActive).ToListAsync();
        Records = await _context.OvertimeRecords
            .Include(r => r.Employee)
            .OrderByDescending(r => r.CreatedAt)
            .ToListAsync();

        TotalPendingHours = Records.Where(r => r.Status == ApprovalStatus.Pending).Sum(r => r.Hours);
        TotalEstimatedPay = Records.Where(r => r.Status == ApprovalStatus.Approved).Sum(r => r.EstimatedPay);
    }
}
