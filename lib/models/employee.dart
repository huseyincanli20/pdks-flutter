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
  final String? customRoleId;
  final String? customRoleName;

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
    this.customRoleId,
    this.customRoleName,
  });

  int get remainingLeaveDays => annualLeaveAllowance - usedLeaveDays;

  String get roleDisplayName => customRoleName ?? role.label;

  Employee copyWith({
    int? id,
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
    String? avatarUrl,
    String? customRoleId,
    String? customRoleName,
    bool clearCustomRole = false,
  }) {
    return Employee(
      id: id ?? this.id,
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
      avatarUrl: avatarUrl ?? this.avatarUrl,
      customRoleId: clearCustomRole ? null : (customRoleId ?? this.customRoleId),
      customRoleName: clearCustomRole ? null : (customRoleName ?? this.customRoleName),
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
      customRoleId: json['customRoleId'],
      customRoleName: json['customRoleName'],
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
      'customRoleId': customRoleId,
      'customRoleName': customRoleName,
    };
  }
}
