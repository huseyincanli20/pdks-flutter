namespace PdksApp.Models;

public record CreateOvertimeDto(int EmployeeId, string PinCode, string Date, double Hours, string Reason);
public record CreateLaborRequestDto(int CompanyId, string Department, string PositionTitle, int HeadCount, string NeededDate, string Justification, string Urgency);
public record CreateVisitorDto(string VisitorFullName, string CompanyOrOrganization, string Phone, string HostEmployeeName, string Purpose, string BadgeNumber);
public record SubmitSurveyDto(int SurveyId, int EmployeeId, int Rating, string? Feedback);
public record ProcessApprovalDto(int ItemType, int ItemId, int NewStatus, string? Comment);
