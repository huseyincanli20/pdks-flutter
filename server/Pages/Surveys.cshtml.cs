using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;
using PdksApp.Data;
using PdksApp.Models;

namespace PdksApp.Pages;

public class SurveysModel : PageModel
{
    private readonly AppDbContext _context;

    public SurveysModel(AppDbContext context)
    {
        _context = context;
    }

    public List<Survey> Surveys { get; set; } = new();
    public List<Employee> Employees { get; set; } = new();

    public async Task OnGetAsync()
    {
        Employees = await _context.Employees.Where(e => e.IsActive).ToListAsync();
        Surveys = await _context.Surveys
            .Include(s => s.Responses)
                .ThenInclude(r => r.Employee)
            .ToListAsync();
    }
}
