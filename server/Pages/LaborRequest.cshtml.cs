using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;
using PdksApp.Data;
using PdksApp.Models;

namespace PdksApp.Pages;

public class LaborRequestModel : PageModel
{
    private readonly AppDbContext _context;

    public LaborRequestModel(AppDbContext context)
    {
        _context = context;
    }

    public List<LaborRequest> Requests { get; set; } = new();

    public async Task OnGetAsync()
    {
        Requests = await _context.LaborRequests
            .OrderByDescending(r => r.CreatedAt)
            .ToListAsync();
    }
}
