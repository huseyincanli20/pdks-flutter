namespace PdksApp.Models;

public record CreateLeaveRequestDto(
    int EmployeeId,
    string PinCode,
    int LeaveType,
    string StartDate,
    string EndDate,
    string Reason
);

public record ProcessLeaveRequestDto(
    int RequestId,
    int NewStatus,
    string? ManagerComment
);
