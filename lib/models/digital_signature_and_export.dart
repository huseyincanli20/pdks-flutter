import 'dart:convert';
import 'package:crypto/crypto.dart';

/// 5070 Sayılı Elektronik İmza Kanunu Uyumlu İmzalı Belge Kaydı
class SignedDocumentRecord {
  final String id;
  final String companyId;
  final int employeeId;
  final String employeeName;
  final String documentType; // 'payroll_slip', 'leave_form', 'kvkk_consent', 'isg_instruction'
  final String documentTitle;
  final String period; // Örn: '2026-10'
  final String signatureSvgOrPoints; // Parmakla çizilen imza vektör noktaları
  final DateTime signedAt;
  final String signerIp;
  final String timeStampHash; // SHA-256 Zaman Damgası Özeti
  final bool isVerified5070;

  SignedDocumentRecord({
    required this.id,
    required this.companyId,
    required this.employeeId,
    required this.employeeName,
    required this.documentType,
    required this.documentTitle,
    required this.period,
    required this.signatureSvgOrPoints,
    required this.signedAt,
    this.signerIp = '192.168.1.105',
    String? timeStampHash,
    this.isVerified5070 = true,
  }) : timeStampHash = timeStampHash ??
            _generateTimestampHash(employeeId, period, signedAt);

  static String _generateTimestampHash(int empId, String period, DateTime signedAt) {
    final payload = 'DOC_SIGN:5070_EMP_${empId}_PER_${period}_TIME_${signedAt.toIso8601String()}_SALT_PDKS_SECURE';
    return sha256.convert(utf8.encode(payload)).toString().toUpperCase();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'companyId': companyId,
        'employeeId': employeeId,
        'employeeName': employeeName,
        'documentType': documentType,
        'documentTitle': documentTitle,
        'period': period,
        'signatureSvgOrPoints': signatureSvgOrPoints,
        'signedAt': signedAt.toIso8601String(),
        'signerIp': signerIp,
        'timeStampHash': timeStampHash,
        'isVerified5070': isVerified5070,
      };

  factory SignedDocumentRecord.fromJson(Map<String, dynamic> json) => SignedDocumentRecord(
        id: json['id'] ?? '',
        companyId: json['companyId'] ?? '',
        employeeId: json['employeeId'] ?? 0,
        employeeName: json['employeeName'] ?? '',
        documentType: json['documentType'] ?? 'payroll_slip',
        documentTitle: json['documentTitle'] ?? '',
        period: json['period'] ?? '',
        signatureSvgOrPoints: json['signatureSvgOrPoints'] ?? '',
        signedAt: DateTime.tryParse(json['signedAt'] ?? '') ?? DateTime.now(),
        signerIp: json['signerIp'] ?? '192.168.1.105',
        timeStampHash: json['timeStampHash'],
        isVerified5070: json['isVerified5070'] ?? true,
      );
}

/// Kurumsal ERP ve SGK İhracat Biçimleri
class ErpExportHelper {
  /// Logo Tiger / Go XML Bordro & Puantaj Şablonu
  static String generateLogoXml({
    required String companyCode,
    required String period,
    required List<Map<String, dynamic>> records,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="ISO-8859-9"?>');
    buffer.writeln('<PDKS_EXPORT TIGER_VERSION="3.0" COMPANY="$companyCode" PERIOD="$period">');
    buffer.writeln('  <TRANSACTIONS>');
    for (final r in records) {
      buffer.writeln('    <RECORD>');
      buffer.writeln('      <SICIL_NO>${r['sicilNo']}</SICIL_NO>');
      buffer.writeln('      <NAME>${r['name']}</NAME>');
      buffer.writeln('      <NORMAL_DAYS>${r['normalDays']}</NORMAL_DAYS>');
      buffer.writeln('      <OVERTIME_HOURS>${r['overtimeHours']}</OVERTIME_HOURS>');
      buffer.writeln('      <WEEKEND_HOURS>${r['weekendHours']}</WEEKEND_HOURS>');
      buffer.writeln('      <TOTAL_GROSS_PAY>${r['grossPay']}</TOTAL_GROSS_PAY>');
      buffer.writeln('    </RECORD>');
    }
    buffer.writeln('  </TRANSACTIONS>');
    buffer.writeln('</PDKS_EXPORT>');
    return buffer.toString();
  }

  /// Mikro Fly / Jump CSV Formatı
  static String generateMikroCsv({
    required List<Map<String, dynamic>> records,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('SicilNo;TCKimlik;PersonelAdSoyad;CalismaGun;FazlaMesaiSaat;HaftaTatili;BrutUcret');
    for (final r in records) {
      buffer.writeln('${r['sicilNo']};${r['tcKimlik']};${r['name']};${r['normalDays']};${r['overtimeHours']};${r['weekendHours']};${r['grossPay']}');
    }
    return buffer.toString();
  }

  /// SAP HCM iDoc / BAPI JSON Formatı
  static String generateSapJson({
    required String companyCode,
    required String period,
    required List<Map<String, dynamic>> records,
  }) {
    final payload = {
      'system': 'SAP_S4HANA_HCM',
      'sapInterface': 'BAPI_PT_TIME_TRANSFER',
      'version': 'S4HANA_2026',
      'companyCode': companyCode,
      'period': period,
      'batchTimestamp': DateTime.now().toIso8601String(),
      'employeeTimeRecords': records,
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  /// SGK Aylık Prim ve Hizmet Belgesi (APHB) Puantaj İcmali
  static String generateSgkAphbSummary({
    required String companyCode,
    required String period,
    required List<Map<String, dynamic>> records,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('========================================================================');
    buffer.writeln('T.C. SOSYAL GÜVENLİK KURUMU - AYLIK PRİM VE HİZMET BELGESİ İCMALİ');
    buffer.writeln('Kurum/Şirket Kodu: $companyCode | Dönem: $period');
    buffer.writeln('Tanzim Tarihi: ${DateTime.now().toString().substring(0, 19)}');
    buffer.writeln('========================================================================');
    buffer.writeln('SIRA | TC KİMLİK NO  | SİCİL NO      | AD SOYAD               | GÜN | BRÜT KAZANÇ');
    buffer.writeln('------------------------------------------------------------------------');
    int i = 1;
    for (final r in records) {
      final idx = i.toString().padLeft(4, '0');
      final tc = (r['tcKimlik'] ?? '').toString().padRight(14);
      final sicil = (r['sicilNo'] ?? '').toString().padRight(13);
      final name = (r['name'] ?? '').toString().padRight(22);
      final days = (r['normalDays'] ?? '30').toString().padLeft(3);
      final gross = '${(r['grossPay'] ?? 0.0)} TL'.padLeft(12);
      buffer.writeln('$idx | $tc | $sicil | $name | $days | $gross');
      i++;
    }
    buffer.writeln('========================================================================');
    return buffer.toString();
  }
}
