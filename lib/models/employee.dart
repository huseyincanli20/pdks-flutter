enum UserRole { employee, hr, boss, admin }

extension UserRoleExtension on UserRole {
  String get label {
    switch (this) {
      case UserRole.employee:
        return 'Personel';
      case UserRole.hr:
        return 'İnsan Kaynakları (İK)';
      case UserRole.boss:
        return 'Patron (Yönetim)';
      case UserRole.admin:
        return 'Sistem Yöneticisi (Admin)';
    }
  }

  String get shortLabel {
    switch (this) {
      case UserRole.employee:
        return 'Personel';
      case UserRole.hr:
        return 'İK';
      case UserRole.boss:
        return 'Patron';
      case UserRole.admin:
        return 'Admin';
    }
  }
}

class Employee {
  final int id;
  final String fullName;
  final String email;
  final String phone;
  final String department;
  final String title;
  final String pinCode;
  final UserRole role;
  final int annualLeaveAllowance;
  final int usedLeaveDays;
  final bool isActive;
  final String? avatarUrl;

  Employee({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone = '+90 555 000 00 00',
    required this.department,
    required this.title,
    required this.pinCode,
    this.role = UserRole.employee,
    this.annualLeaveAllowance = 14,
    this.usedLeaveDays = 0,
    this.isActive = true,
    this.avatarUrl,
  });

  int get remainingLeaveDays => annualLeaveAllowance - usedLeaveDays;

  factory Employee.fromJson(Map<String, dynamic> json) {
    UserRole parsedRole = UserRole.employee;
    final r = json['role']?.toString().toLowerCase();
    if (r == 'hr' || r == 'hradmin') parsedRole = UserRole.hr;
    if (r == 'boss' || r == 'patron' || r == 'ceo') parsedRole = UserRole.boss;
    if (r == 'admin') parsedRole = UserRole.admin;

    return Employee(
      id: json['id'] ?? 0,
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '+90 555 000 00 00',
      department: json['department'] ?? 'Genel',
      title: json['title'] ?? 'Çalışan',
      pinCode: json['pinCode'] ?? '1234',
      role: parsedRole,
      annualLeaveAllowance: json['annualLeaveAllowance'] ?? 14,
      usedLeaveDays: json['usedLeaveDays'] ?? 0,
      isActive: json['isActive'] ?? true,
      avatarUrl: json['avatarUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'department': department,
      'title': title,
      'pinCode': pinCode,
      'role': role.name,
      'annualLeaveAllowance': annualLeaveAllowance,
      'usedLeaveDays': usedLeaveDays,
      'isActive': isActive,
      'avatarUrl': avatarUrl,
    };
  }
}
