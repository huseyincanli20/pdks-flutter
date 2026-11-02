using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;
using PdksApp.Data;
using PdksApp.Models;

namespace PdksApp.Pages;

public class PayrollModel : PageModel
{
    private readonly AppDbContext _context;

    public PayrollModel(AppDbContext context)
    {
        _context = context;
    }

    public List<PayrollRecord> Records { get; set; } = new();
    public decimal TotalNetPayout { get; set; }
    public decimal TotalOvertimePayout { get; set; }

    public async Task OnGetAsync()
    {
        Records = await _context.PayrollRecords
            .Include(p => p.Employee)
            .OrderByDescending(p => p.Year)
            .ThenByDescending(p => p.Month)
            .ToListAsync();

        TotalNetPayout = Records.Sum(p => p.NetSalary);
        TotalOvertimePayout = Records.Sum(p => p.OvertimePay);
    }
}
