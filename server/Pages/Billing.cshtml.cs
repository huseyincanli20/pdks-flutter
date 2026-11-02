using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;
using PdksApp.Data;
using PdksApp.Models;

namespace PdksApp.Pages;

public class BillingModel : PageModel
{
    private readonly AppDbContext _context;

    public BillingModel(AppDbContext context)
    {
        _context = context;
    }

    public Company? Company { get; set; }

    public async Task OnGetAsync()
    {
        Company = await _context.Companies.FirstOrDefaultAsync(c => c.Id == 1);
    }
}
