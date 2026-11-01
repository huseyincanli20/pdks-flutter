class VisitorRecord {
  final String id;
  final String companyId;
  final String visitorFullName;
  final String visitorCompany;
  final String visitorPhone;
  final int hostEmployeeId;
  final String hostEmployeeName;
  final String purpose;
  final DateTime expectedDate;
  final String qrPassCode;
  final String status; // 'pre_registered', 'inside', 'completed', 'cancelled'
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final bool isContractor; // Taşeron mu?
  final bool hasSafetyBriefing; // İSG eğitimi/taahhüdü verildi mi?

  VisitorRecord({
    required this.id,
    required this.companyId,
    required this.visitorFullName,
    required this.visitorCompany,
    required this.visitorPhone,
    required this.hostEmployeeId,
    required this.hostEmployeeName,
    required this.purpose,
    required this.expectedDate,
    required this.qrPassCode,
    this.status = 'pre_registered',
    this.checkInTime,
    this.checkOutTime,
    this.isContractor = false,
    this.hasSafetyBriefing = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'companyId': companyId,
        'visitorFullName': visitorFullName,
        'visitorCompany': visitorCompany,
        'visitorPhone': visitorPhone,
        'hostEmployeeId': hostEmployeeId,
        'hostEmployeeName': hostEmployeeName,
        'purpose': purpose,
        'expectedDate': expectedDate.toIso8601String(),
        'qrPassCode': qrPassCode,
        'status': status,
        'checkInTime': checkInTime?.toIso8601String(),
        'checkOutTime': checkOutTime?.toIso8601String(),
        'isContractor': isContractor,
        'hasSafetyBriefing': hasSafetyBriefing,
      };

  factory VisitorRecord.fromJson(Map<String, dynamic> json) => VisitorRecord(
        id: json['id'] ?? '',
        companyId: json['companyId'] ?? 'cmp_acme',
        visitorFullName: json['visitorFullName'] ?? '',
        visitorCompany: json['visitorCompany'] ?? '',
        visitorPhone: json['visitorPhone'] ?? '',
        hostEmployeeId: json['hostEmployeeId'] ?? 0,
        hostEmployeeName: json['hostEmployeeName'] ?? '',
        purpose: json['purpose'] ?? '',
        expectedDate: json['expectedDate'] != null ? DateTime.parse(json['expectedDate']) : DateTime.now(),
        qrPassCode: json['qrPassCode'] ?? '',
        status: json['status'] ?? 'pre_registered',
        checkInTime: json['checkInTime'] != null ? DateTime.parse(json['checkInTime']) : null,
        checkOutTime: json['checkOutTime'] != null ? DateTime.parse(json['checkOutTime']) : null,
        isContractor: json['isContractor'] ?? false,
        hasSafetyBriefing: json['hasSafetyBriefing'] ?? true,
      );

  VisitorRecord copyWith({String? status, DateTime? checkInTime, DateTime? checkOutTime}) => VisitorRecord(
        id: id,
        companyId: companyId,
        visitorFullName: visitorFullName,
        visitorCompany: visitorCompany,
        visitorPhone: visitorPhone,
        hostEmployeeId: hostEmployeeId,
        hostEmployeeName: hostEmployeeName,
        purpose: purpose,
        expectedDate: expectedDate,
        qrPassCode: qrPassCode,
        status: status ?? this.status,
        checkInTime: checkInTime ?? this.checkInTime,
        checkOutTime: checkOutTime ?? this.checkOutTime,
        isContractor: isContractor,
        hasSafetyBriefing: hasSafetyBriefing,
      );
}
