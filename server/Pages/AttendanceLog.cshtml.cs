using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;
using PdksApp.Data;
using PdksApp.Models;

namespace PdksApp.Pages;

public class AttendanceLogModel : PageModel
{
    private readonly AppDbContext _context;

    public AttendanceLogModel(AppDbContext context)
    {
        _context = context;
    }

    public List<AttendanceRecord> Records { get; set; } = new();

    public async Task OnGetAsync()
    {
        Records = await _context.AttendanceRecords
            .Include(r => r.Employee)
            .OrderByDescending(r => r.Timestamp)
            .Take(50)
            .ToListAsync();
    }
}
