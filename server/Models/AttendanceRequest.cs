namespace PdksApp.Models;

public record AttendanceRequest(
    int EmployeeId,
    string PinCode,
    int AttendanceType,
    double Latitude,
    double Longitude,
    string? DeviceInfo
);
