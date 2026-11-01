class HybridBooking {
  final String id;
  final String companyId;
  final int employeeId;
  final String employeeName;
  final String resourceType; // 'desk' (Masa), 'meeting_room' (Toplantı Odası), 'parking' (Otopark)
  final String resourceCode; // 'Masa A-14', 'Oda Sirius', 'Otopark P-08'
  final DateTime date;
  final String timeSlot; // 'Tam Gün (08:30 - 18:00)', '09:00 - 12:00', '13:00 - 17:00'
  final bool isWorkFromHome; // True ise Evden Çalışma Bildirimi
  final String status; // 'confirmed', 'cancelled'

  HybridBooking({
    required this.id,
    required this.companyId,
    required this.employeeId,
    required this.employeeName,
    required this.resourceType,
    required this.resourceCode,
    required this.date,
    this.timeSlot = 'Tam Gün (08:30 - 18:00)',
    this.isWorkFromHome = false,
    this.status = 'confirmed',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'companyId': companyId,
        'employeeId': employeeId,
        'employeeName': employeeName,
        'resourceType': resourceType,
        'resourceCode': resourceCode,
        'date': date.toIso8601String(),
        'timeSlot': timeSlot,
        'isWorkFromHome': isWorkFromHome,
        'status': status,
      };

  factory HybridBooking.fromJson(Map<String, dynamic> json) => HybridBooking(
        id: json['id'] ?? '',
        companyId: json['companyId'] ?? 'cmp_acme',
        employeeId: json['employeeId'] ?? 0,
        employeeName: json['employeeName'] ?? '',
        resourceType: json['resourceType'] ?? 'desk',
        resourceCode: json['resourceCode'] ?? 'Masa 1',
        date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
        timeSlot: json['timeSlot'] ?? 'Tam Gün',
        isWorkFromHome: json['isWorkFromHome'] ?? false,
        status: json['status'] ?? 'confirmed',
      );

  HybridBooking copyWith({String? status}) => HybridBooking(
        id: id,
        companyId: companyId,
        employeeId: employeeId,
        employeeName: employeeName,
        resourceType: resourceType,
        resourceCode: resourceCode,
        date: date,
        timeSlot: timeSlot,
        isWorkFromHome: isWorkFromHome,
        status: status ?? this.status,
      );
}
