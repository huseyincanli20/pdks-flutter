import 'package:flutter/material.dart';

class Company {
  final String id;
  final String code; // Tekil Şirket Kodu (örn: ACME, NOVA, OZDEMIR)
  final String name;
  final String sector;
  final String address;
  final double officeLat;
  final double officeLng;
  final double allowedRadiusMeters;
  final String allowedWifiSsid;
  final String taxNumber;
  final String phone;
  final String email;
  final String? logoUrl;
  final Color primaryColor;
  final bool isActive;
  final DateTime createdAt;

  Company({
    required this.id,
    required this.code,
    required this.name,
    required this.sector,
    required this.address,
    required this.officeLat,
    required this.officeLng,
    this.allowedRadiusMeters = 150.0,
    required this.allowedWifiSsid,
    this.taxNumber = '1234567890',
    this.phone = '+90 850 000 00 00',
    this.email = 'info@sirket.com',
    this.logoUrl,
    this.primaryColor = const Color(0xFF2563EB),
    this.isActive = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Company copyWith({
    String? id,
    String? code,
    String? name,
    String? sector,
    String? address,
    double? officeLat,
    double? officeLng,
    double? allowedRadiusMeters,
    String? allowedWifiSsid,
    String? taxNumber,
    String? phone,
    String? email,
    String? logoUrl,
    Color? primaryColor,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Company(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      sector: sector ?? this.sector,
      address: address ?? this.address,
      officeLat: officeLat ?? this.officeLat,
      officeLng: officeLng ?? this.officeLng,
      allowedRadiusMeters: allowedRadiusMeters ?? this.allowedRadiusMeters,
      allowedWifiSsid: allowedWifiSsid ?? this.allowedWifiSsid,
      taxNumber: taxNumber ?? this.taxNumber,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      logoUrl: logoUrl ?? this.logoUrl,
      primaryColor: primaryColor ?? this.primaryColor,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'sector': sector,
      'address': address,
      'officeLat': officeLat,
      'officeLng': officeLng,
      'allowedRadiusMeters': allowedRadiusMeters,
      'allowedWifiSsid': allowedWifiSsid,
      'taxNumber': taxNumber,
      'phone': phone,
      'email': email,
      'logoUrl': logoUrl,
      'primaryColor': primaryColor.value,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id'] ?? '',
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      sector: json['sector'] ?? 'Genel',
      address: json['address'] ?? '',
      officeLat: (json['officeLat'] as num?)?.toDouble() ?? 40.01461,
      officeLng: (json['officeLng'] as num?)?.toDouble() ?? 32.51520,
      allowedRadiusMeters: (json['allowedRadiusMeters'] as num?)?.toDouble() ?? 150.0,
      allowedWifiSsid: json['allowedWifiSsid'] ?? 'Sirket_Wifi',
      taxNumber: json['taxNumber'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      logoUrl: json['logoUrl'],
      primaryColor: json['primaryColor'] != null ? Color(json['primaryColor']) : const Color(0xFF2563EB),
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }
}
