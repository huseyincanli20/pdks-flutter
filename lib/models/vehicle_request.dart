import 'package:flutter/material.dart';

enum VehicleRequestStatus {
  pending,
  approved,
  rejected,
  inUse,
  completed,
}

extension VehicleRequestStatusExtension on VehicleRequestStatus {
  String get label {
    switch (this) {
      case VehicleRequestStatus.pending:
        return 'Onay Bekliyor';
      case VehicleRequestStatus.approved:
        return 'Onaylandı (Araç Tahsis)';
      case VehicleRequestStatus.rejected:
        return 'Reddedildi';
      case VehicleRequestStatus.inUse:
        return 'Kullanımda / Seferde';
      case VehicleRequestStatus.completed:
        return 'Tamamlandı';
    }
  }

  Color get color {
    switch (this) {
      case VehicleRequestStatus.pending:
        return const Color(0xFFD97706); // Amber
      case VehicleRequestStatus.approved:
        return const Color(0xFF10B981); // Emerald
      case VehicleRequestStatus.rejected:
        return const Color(0xFFEF4444); // Red
      case VehicleRequestStatus.inUse:
        return const Color(0xFF2563EB); // Blue
      case VehicleRequestStatus.completed:
        return const Color(0xFF6B7280); // Gray
    }
  }

  IconData get icon {
    switch (this) {
      case VehicleRequestStatus.pending:
        return Icons.hourglass_top_rounded;
      case VehicleRequestStatus.approved:
        return Icons.check_circle_outline_rounded;
      case VehicleRequestStatus.rejected:
        return Icons.cancel_outlined;
      case VehicleRequestStatus.inUse:
        return Icons.directions_car_rounded;
      case VehicleRequestStatus.completed:
        return Icons.task_alt_rounded;
    }
  }
}

class VehicleRequest {
  final String id;
  final String companyId;
  final int employeeId;
  final String employeeName;
  final String employeeDepartment;
  final String employeeTitle;
  final String vehicleType; // 'Binek Otomobil', 'SUV / 4x4', 'Hafif Ticari', 'Minibüs / Servis', 'VIP Araç'
  final DateTime startDate;
  final DateTime endDate;
  final String destination;
  final String purpose;
  final int passengerCount;
  final bool needsDriver;
  final String? notes;
  final VehicleRequestStatus status;
  final String? assignedVehicle; // Örn: '34 ACME 2024 - Renault Megane'
  final String? assignedDriver; // Örn: 'Personel Kendisi' veya 'Murat Şen (Şoför)'
  final String? approvalNote;
  final String? approvedBy;
  final DateTime createdAt;

  VehicleRequest({
    required this.id,
    this.companyId = 'cmp_acme',
    required this.employeeId,
    required this.employeeName,
    required this.employeeDepartment,
    required this.employeeTitle,
    required this.vehicleType,
    required this.startDate,
    required this.endDate,
    required this.destination,
    required this.purpose,
    this.passengerCount = 1,
    this.needsDriver = false,
    this.notes,
    this.status = VehicleRequestStatus.pending,
    this.assignedVehicle,
    this.assignedDriver,
    this.approvalNote,
    this.approvedBy,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Duration get duration => endDate.difference(startDate);

  String get durationLabel {
    final d = duration;
    if (d.inDays > 0) {
      final hours = d.inHours % 24;
      return hours > 0 ? '${d.inDays} gün $hours saat' : '${d.inDays} gün';
    }
    return '${d.inHours} saat';
  }

  VehicleRequest copyWith({
    String? id,
    String? companyId,
    int? employeeId,
    String? employeeName,
    String? employeeDepartment,
    String? employeeTitle,
    String? vehicleType,
    DateTime? startDate,
    DateTime? endDate,
    String? destination,
    String? purpose,
    int? passengerCount,
    bool? needsDriver,
    String? notes,
    VehicleRequestStatus? status,
    String? assignedVehicle,
    String? assignedDriver,
    String? approvalNote,
    String? approvedBy,
    DateTime? createdAt,
  }) {
    return VehicleRequest(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      employeeDepartment: employeeDepartment ?? this.employeeDepartment,
      employeeTitle: employeeTitle ?? this.employeeTitle,
      vehicleType: vehicleType ?? this.vehicleType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      destination: destination ?? this.destination,
      purpose: purpose ?? this.purpose,
      passengerCount: passengerCount ?? this.passengerCount,
      needsDriver: needsDriver ?? this.needsDriver,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      assignedVehicle: assignedVehicle ?? this.assignedVehicle,
      assignedDriver: assignedDriver ?? this.assignedDriver,
      approvalNote: approvalNote ?? this.approvalNote,
      approvedBy: approvedBy ?? this.approvedBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyId': companyId,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'employeeDepartment': employeeDepartment,
      'employeeTitle': employeeTitle,
      'vehicleType': vehicleType,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'destination': destination,
      'purpose': purpose,
      'passengerCount': passengerCount,
      'needsDriver': needsDriver,
      'notes': notes,
      'status': status.name,
      'assignedVehicle': assignedVehicle,
      'assignedDriver': assignedDriver,
      'approvalNote': approvalNote,
      'approvedBy': approvedBy,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory VehicleRequest.fromJson(Map<String, dynamic> json) {
    VehicleRequestStatus parsedStatus = VehicleRequestStatus.pending;
    final s = json['status']?.toString().toLowerCase();
    for (final val in VehicleRequestStatus.values) {
      if (val.name.toLowerCase() == s) {
        parsedStatus = val;
        break;
      }
    }

    return VehicleRequest(
      id: json['id'] ?? '',
      companyId: json['companyId'] ?? 'cmp_acme',
      employeeId: json['employeeId'] ?? 0,
      employeeName: json['employeeName'] ?? '',
      employeeDepartment: json['employeeDepartment'] ?? '',
      employeeTitle: json['employeeTitle'] ?? '',
      vehicleType: json['vehicleType'] ?? 'Binek Otomobil',
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate']) ?? DateTime.now()
          : DateTime.now(),
      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate']) ?? DateTime.now().add(const Duration(hours: 4))
          : DateTime.now().add(const Duration(hours: 4)),
      destination: json['destination'] ?? '',
      purpose: json['purpose'] ?? '',
      passengerCount: json['passengerCount'] ?? 1,
      needsDriver: json['needsDriver'] ?? false,
      notes: json['notes'],
      status: parsedStatus,
      assignedVehicle: json['assignedVehicle'],
      assignedDriver: json['assignedDriver'],
      approvalNote: json['approvalNote'],
      approvedBy: json['approvedBy'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
