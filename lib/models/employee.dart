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

class AppPageDefinition {
  final String id;
  final String title;
  final String category;
  final IconData icon;

  const AppPageDefinition({
    required this.id,
    required this.title,
    required this.category,
    required this.icon,
  });
}

const List<AppPageDefinition> kAllAppPages = [
  AppPageDefinition(id: 'profile', title: 'Profil & İzin Bakiyesi', category: 'Temel Modüller', icon: Icons.person_rounded),
  AppPageDefinition(id: 'payroll', title: 'Bordro & Maaş Yönetimi', category: 'İK & Finans', icon: Icons.receipt_long_rounded),
  AppPageDefinition(id: 'chat', title: 'Mesajlaşma & Ekip Sohbeti', category: 'İletişim', icon: Icons.chat_bubble_rounded),
  AppPageDefinition(id: 'contacts', title: 'Kişiler & Şirket Rehberi', category: 'İletişim', icon: Icons.people_alt_rounded),
  AppPageDefinition(id: 'notifications', title: 'Bildirimler & Duyurular', category: 'İletişim', icon: Icons.notifications_rounded),
  AppPageDefinition(id: 'cafeteria', title: 'Yemekhane Menüsü', category: 'Sosyal Tesis', icon: Icons.restaurant_rounded),
  AppPageDefinition(id: 'business_card', title: 'Dijital Kartvizit (QR)', category: 'Profil', icon: Icons.badge_rounded),
  AppPageDefinition(id: 'favorites', title: 'Sık Kullanılanlar', category: 'Hızlı Erişim', icon: Icons.star_rounded),
  AppPageDefinition(id: 'leave', title: 'İzin Talebi & Takip', category: 'Operasyon', icon: Icons.beach_access_rounded),
  AppPageDefinition(id: 'records', title: 'Giriş / Çıkış Kayıtları', category: 'Operasyon', icon: Icons.history_rounded),
  AppPageDefinition(id: 'field_work', title: 'Dışarıda Çalışma (Saha)', category: 'Operasyon', icon: Icons.location_on_rounded),
  AppPageDefinition(id: 'overtime', title: 'Fazla Mesai Talebi', category: 'Operasyon', icon: Icons.more_time_rounded),
  AppPageDefinition(id: 'settings', title: 'Uygulama Ayarları', category: 'Sistem', icon: Icons.settings_rounded),
  AppPageDefinition(id: 'about', title: 'Hakkımda & Güvenlik', category: 'Sistem', icon: Icons.info_rounded),
  AppPageDefinition(id: 'cloud_db', title: 'Firebase Bulut DB', category: 'Sistem (Korumalı)', icon: Icons.cloud_rounded),
];

class AppRoleItem {
  final String id;
  final String name;
  final String description;
  final UserRole baseRole;
  final Color color;
  final IconData icon;
  final bool isSystemRole;
  final String createdBy;
  final List<String> allowedPageIds;

  const AppRoleItem({
    required this.id,
    required this.name,
    required this.description,
    required this.baseRole,
    required this.color,
    required this.icon,
    this.isSystemRole = false,
    this.createdBy = 'Sistem',
    this.allowedPageIds = const [],
  });

  bool canAccessPage(String pageId) {
    if (baseRole == UserRole.admin || id == 'role_admin') return true;
    if (allowedPageIds.isEmpty) return true;
    return allowedPageIds.contains(pageId);
  }

  AppRoleItem copyWith({
    String? id,
    String? name,
    String? description,
    UserRole? baseRole,
    Color? color,
    IconData? icon,
    bool? isSystemRole,
    String? createdBy,
    List<String>? allowedPageIds,
  }) {
    return AppRoleItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      baseRole: baseRole ?? this.baseRole,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      isSystemRole: isSystemRole ?? this.isSystemRole,
      createdBy: createdBy ?? this.createdBy,
      allowedPageIds: allowedPageIds ?? this.allowedPageIds,
    );
  }
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
  final DateTime? hireDate;
  final int? heightCm;
  final int? weightKg;
  final String? shirtSize;
  final String? pantSize;
  final int? shoeSize;
  final String? outerwearSize;

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
    this.hireDate,
    this.heightCm,
    this.weightKg,
    this.shirtSize,
    this.pantSize,
    this.shoeSize,
    this.outerwearSize,
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
    DateTime? hireDate,
    int? heightCm,
    int? weightKg,
    String? shirtSize,
    String? pantSize,
    int? shoeSize,
    String? outerwearSize,
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
      hireDate: hireDate ?? this.hireDate,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      shirtSize: shirtSize ?? this.shirtSize,
      pantSize: pantSize ?? this.pantSize,
      shoeSize: shoeSize ?? this.shoeSize,
      outerwearSize: outerwearSize ?? this.outerwearSize,
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
      hireDate: json['hireDate'] != null ? DateTime.tryParse(json['hireDate']) : null,
      heightCm: json['heightCm'],
      weightKg: json['weightKg'],
      shirtSize: json['shirtSize'],
      pantSize: json['pantSize'],
      shoeSize: json['shoeSize'],
      outerwearSize: json['outerwearSize'],
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
      'hireDate': hireDate?.toIso8601String(),
      'heightCm': heightCm,
      'weightKg': weightKg,
      'shirtSize': shirtSize,
      'pantSize': pantSize,
      'shoeSize': shoeSize,
      'outerwearSize': outerwearSize,
    };
  }
}
