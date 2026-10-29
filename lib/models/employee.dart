import 'package:flutter/material.dart';

enum UserRole { employee, hr, boss, admin, cafeteria }

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
      case UserRole.cafeteria:
        return 'Yemekhane Personeli';
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
      case UserRole.cafeteria:
        return 'Yemekhane';
    }
  }
}

class AppRoleItem {
  final String id;
  final String name;
  final String description;
  final UserRole baseRole;
  final Color color;
  final IconData icon;
  final bool isSystemRole;
  final String createdBy;

  const AppRoleItem({
    required this.id,
    required this.name,
    required this.description,
    required this.baseRole,
    required this.color,
    required this.icon,
    this.isSystemRole = false,
    this.createdBy = 'Sistem',
  });
}

class Employee {
  final int id;
  final String companyId; // Şirket / Tenant Kimliği
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
  final bool isApproved;
  final DateTime? registeredAt;
  final String? avatarUrl;
  final String? customRoleId;
  final String? customRoleName;
  final double baseGrossSalary;
  final String tcKimlikNo;
  final String iban;
  final String bankName;

  Employee({
    required this.id,
    this.companyId = 'cmp_acme',
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
    this.isApproved = true,
    this.registeredAt,
    this.avatarUrl,
    this.customRoleId,
    this.customRoleName,
    this.baseGrossSalary = 52000.0,
    this.tcKimlikNo = '28491028472',
    this.iban = 'TR42 0006 2000 0001 2345 6789 01',
    this.bankName = 'Garanti BBVA',
  });

  int get remainingLeaveDays => annualLeaveAllowance - usedLeaveDays;

  String get roleDisplayName => customRoleName ?? role.label;

  Employee copyWith({
    int? id,
    String? companyId,
    String? fullName,
    String? email,
    String? phone,
    String? department,
    String? title,
    String? pinCode,
    UserRole? role,
    int? annualLeaveAllowance,
    int? usedLeaveDays,
    bool? isActive,
    bool? isApproved,
    DateTime? registeredAt,
    String? avatarUrl,
    String? customRoleId,
    String? customRoleName,
    bool clearCustomRole = false,
    double? baseGrossSalary,
    String? tcKimlikNo,
    String? iban,
    String? bankName,
  }) {
    return Employee(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      department: department ?? this.department,
      title: title ?? this.title,
      pinCode: pinCode ?? this.pinCode,
      role: role ?? this.role,
      annualLeaveAllowance: annualLeaveAllowance ?? this.annualLeaveAllowance,
      usedLeaveDays: usedLeaveDays ?? this.usedLeaveDays,
      isActive: isActive ?? this.isActive,
      isApproved: isApproved ?? this.isApproved,
      registeredAt: registeredAt ?? this.registeredAt,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      customRoleId: clearCustomRole ? null : (customRoleId ?? this.customRoleId),
      customRoleName: clearCustomRole ? null : (customRoleName ?? this.customRoleName),
      baseGrossSalary: baseGrossSalary ?? this.baseGrossSalary,
      tcKimlikNo: tcKimlikNo ?? this.tcKimlikNo,
      iban: iban ?? this.iban,
      bankName: bankName ?? this.bankName,
    );
  }

  factory Employee.fromJson(Map<String, dynamic> json) {
    UserRole parsedRole = UserRole.employee;
    final r = json['role']?.toString().toLowerCase();
    if (r == 'hr' || r == 'hradmin') parsedRole = UserRole.hr;
    if (r == 'boss' || r == 'patron' || r == 'ceo') parsedRole = UserRole.boss;
    if (r == 'admin') parsedRole = UserRole.admin;
    if (r == 'cafeteria' || r == 'yemekhane') parsedRole = UserRole.cafeteria;

    return Employee(
      id: json['id'] ?? 0,
      companyId: json['companyId'] ?? 'cmp_acme',
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
      isApproved: json['isApproved'] ?? true,
      registeredAt: json['registeredAt'] != null ? DateTime.tryParse(json['registeredAt']) : null,
      avatarUrl: json['avatarUrl'],
      customRoleId: json['customRoleId'],
      customRoleName: json['customRoleName'],
      baseGrossSalary: (json['baseGrossSalary'] as num?)?.toDouble() ?? 52000.0,
      tcKimlikNo: json['tcKimlikNo'] ?? '28491028472',
      iban: json['iban'] ?? 'TR42 0006 2000 0001 2345 6789 01',
      bankName: json['bankName'] ?? 'Garanti BBVA',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyId': companyId,
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
      'isApproved': isApproved,
      'registeredAt': registeredAt?.toIso8601String(),
      'avatarUrl': avatarUrl,
      'customRoleId': customRoleId,
      'customRoleName': customRoleName,
      'baseGrossSalary': baseGrossSalary,
      'tcKimlikNo': tcKimlikNo,
      'iban': iban,
      'bankName': bankName,
    };
  }
}
