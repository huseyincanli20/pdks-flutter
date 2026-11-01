class IntegrationEndpoint {
  final String id;
  final String companyId;
  final String name; // 'Logo Tiger ERP', 'SAP HCM', 'ZKTeco Turnike', 'Mikro Yazılım'
  final String systemType; // 'erp', 'turnstile', 'biometric', 'payroll'
  final String status; // 'active', 'disconnected', 'error', 'syncing'
  final DateTime lastSyncTime;
  final int syncedRecordsCount;
  final int failedRecordsCount;
  final String apiEndpoint;

  IntegrationEndpoint({
    required this.id,
    required this.companyId,
    required this.name,
    required this.systemType,
    this.status = 'active',
    DateTime? lastSyncTime,
    this.syncedRecordsCount = 0,
    this.failedRecordsCount = 0,
    required this.apiEndpoint,
  }) : lastSyncTime = lastSyncTime ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'companyId': companyId,
        'name': name,
        'systemType': systemType,
        'status': status,
        'lastSyncTime': lastSyncTime.toIso8601String(),
        'syncedRecordsCount': syncedRecordsCount,
        'failedRecordsCount': failedRecordsCount,
        'apiEndpoint': apiEndpoint,
      };

  factory IntegrationEndpoint.fromJson(Map<String, dynamic> json) => IntegrationEndpoint(
        id: json['id'] ?? '',
        companyId: json['companyId'] ?? 'cmp_acme',
        name: json['name'] ?? '',
        systemType: json['systemType'] ?? 'erp',
        status: json['status'] ?? 'active',
        lastSyncTime: json['lastSyncTime'] != null ? DateTime.parse(json['lastSyncTime']) : DateTime.now(),
        syncedRecordsCount: json['syncedRecordsCount'] ?? 0,
        failedRecordsCount: json['failedRecordsCount'] ?? 0,
        apiEndpoint: json['apiEndpoint'] ?? 'https://api.erp.local/v1',
      );

  IntegrationEndpoint copyWith({String? status, DateTime? lastSyncTime, int? syncedRecordsCount, int? failedRecordsCount}) =>
      IntegrationEndpoint(
        id: id,
        companyId: companyId,
        name: name,
        systemType: systemType,
        status: status ?? this.status,
        lastSyncTime: lastSyncTime ?? this.lastSyncTime,
        syncedRecordsCount: syncedRecordsCount ?? this.syncedRecordsCount,
        failedRecordsCount: failedRecordsCount ?? this.failedRecordsCount,
        apiEndpoint: apiEndpoint,
      );
}

class OfflineSyncItem {
  final String id;
  final String companyId;
  final String actionType; // 'check_in', 'check_out', 'field_work', 'leave_request'
  final Map<String, dynamic> payload;
  final DateTime recordedAt;
  final String syncStatus; // 'queued', 'synced', 'conflict'

  OfflineSyncItem({
    required this.id,
    required this.companyId,
    required this.actionType,
    required this.payload,
    DateTime? recordedAt,
    this.syncStatus = 'queued',
  }) : recordedAt = recordedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'companyId': companyId,
        'actionType': actionType,
        'payload': payload,
        'recordedAt': recordedAt.toIso8601String(),
        'syncStatus': syncStatus,
      };

  factory OfflineSyncItem.fromJson(Map<String, dynamic> json) => OfflineSyncItem(
        id: json['id'] ?? '',
        companyId: json['companyId'] ?? 'cmp_acme',
        actionType: json['actionType'] ?? 'check_in',
        payload: json['payload'] != null ? Map<String, dynamic>.from(json['payload']) : {},
        recordedAt: json['recordedAt'] != null ? DateTime.parse(json['recordedAt']) : DateTime.now(),
        syncStatus: json['syncStatus'] ?? 'queued',
      );

  OfflineSyncItem copyWith({String? syncStatus}) => OfflineSyncItem(
        id: id,
        companyId: companyId,
        actionType: actionType,
        payload: payload,
        recordedAt: recordedAt,
        syncStatus: syncStatus ?? this.syncStatus,
      );
}
