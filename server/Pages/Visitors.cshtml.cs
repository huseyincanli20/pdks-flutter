using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;
using PdksApp.Data;
using PdksApp.Models;

namespace PdksApp.Pages;

public class VisitorsModel : PageModel
{
    private readonly AppDbContext _context;

    public VisitorsModel(AppDbContext context)
    {
        _context = context;
    }

    public List<VisitorEntry> Visitors { get; set; } = new();
    public int ActiveVisitorCount { get; set; }

    public async Task OnGetAsync()
    {
        Visitors = await _context.VisitorEntries
            .OrderByDescending(v => v.CheckInTime)
            .ToListAsync();

        ActiveVisitorCount = Visitors.Count(v => v.CheckOutTime == null);
    }
}
