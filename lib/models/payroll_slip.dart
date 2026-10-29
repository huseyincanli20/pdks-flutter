import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum PayrollStatus { draft, approved, paid }

extension PayrollStatusExtension on PayrollStatus {
  String get label {
    switch (this) {
      case PayrollStatus.draft:
        return 'Taslak';
      case PayrollStatus.approved:
        return 'Onaylandı';
      case PayrollStatus.paid:
        return 'Ödendi';
    }
  }

  Color get color {
    switch (this) {
      case PayrollStatus.draft:
        return const Color(0xFFF59E0B);
      case PayrollStatus.approved:
        return const Color(0xFF0284C7);
      case PayrollStatus.paid:
        return const Color(0xFF10B981);
    }
  }

  IconData get icon {
    switch (this) {
      case PayrollStatus.draft:
        return Icons.edit_note_rounded;
      case PayrollStatus.approved:
        return Icons.verified_outlined;
      case PayrollStatus.paid:
        return Icons.check_circle_outline_rounded;
    }
  }
}

class PayrollSlip {
  final String id;
  final String companyId;
  final String companyName;
  final int employeeId;
  final String employeeName;
  final String employeeTitle;
  final String department;
  final String tcKimlikNo;
  final String sicilNo;
  final String iban;
  final String bankName;
  final int periodMonth;
  final int periodYear;
  final DateTime issueDate;
  final DateTime paymentDate;
  final int workedDays;
  final double workedHours;
  final double overtimeHours;
  final double missingHours;
  final double baseGrossSalary;
  final double overtimePay;
  final double mealAllowance;
  final double travelAllowance;
  final double bonus;
  final double sgkEmployeeRate;
  final double unemploymentEmployeeRate;
  final double incomeTax;
  final double stampTax;
  final double taxExemption; // Asgari Ücret Vergi İstisnası
  final double sgkEmployerRate;
  final double unemploymentEmployerRate;
  PayrollStatus status;
  final bool isSigned;
  final DateTime? signatureTimestamp;

  PayrollSlip({
    required this.id,
    required this.companyId,
    required this.companyName,
    required this.employeeId,
    required this.employeeName,
    required this.employeeTitle,
    required this.department,
    required this.tcKimlikNo,
    required this.sicilNo,
    required this.iban,
    required this.bankName,
    required this.periodMonth,
    required this.periodYear,
    required this.issueDate,
    required this.paymentDate,
    this.workedDays = 22,
    this.workedHours = 176.0,
    this.overtimeHours = 0.0,
    this.missingHours = 0.0,
    required this.baseGrossSalary,
    this.overtimePay = 0.0,
    this.mealAllowance = 4500.0,
    this.travelAllowance = 1800.0,
    this.bonus = 0.0,
    this.sgkEmployeeRate = 0.14,
    this.unemploymentEmployeeRate = 0.01,
    required this.incomeTax,
    required this.stampTax,
    this.taxExemption = 3200.0,
    this.sgkEmployerRate = 0.205,
    this.unemploymentEmployerRate = 0.02,
    this.status = PayrollStatus.paid,
    this.isSigned = true,
    this.signatureTimestamp,
  });

  String get periodName {
    final months = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    final m = (periodMonth >= 1 && periodMonth <= 12) ? months[periodMonth - 1] : 'Ay $periodMonth';
    return '$m $periodYear';
  }

  // Toplam Brüt / Gelirler
  double get totalEarnings => baseGrossSalary + overtimePay + mealAllowance + travelAllowance + bonus;

  // SGK Matrahı (Genelde Brüt + Mesai + Prim)
  double get sgkBase => baseGrossSalary + overtimePay + bonus;

  // SGK İşçi Payı (%14)
  double get sgkEmployeeDeduction => sgkBase * sgkEmployeeRate;

  // İşsizlik Sigortası İşçi Payı (%1)
  double get unemploymentEmployeeDeduction => sgkBase * unemploymentEmployeeRate;

  // Toplam Yasal Kesintiler (İstisna düşülmüş)
  double get totalDeductions {
    final rawTax = (incomeTax + stampTax) - taxExemption;
    final netTax = rawTax < 0 ? 0.0 : rawTax;
    return sgkEmployeeDeduction + unemploymentEmployeeDeduction + netTax;
  }

  // Net Ödenecek Maaş
  double get netSalary => totalEarnings - totalDeductions;

  // İşveren Maliyetleri (İK & Yönetim için)
  double get sgkEmployerDeduction => sgkBase * sgkEmployerRate;
  double get unemploymentEmployerDeduction => sgkBase * unemploymentEmployerRate;
  double get totalEmployerCost => totalEarnings + sgkEmployerDeduction + unemploymentEmployerDeduction;

  String formatCurrency(double amount) {
    final formatter = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2);
    return formatter.format(amount);
  }

  PayrollSlip copyWith({
    PayrollStatus? status,
    bool? isSigned,
    DateTime? signatureTimestamp,
  }) {
    return PayrollSlip(
      id: id,
      companyId: companyId,
      companyName: companyName,
      employeeId: employeeId,
      employeeName: employeeName,
      employeeTitle: employeeTitle,
      department: department,
      tcKimlikNo: tcKimlikNo,
      sicilNo: sicilNo,
      iban: iban,
      bankName: bankName,
      periodMonth: periodMonth,
      periodYear: periodYear,
      issueDate: issueDate,
      paymentDate: paymentDate,
      workedDays: workedDays,
      workedHours: workedHours,
      overtimeHours: overtimeHours,
      missingHours: missingHours,
      baseGrossSalary: baseGrossSalary,
      overtimePay: overtimePay,
      mealAllowance: mealAllowance,
      travelAllowance: travelAllowance,
      bonus: bonus,
      sgkEmployeeRate: sgkEmployeeRate,
      unemploymentEmployeeRate: unemploymentEmployeeRate,
      incomeTax: incomeTax,
      stampTax: stampTax,
      taxExemption: taxExemption,
      sgkEmployerRate: sgkEmployerRate,
      unemploymentEmployerRate: unemploymentEmployerRate,
      status: status ?? this.status,
      isSigned: isSigned ?? this.isSigned,
      signatureTimestamp: signatureTimestamp ?? this.signatureTimestamp,
    );
  }
}
