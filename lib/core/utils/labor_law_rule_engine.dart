/// 4857 Sayl  Kanunu Mevzuat ve Kural Motoru
/// Teknik artname Madde 2.4, 2.5 ve 2.10 gereksinimleri
class LaborLawRuleEngine {
  /// 4857 Madde 68: alma sresine bal kademeli ara dinlenme kesintisi
  /// - 4 saate kadar (4 saat dahil): 15 dakika
  /// - 4 saatten fazla, 7.5 saate kadar (7.5 saat dahil): 30 dakika
  /// - 7.5 saatten fazla: 60 dakika (1 saat)
  static Duration calculateMandatoryBreak(Duration totalGrossDuration) {
    final double hours = totalGrossDuration.inMinutes / 60.0;
    if (hours <= 0) return Duration.zero;
    if (hours <= 4.0) {
      return const Duration(minutes: 15);
    } else if (hours <= 7.5) {
      return const Duration(minutes: 30);
    } else {
      return const Duration(minutes: 60);
    }
  }

  /// Net alma sresini hesaplar (Brt - Yasal mola kesintisi)
  static Duration calculateNetWorkDuration(Duration totalGrossDuration) {
    final mola = calculateMandatoryBreak(totalGrossDuration);
    final net = totalGrossDuration - mola;
    return net.isNegative ? Duration.zero : net;
  }

  /// 4857 Madde 69: Gece alma sresini (20:00 - 06:00) ayrtrr
  static Duration calculateNightShiftHours(DateTime entry, DateTime exit) {
    if (exit.isBefore(entry)) return Duration.zero;

    Duration nightDuration = Duration.zero;
    DateTime cursor = entry;

    while (cursor.isBefore(exit)) {
      final hour = cursor.hour;
      // 20:00'den gece 24:00'e kadar (20, 21, 22, 23) veya 00:00'dan 06:00'ya kadar (0, 1, 2, 3, 4, 5)
      if (hour >= 20 || hour < 6) {
        nightDuration += const Duration(minutes: 1);
      }
      cursor = cursor.add(const Duration(minutes: 1));
    }

    return nightDuration;
  }

  /// Gece almas yasal 7.5 saat snr kontrol
  static ({bool isExceeded, double nightHours, String warningMessage}) checkNightWorkLimit(
    DateTime entry,
    DateTime exit,
  ) {
    final night = calculateNightShiftHours(entry, exit);
    final hours = night.inMinutes / 60.0;
    final isExceeded = hours > 7.5;
    return (
      isExceeded: isExceeded,
      nightHours: hours,
      warningMessage: isExceeded
          ? '4857 Sayl  Kanunu Uyar: Gece postas alma sresi 7.5 saati aamaz! (Yaplan: ${hours.toStringAsFixed(1)} saat)'
          : 'Gece alma sresi yasal snrlar iindedir (${hours.toStringAsFixed(1)} saat).',
    );
  }

  /// 4857 Madde 63: Gnlk azami 11 saat alma snr kontrol
  static ({bool isExceeded, double netHours, String warningMessage}) checkDailyLimit(
    Duration netWorkDuration,
  ) {
    final hours = netWorkDuration.inMinutes / 60.0;
    final isExceeded = hours > 11.0;
    return (
      isExceeded: isExceeded,
      netHours: hours,
      warningMessage: isExceeded
          ? '4857 Sayl  Kanunu Uyar: Gnlk alma sresi hibir ekilde 11 saati aamaz! (Yaplan: ${hours.toStringAsFixed(1)} saat)'
          : 'Gnlk alma yasal 11 saatlik azami snr gememektedir.',
    );
  }

  /// 4857 Madde 41: Yllk 270 saat fazla mesai snr kontrol
  static ({bool isExceeded, bool isApproaching, double currentHours, String warningMessage}) checkAnnualOvertimeLimit(
    double totalOvertimeHoursThisYear,
  ) {
    final isExceeded = totalOvertimeHoursThisYear > 270.0;
    final isApproaching = totalOvertimeHoursThisYear >= 240.0 && !isExceeded;
    String msg;
    if (isExceeded) {
      msg = 'YASAL SINIR AILDI! Yllk 270 saatlik azami fazla mesai snr ald (${totalOvertimeHoursThisYear.toStringAsFixed(1)} / 270 saat).';
    } else if (isApproaching) {
      msg = 'KRTTK UYARI: Yllk 270 saatlik fazla mesai snrna yaklalyor (${totalOvertimeHoursThisYear.toStringAsFixed(1)} / 270 saat).';
    } else {
      msg = 'Yllk fazla mesai kotas uygun (${totalOvertimeHoursThisYear.toStringAsFixed(1)} / 270 saat).';
    }
    return (
      isExceeded: isExceeded,
      isApproaching: isApproaching,
      currentHours: totalOvertimeHoursThisYear,
      warningMessage: msg,
    );
  }

  /// 4857 Madde 41: cret yerine zaml serbest zaman (izin) karl
  /// Fazla mesaide 1 saate karlk 1 saat 30 dakika (1.5x) serbest zaman
  static Duration calculateCompensatoryFreeTime(Duration overtime) {
    final extraMinutes = (overtime.inMinutes * 1.5).round();
    return Duration(minutes: extraMinutes);
  }

  /// 4857 Madde 53: Kdem ve ya kriterine gre yllk cretli izin hak edii
  /// - 1 yldan 5 yla kadar (5 yl dahil): 14 gn
  /// - 5 yldan fazla 15 yla kadar: 20 gn
  /// - 15 yl (dahil) ve daha fazla: 26 gn
  /// - KRTTK KURAL: 18 ve daha kk ya da 50 ve daha yukar yata olanlara verilecek yllk izin 20 gnden az olamaz!
  static int calculateAnnualLeaveAllowance({
    required int yearsOfService,
    required int age,
  }) {
    if (yearsOfService < 1) return 0;

    int days;
    if (yearsOfService <= 5) {
      days = 14;
    } else if (yearsOfService < 15) {
      days = 20;
    } else {
      days = 26;
    }

    // 18 ya alt veya 50 ya st iin yasal asgari taban 20 gndr
    if ((age <= 18 || age >= 50) && days < 20) {
      days = 20;
    }

    return days;
  }

  /// 4857 Dinlenme Hakk: Mesai d ve izin gnlerinde sessiz mod kural
  /// Eer alan o an vardiyada deilse veya izinliyse, standart bildirimler
  /// anlk drlmez, sonraki vardiya balangcna ertelenir.
  /// Yalnzca "Acil Durum / SG / Kritik Arza" mesajlar muaftr.
  static bool shouldSuppressNotificationForRestHours({
    required bool isCurrentlyCheckedIn,
    required bool isCurrentlyOnLeave,
    required bool isEmergencyOrIsg,
  }) {
    // Acil durum veya SG iaretliyse hibir ekilde bastrlmaz!
    if (isEmergencyOrIsg) return false;

    // zinliyse veya tesiste/vardiyada deilse mesai d kalkan devreye girer
    if (isCurrentlyOnLeave || !isCurrentlyCheckedIn) {
      return true; // Sessiz moda al, vardiya bana ertele
    }

    return false;
  }

  /// Maskeleme Yardmcs: KVKK Madde 4 & 12 uyarnca hassas veri maskeleme
  /// rnek TC: '12345678901' -> '123*****01'
  static String maskTcKimlik(String tc) {
    final clean = tc.trim();
    if (clean.length < 5) return '***';
    return '${clean.substring(0, 3)}*****${clean.substring(clean.length - 2)}';
  }

  /// cret Maskeleme: Birim yneticilerine hassas cretleri gizleme
  static String maskSalary(double salary) {
    return '******  TL';
  }
}
