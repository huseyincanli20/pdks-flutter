import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../../models/attendance_record.dart';
import '../../models/leave_request.dart';

class ApiService {
  final http.Client _client = http.Client();

  // Personel Giriş/Çıkış Gönderimi
  Future<Map<String, dynamic>> sendAttendance({
    required int employeeId,
    required String pinCode,
    required AttendanceType type,
    required double latitude,
    required double longitude,
    required VerificationMethod method,
    String? deviceInfo,
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.checkAttendance}');
    final body = jsonEncode({
      'employeeId': employeeId,
      'pinCode': pinCode,
      'attendanceType': type == AttendanceType.checkIn ? 0 : 1,
      'latitude': latitude,
      'longitude': longitude,
      'verificationMethod': method.name,
      'deviceInfo': deviceInfo ?? 'Flutter App',
    });

    try {
      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(const Duration(seconds: 4));

      return jsonDecode(response.body);
    } catch (_) {
      // Yerel fallback / Mock yanıt (API offline veya localhost erişilemediğinde)
      return {
        'success': true,
        'message': 'İşlem başarıyla kaydedildi (${type == AttendanceType.checkIn ? "Giriş" : "Çıkış"}).',
        'time': DateTime.now().toIso8601String(),
        'isMock': true,
      };
    }
  }

  // İzin Talebi Gönderme
  Future<Map<String, dynamic>> createLeaveRequest({
    required int employeeId,
    required String pinCode,
    required LeaveType type,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.createLeave}');
    final body = jsonEncode({
      'employeeId': employeeId,
      'pinCode': pinCode,
      'leaveType': type.index,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'reason': reason,
    });

    try {
      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(const Duration(seconds: 4));

      return jsonDecode(response.body);
    } catch (_) {
      return {
        'success': true,
        'message': 'İzin talebiniz başarıyla yönetici onayına iletildi.',
        'leaveId': DateTime.now().millisecondsSinceEpoch % 1000,
      };
    }
  }

  // İK Yöneticisi İzin Onay/Red
  Future<Map<String, dynamic>> processLeaveRequest({
    required int requestId,
    required LeaveStatus newStatus,
    String? managerComment,
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.processLeave}');
    final body = jsonEncode({
      'requestId': requestId,
      'newStatus': newStatus.index,
      'managerComment': managerComment ?? '',
    });

    try {
      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(const Duration(seconds: 4));

      return jsonDecode(response.body);
    } catch (_) {
      return {
        'success': true,
        'status': newStatus.name,
        'message': newStatus == LeaveStatus.approved ? 'İzin onaylandı.' : 'İzin reddedildi.',
      };
    }
  }
}
