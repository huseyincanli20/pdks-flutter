using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace PdksApp.Models;

public enum SubscriptionPlan
{
    FreeTrial = 0,
    Monthly = 1,  // 200 TL/ay
    Yearly = 2    // 2000 TL/yıl
}

public enum AttendanceType
{
    CheckIn = 1,  // Giriş
    CheckOut = 2  // Çıkış
}

public enum LeaveType
{
    Annual = 1,    // Yıllık İzin
    Sick = 2,      // Rapor / Hastalık
    Excuse = 3,    // Mazeret İzni
    Unpaid = 4,    // Ücretsiz İzin
    Other = 5      // Diğer
}

public enum ApprovalStatus
{
    Pending = 0,   // Beklemede
    Approved = 1,  // Onaylandı
    Rejected = 2   // Reddedildi
}

// Geriye dönük uyumluluk için takma ad (alias)
public enum LeaveStatus
{
    Pending = 0,
    Approved = 1,
    Rejected = 2
}

public enum ApprovalItemType
{
    Leave = 1,          // İzin Talebi
    Overtime = 2,       // Fazla Mesai
    LaborRequest = 3    // İşçilik / Personel Talebi
}

// ----------------------------------------------------
// ANA ŞİRKET & PERSONEL MODELLERİ
// ----------------------------------------------------

public class Company
{
    public int Id { get; set; }

    [Required]
    [MaxLength(150)]
    public string Name { get; set; } = string.Empty;

    public string ContactEmail { get; set; } = string.Empty;
    public string ContactPhone { get; set; } = string.Empty;

    public SubscriptionPlan Plan { get; set; } = SubscriptionPlan.Monthly;
    public decimal MonthlyPrice { get; set; } = 200.00m;
    public decimal YearlyPrice { get; set; } = 2000.00m;
    public DateTime SubscriptionStartDate { get; set; } = DateTime.UtcNow;
    public DateTime SubscriptionEndDate { get; set; } = DateTime.UtcNow.AddMonths(1);
    public bool IsActive { get; set; } = true;

    public double OfficeLatitude { get; set; } = 41.0082;
    public double OfficeLongitude { get; set; } = 28.9784;
    public double AllowedRadiusMeters { get; set; } = 150.0;

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public List<Employee> Employees { get; set; } = new();
    public List<LeaveRequest> LeaveRequests { get; set; } = new();
    public List<OvertimeRecord> OvertimeRecords { get; set; } = new();
    public List<LaborRequest> LaborRequests { get; set; } = new();
    public List<VisitorEntry> VisitorEntries { get; set; } = new();
    public List<Survey> Surveys { get; set; } = new();
    public List<PayrollRecord> PayrollRecords { get; set; } = new();
}

public class Employee
{
    public int Id { get; set; }
    public int CompanyId { get; set; }
    public Company? Company { get; set; }

    [Required]
    [MaxLength(100)]
    public string FullName { get; set; } = string.Empty;

    [MaxLength(50)]
    public string PinCode { get; set; } = "1234";

    [MaxLength(100)]
    public string Email { get; set; } = string.Empty;

    [MaxLength(50)]
    public string Department { get; set; } = "Genel";

    [MaxLength(50)]
    public string Title { get; set; } = "Personel";

    public decimal BaseSalary { get; set; } = 30000.00m; // Aylık baz maaş
    public decimal HourlyRate { get; set; } = 150.00m;   // Fazla mesai saatlik ücreti

    public int AnnualLeaveAllowance { get; set; } = 14;
    public int UsedLeaveDays { get; set; } = 0;

    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public List<AttendanceRecord> AttendanceRecords { get; set; } = new();
    public List<LeaveRequest> LeaveRequests { get; set; } = new();
    public List<OvertimeRecord> OvertimeRecords { get; set; } = new();
}

// ----------------------------------------------------
// 1. ÇALIŞAN HAREKETLERİ (Giriş / Çıkış & GPS)
// ----------------------------------------------------

public class AttendanceRecord
{
    public int Id { get; set; }
    public int EmployeeId { get; set; }
    public Employee? Employee { get; set; }

    public int CompanyId { get; set; }
    public Company? Company { get; set; }

    public AttendanceType Type { get; set; }
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;

    public double UserLatitude { get; set; }
    public double UserLongitude { get; set; }
    public double CalculatedDistanceMeters { get; set; }
    public bool IsLocationVerified { get; set; }

    public string? DeviceInfo { get; set; }
    public string? Note { get; set; }
}

// ----------------------------------------------------
// 2. İZİN VE RAPOR TALEPLERİ
// ----------------------------------------------------

public class LeaveRequest
{
    public int Id { get; set; }
    public int CompanyId { get; set; }
    public Company? Company { get; set; }

    public int EmployeeId { get; set; }
    public Employee? Employee { get; set; }

    public LeaveType Type { get; set; } = LeaveType.Annual;
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public int TotalDays { get; set; } = 1;

    [MaxLength(500)]
    public string Reason { get; set; } = string.Empty;

    public LeaveStatus Status { get; set; } = LeaveStatus.Pending;
    public string? ManagerComment { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? ProcessedAt { get; set; }
}

// ----------------------------------------------------
// 3. FAZLA MESAİ TALEPLERİ VE TAKİBİ
// ----------------------------------------------------

public class OvertimeRecord
{
    public int Id { get; set; }
    public int CompanyId { get; set; }
    public Company? Company { get; set; }

    public int EmployeeId { get; set; }
    public Employee? Employee { get; set; }

    public DateTime OvertimeDate { get; set; } = DateTime.UtcNow.Date;
    public double Hours { get; set; } = 2.0; // Mesai süresi (saat)

    [MaxLength(250)]
    public string Reason { get; set; } = string.Empty; // Sebep (Proje yetiştirme, vardiya uzaması vb.)

    public decimal EstimatedPay { get; set; } = 0.0m; // Hesaplanan mesai ücreti
    public ApprovalStatus Status { get; set; } = ApprovalStatus.Pending;
    public string? ManagerComment { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? ProcessedAt { get; set; }
}

// ----------------------------------------------------
// 4. İŞÇİLİK TALEBİ (Labor Request / Eleman / Vardiya Takviyesi)
// ----------------------------------------------------

public class LaborRequest
{
    public int Id { get; set; }
    public int CompanyId { get; set; }
    public Company? Company { get; set; }

    [MaxLength(100)]
    public string Department { get; set; } = "Üretim / Depo";

    [MaxLength(100)]
    public string PositionTitle { get; set; } = "Genel Eleman";

    public int HeadCount { get; set; } = 1; // Talep edilen personel sayısı
    public DateTime NeededDate { get; set; } = DateTime.UtcNow.AddDays(7);

    [MaxLength(500)]
    public string Justification { get; set; } = string.Empty; // Gerekçe

    public string Urgency { get; set; } = "Normal"; // Acil, Normal, Kritik

    public ApprovalStatus Status { get; set; } = ApprovalStatus.Pending;
    public string? ManagerComment { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? ProcessedAt { get; set; }
}

// ----------------------------------------------------
// 5. ZİYARETÇİ GİRİŞ / ÇIKIŞ TAKİBİ
// ----------------------------------------------------

public class VisitorEntry
{
    public int Id { get; set; }
    public int CompanyId { get; set; }
    public Company? Company { get; set; }

    [Required]
    [MaxLength(100)]
    public string VisitorFullName { get; set; } = string.Empty;

    [MaxLength(100)]
    public string CompanyOrOrganization { get; set; } = string.Empty;

    [MaxLength(20)]
    public string Phone { get; set; } = string.Empty;

    [MaxLength(100)]
    public string HostEmployeeName { get; set; } = string.Empty; // Ziyaret edilen personel

    [MaxLength(200)]
    public string Purpose { get; set; } = "İş Görüşmesi";

    [MaxLength(50)]
    public string BadgeNumber { get; set; } = "Z-01"; // Ziyaretçi kart no

    public DateTime CheckInTime { get; set; } = DateTime.UtcNow;
    public DateTime? CheckOutTime { get; set; }

    public bool IsActive => CheckOutTime == null;
}

// ----------------------------------------------------
// 6. BORDROR VE MAAŞ İŞLEMLERİ (Payroll)
// ----------------------------------------------------

public class PayrollRecord
{
    public int Id { get; set; }
    public int CompanyId { get; set; }
    public Company? Company { get; set; }

    public int EmployeeId { get; set; }
    public Employee? Employee { get; set; }

    public int Year { get; set; } = 2026;
    public int Month { get; set; } = 10;

    public decimal BaseSalary { get; set; }
    public decimal OvertimePay { get; set; }
    public decimal Bonus { get; set; }
    public decimal Deductions { get; set; } // Kesintiler (Geç kalma, eksik mesai vb.)
    public decimal NetSalary { get; set; }

    public int WorkedDays { get; set; } = 22;
    public double TotalOvertimeHours { get; set; } = 0;

    public bool IsPaid { get; set; } = false;
    public DateTime? PaidDate { get; set; }
    public DateTime GeneratedAt { get; set; } = DateTime.UtcNow;
}

// ----------------------------------------------------
// 7. ANKET VE MEMNUNİYET SİSTEMİ (Surveys)
// ----------------------------------------------------

public class Survey
{
    public int Id { get; set; }
    public int CompanyId { get; set; }
    public Company? Company { get; set; }

    [Required]
    [MaxLength(200)]
    public string Title { get; set; } = string.Empty;

    [MaxLength(500)]
    public string Description { get; set; } = string.Empty;

    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public List<SurveyResponse> Responses { get; set; } = new();
}

public class SurveyResponse
{
    public int Id { get; set; }
    public int SurveyId { get; set; }
    public Survey? Survey { get; set; }

    public int EmployeeId { get; set; }
    public Employee? Employee { get; set; }

    public int Rating { get; set; } = 5; // 1-5 puan

    [MaxLength(500)]
    public string? Feedback { get; set; } // Çalışan görüşü

    public DateTime SubmittedAt { get; set; } = DateTime.UtcNow;
}
