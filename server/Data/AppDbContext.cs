using Microsoft.EntityFrameworkCore;
using PdksApp.Models;

namespace PdksApp.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options)
    {
    }

    public DbSet<Company> Companies => Set<Company>();
    public DbSet<Employee> Employees => Set<Employee>();
    public DbSet<AttendanceRecord> AttendanceRecords => Set<AttendanceRecord>();
    public DbSet<LeaveRequest> LeaveRequests => Set<LeaveRequest>();
    public DbSet<OvertimeRecord> OvertimeRecords => Set<OvertimeRecord>();
    public DbSet<LaborRequest> LaborRequests => Set<LaborRequest>();
    public DbSet<VisitorEntry> VisitorEntries => Set<VisitorEntry>();
    public DbSet<PayrollRecord> PayrollRecords => Set<PayrollRecord>();
    public DbSet<Survey> Surveys => Set<Survey>();
    public DbSet<SurveyResponse> SurveyResponses => Set<SurveyResponse>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        var demoCompany = new Company
        {
            Id = 1,
            Name = "Atlas Bilişim A.Ş.",
            ContactEmail = "info@atlasbilisim.com",
            ContactPhone = "+90 555 123 4567",
            Plan = SubscriptionPlan.Monthly,
            MonthlyPrice = 200.00m,
            YearlyPrice = 2000.00m,
            SubscriptionStartDate = DateTime.UtcNow,
            SubscriptionEndDate = DateTime.UtcNow.AddMonths(1),
            OfficeLatitude = 41.0082,
            OfficeLongitude = 28.9784,
            AllowedRadiusMeters = 250.0
        };

        modelBuilder.Entity<Company>().HasData(demoCompany);

        modelBuilder.Entity<Employee>().HasData(
            new Employee
            {
                Id = 1,
                CompanyId = 1,
                FullName = "Ahmet Yılmaz",
                PinCode = "1001",
                Email = "ahmet@atlasbilisim.com",
                Department = "Yazılım",
                Title = "Kıdemli Geliştirici",
                BaseSalary = 45000.00m,
                HourlyRate = 250.00m,
                AnnualLeaveAllowance = 14,
                UsedLeaveDays = 3
            },
            new Employee
            {
                Id = 2,
                CompanyId = 1,
                FullName = "Ayşe Kaya",
                PinCode = "1002",
                Email = "ayse@atlasbilisim.com",
                Department = "İnsan Kaynakları",
                Title = "İK Uzmanı",
                BaseSalary = 35000.00m,
                HourlyRate = 200.00m,
                AnnualLeaveAllowance = 14,
                UsedLeaveDays = 0
            },
            new Employee
            {
                Id = 3,
                CompanyId = 1,
                FullName = "Mehmet Demir",
                PinCode = "1003",
                Email = "mehmet@atlasbilisim.com",
                Department = "Operasyon",
                Title = "Saha Sorumlusu",
                BaseSalary = 32000.00m,
                HourlyRate = 180.00m,
                AnnualLeaveAllowance = 14,
                UsedLeaveDays = 5
            }
        );

        // İzin Verileri
        modelBuilder.Entity<LeaveRequest>().HasData(
            new LeaveRequest
            {
                Id = 1,
                CompanyId = 1,
                EmployeeId = 1,
                Type = LeaveType.Annual,
                StartDate = DateTime.UtcNow.AddDays(5),
                EndDate = DateTime.UtcNow.AddDays(8),
                TotalDays = 3,
                Reason = "Yıllık izin kullanımı",
                Status = LeaveStatus.Pending,
                CreatedAt = DateTime.UtcNow.AddDays(-1)
            }
        );

        // Fazla Mesai Verileri
        modelBuilder.Entity<OvertimeRecord>().HasData(
            new OvertimeRecord
            {
                Id = 1,
                CompanyId = 1,
                EmployeeId = 1,
                OvertimeDate = DateTime.UtcNow.Date,
                Hours = 3.5,
                Reason = "Müşteri canlıya geçiş desteği",
                EstimatedPay = 875.00m,
                Status = ApprovalStatus.Pending,
                CreatedAt = DateTime.UtcNow.AddHours(-4)
            },
            new OvertimeRecord
            {
                Id = 2,
                CompanyId = 1,
                EmployeeId = 3,
                OvertimeDate = DateTime.UtcNow.AddDays(-2).Date,
                Hours = 2.0,
                Reason = "Haftasonu acil saha kontrolü",
                EstimatedPay = 360.00m,
                Status = ApprovalStatus.Approved,
                ManagerComment = "Onaylandı",
                CreatedAt = DateTime.UtcNow.AddDays(-2),
                ProcessedAt = DateTime.UtcNow.AddDays(-1)
            }
        );

        // İşçilik / Personel Talebi Verileri
        modelBuilder.Entity<LaborRequest>().HasData(
            new LaborRequest
            {
                Id = 1,
                CompanyId = 1,
                Department = "Yazılım",
                PositionTitle = "Fullstack .NET Geliştirici",
                HeadCount = 2,
                NeededDate = DateTime.UtcNow.AddDays(14),
                Justification = "Yeni PDKS SaaS modülleri geliştirme ekibi büyümesi",
                Urgency = "Yüksek",
                Status = ApprovalStatus.Pending,
                CreatedAt = DateTime.UtcNow.AddDays(-1)
            }
        );

        // Ziyaretçi Giriş Kayıtları
        modelBuilder.Entity<VisitorEntry>().HasData(
            new VisitorEntry
            {
                Id = 1,
                CompanyId = 1,
                VisitorFullName = "Kemal Tekin",
                CompanyOrOrganization = "Tekno Bilişim Ltd.",
                Phone = "0532 999 8877",
                HostEmployeeName = "Ahmet Yılmaz",
                Purpose = "API Entegrasyon Toplantısı",
                BadgeNumber = "Z-01",
                CheckInTime = DateTime.UtcNow.AddHours(-2),
                CheckOutTime = null
            },
            new VisitorEntry
            {
                Id = 2,
                CompanyId = 1,
                VisitorFullName = "Selin Aydın",
                CompanyOrOrganization = "Denetim Grubu",
                Phone = "0544 111 2233",
                HostEmployeeName = "Ayşe Kaya",
                Purpose = "Yıllık İK Mevzuat İncelemesi",
                BadgeNumber = "Z-02",
                CheckInTime = DateTime.UtcNow.AddHours(-5),
                CheckOutTime = DateTime.UtcNow.AddHours(-1)
            }
        );

        // Bordro Verileri
        modelBuilder.Entity<PayrollRecord>().HasData(
            new PayrollRecord
            {
                Id = 1,
                CompanyId = 1,
                EmployeeId = 1,
                Year = 2026,
                Month = 10,
                BaseSalary = 45000.00m,
                OvertimePay = 1750.00m,
                Bonus = 3000.00m,
                Deductions = 500.00m,
                NetSalary = 49250.00m,
                WorkedDays = 22,
                TotalOvertimeHours = 7.0,
                IsPaid = false,
                GeneratedAt = DateTime.UtcNow
            },
            new PayrollRecord
            {
                Id = 2,
                CompanyId = 1,
                EmployeeId = 2,
                Year = 2026,
                Month = 10,
                BaseSalary = 35000.00m,
                OvertimePay = 0.00m,
                Bonus = 1500.00m,
                Deductions = 0.00m,
                NetSalary = 36500.00m,
                WorkedDays = 22,
                TotalOvertimeHours = 0,
                IsPaid = true,
                PaidDate = DateTime.UtcNow.AddDays(-2),
                GeneratedAt = DateTime.UtcNow
            }
        );

        // Anket Verileri
        modelBuilder.Entity<Survey>().HasData(
            new Survey
            {
                Id = 1,
                CompanyId = 1,
                Title = "2026 Q4 Çalışan Memnuniyeti ve Çalışma Ortamı Anketi",
                Description = "Şirket içi çalışma şartları, yemek, servis ve esnek mesai uygulamaları hakkındaki görüşleriniz.",
                IsActive = true,
                CreatedAt = DateTime.UtcNow.AddDays(-3)
            }
        );

        modelBuilder.Entity<SurveyResponse>().HasData(
            new SurveyResponse
            {
                Id = 1,
                SurveyId = 1,
                EmployeeId = 1,
                Rating = 5,
                Feedback = "Mobil GPS ile giriş-çıkış yapabilmek inanılmaz pratik, parmak izi kuyrukları bitti.",
                SubmittedAt = DateTime.UtcNow.AddDays(-1)
            },
            new SurveyResponse
            {
                Id = 2,
                SurveyId = 1,
                EmployeeId = 3,
                Rating = 4,
                Feedback = "Saha görevlerimizde konum kontrolünün otomatik algılaması çok başarılı.",
                SubmittedAt = DateTime.UtcNow.AddDays(-2)
            }
        );
    }
}
