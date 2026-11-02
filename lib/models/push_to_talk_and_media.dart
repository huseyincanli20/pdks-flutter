/// Saha Telsizi (Push-to-Talk / PTT) Kanalı
class PttChannel {
  final String id;
  final String companyId;
  final String channelName; // 'Kanal 1: Saha Güvenlik', 'Kanal 2: Bakım & Arıza', 'Kanal 3: Üretim Şefleri'
  final String description;
  final int activeParticipantsCount;
  bool isOccupied; // Birisi mandala basıp konuşuyor mu?
  String? currentSpeakerName;
  DateTime? transmissionStartedAt;

  PttChannel({
    required this.id,
    required this.companyId,
    required this.channelName,
    required this.description,
    this.activeParticipantsCount = 8,
    this.isOccupied = false,
    this.currentSpeakerName,
    this.transmissionStartedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'companyId': companyId,
        'channelName': channelName,
        'description': description,
        'activeParticipantsCount': activeParticipantsCount,
        'isOccupied': isOccupied,
        'currentSpeakerName': currentSpeakerName,
        'transmissionStartedAt': transmissionStartedAt?.toIso8601String(),
      };

  factory PttChannel.fromJson(Map<String, dynamic> json) => PttChannel(
        id: json['id'] ?? '',
        companyId: json['companyId'] ?? '',
        channelName: json['channelName'] ?? '',
        description: json['description'] ?? '',
        activeParticipantsCount: json['activeParticipantsCount'] ?? 5,
        isOccupied: json['isOccupied'] ?? false,
        currentSpeakerName: json['currentSpeakerName'],
        transmissionStartedAt: json['transmissionStartedAt'] != null ? DateTime.tryParse(json['transmissionStartedAt']) : null,
      );
}

/// Telsiz Ses İletimi Kaydı (Audio Burst & Transkript)
class PttVoiceBurst {
  final String burstId;
  final String channelId;
  final int speakerId;
  final String speakerName;
  final String speakerRole;
  final DateTime timestamp;
  final int durationSeconds;
  final String transcriptText;
  final List<double> waveformPoints;

  PttVoiceBurst({
    required this.burstId,
    required this.channelId,
    required this.speakerId,
    required this.speakerName,
    required this.speakerRole,
    required this.timestamp,
    required this.durationSeconds,
    required this.transcriptText,
    this.waveformPoints = const [0.2, 0.5, 0.9, 0.7, 0.4, 0.8, 1.0, 0.6, 0.3],
  });

  Map<String, dynamic> toJson() => {
        'burstId': burstId,
        'channelId': channelId,
        'speakerId': speakerId,
        'speakerName': speakerName,
        'speakerRole': speakerRole,
        'timestamp': timestamp.toIso8601String(),
        'durationSeconds': durationSeconds,
        'transcriptText': transcriptText,
        'waveformPoints': waveformPoints,
      };

  factory PttVoiceBurst.fromJson(Map<String, dynamic> json) => PttVoiceBurst(
        burstId: json['burstId'] ?? '',
        channelId: json['channelId'] ?? '',
        speakerId: json['speakerId'] ?? 0,
        speakerName: json['speakerName'] ?? '',
        speakerRole: json['speakerRole'] ?? 'Teknisyen',
        timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
        durationSeconds: json['durationSeconds'] ?? 3,
        transcriptText: json['transcriptText'] ?? '',
        waveformPoints: json['waveformPoints'] != null
            ? List<double>.from((json['waveformPoints'] as List).map((x) => (x as num).toDouble()))
            : const [0.2, 0.5, 0.9, 0.7, 0.4, 0.8, 1.0, 0.6, 0.3],
      );
}
