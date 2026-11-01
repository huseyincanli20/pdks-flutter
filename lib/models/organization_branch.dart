class CompanyBranch {
  final String id;
  final String companyId;
  final String name; // 'Ankara Genel Merkez', 'İstanbul Ar-Ge Ofisi', 'İzmir Lojistik Tesisi'
  final String code; // 'ANK-01', 'IST-02', 'IZM-03'
  final String city;
  final String address;
  final int managerId;
  final String managerName;
  final List<String> departments;
  final int employeeCount;

  CompanyBranch({
    required this.id,
    required this.companyId,
    required this.name,
    required this.code,
    required this.city,
    required this.address,
    required this.managerId,
    required this.managerName,
    required this.departments,
    this.employeeCount = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'companyId': companyId,
        'name': name,
        'code': code,
        'city': city,
        'address': address,
        'managerId': managerId,
        'managerName': managerName,
        'departments': departments,
        'employeeCount': employeeCount,
      };

  factory CompanyBranch.fromJson(Map<String, dynamic> json) => CompanyBranch(
        id: json['id'] ?? '',
        companyId: json['companyId'] ?? 'cmp_acme',
        name: json['name'] ?? '',
        code: json['code'] ?? '',
        city: json['city'] ?? '',
        address: json['address'] ?? '',
        managerId: json['managerId'] ?? 0,
        managerName: json['managerName'] ?? '',
        departments: (json['departments'] as List?)?.map((e) => e.toString()).toList() ?? [],
        employeeCount: json['employeeCount'] ?? 0,
      );
}

class ApprovalDelegation {
  final String id;
  final String companyId;
  final int managerId;
  final String managerName;
  final int delegateEmployeeId;
  final String delegateEmployeeName;
  final DateTime startDate;
  final DateTime endDate;
  final String scope; // 'all', 'leave', 'shift', 'vehicle', 'expense'
  final bool isActive;

  ApprovalDelegation({
    required this.id,
    required this.companyId,
    required this.managerId,
    required this.managerName,
    required this.delegateEmployeeId,
    required this.delegateEmployeeName,
    required this.startDate,
    required this.endDate,
    this.scope = 'all',
    this.isActive = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'companyId': companyId,
        'managerId': managerId,
        'managerName': managerName,
        'delegateEmployeeId': delegateEmployeeId,
        'delegateEmployeeName': delegateEmployeeName,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'scope': scope,
        'isActive': isActive,
      };

  factory ApprovalDelegation.fromJson(Map<String, dynamic> json) => ApprovalDelegation(
        id: json['id'] ?? '',
        companyId: json['companyId'] ?? 'cmp_acme',
        managerId: json['managerId'] ?? 0,
        managerName: json['managerName'] ?? '',
        delegateEmployeeId: json['delegateEmployeeId'] ?? 0,
        delegateEmployeeName: json['delegateEmployeeName'] ?? '',
        startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : DateTime.now(),
        endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : DateTime.now().add(const Duration(days: 7)),
        scope: json['scope'] ?? 'all',
        isActive: json['isActive'] ?? true,
      );

  ApprovalDelegation copyWith({bool? isActive}) => ApprovalDelegation(
        id: id,
        companyId: companyId,
        managerId: managerId,
        managerName: managerName,
        delegateEmployeeId: delegateEmployeeId,
        delegateEmployeeName: delegateEmployeeName,
        startDate: startDate,
        endDate: endDate,
        scope: scope,
        isActive: isActive ?? this.isActive,
      );
}
