import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../models/qr_token.dart';

class KioskScreen extends StatefulWidget {
  const KioskScreen({super.key});

  @override
  State<KioskScreen> createState() => _KioskScreenState();
}

class _KioskScreenState extends State<KioskScreen> {
  String _currentQrPayload = '';
  int _secondsRemaining = 10;
  Timer? _refreshTimer;
  Timer? _clockTimer;
  DateTime _currentTime = DateTime.now();
  final String _secretKey = 'PDKS_SUPER_SECRET_SALT_2026';

  @override
  void initState() {
    super.initState();
    _generateNewQr();
    _startTimers();
  }

  void _generateNewQr() {
    setState(() {
      _currentQrPayload = QrToken.generateSecurePayload(
        companyId: 1,
        locationId: 'TURNIKE_ANA_GIRIS',
        secretKey: _secretKey,
      );
      _secondsRemaining = 10;
    });
  }

  void _startTimers() {
    // Saat sayacı
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _currentTime = DateTime.now());
    });

    // QR Geri sayım sayacı
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 1) {
        setState(() => _secondsRemaining--);
      } else {
        _generateNewQr();
      }
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Row(
          children: [
            // Sol Taraf: Bilgi, Saat, Turnike Durumu
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Şirket Başlığı
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.corporate_fare, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 16),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ACME CORP A.Ş.',
                              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                            ),
                            Text(
                              'Ana Merkez Plaza • Turnike Giriş 1',
                              style: TextStyle(color: Colors.white60, fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Büyük Dijital Saat
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('HH:mm:ss').format(_currentTime),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 72,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4,
                          ),
                        ),
                        Text(
                          DateFormat('EEEE, dd MMMM yyyy', 'tr_TR').format(_currentTime),
                          style: const TextStyle(color: Colors.white70, fontSize: 22, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.shield_outlined, color: AppColors.success, size: 20),
                              SizedBox(width: 10),
                              Text(
                                'Dinamik Anti-Cheat Koruma Aktif (10s Token)',
                                style: TextStyle(color: Colors.white, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Kiosk Alt Bilgi
                    const Text(
                      'Lütfen mobil uygulamanızı açıp kamerayı sağdaki QR koda tutun.\nEkran görüntüsü ile başkası adına giriş yapılamaz.',
                      style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              ),
            ),

            // Sağ Taraf: Dinamik QR Kod Kartı
            Expanded(
              flex: 4,
              child: Center(
                child: Container(
                  width: 380,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.2),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'PDKS Turnike Giriş',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Mobil uygulamadan taratın',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 24),

                      // Dinamik QR Kod
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border, width: 2),
                        ),
                        child: QrImageView(
                          data: _currentQrPayload,
                          version: QrVersions.auto,
                          size: 240.0,
                          backgroundColor: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Geri Sayım Barı
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: _secondsRemaining / 10.0,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _secondsRemaining > 3 ? AppColors.primary : AppColors.danger,
                          ),
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Kod yenileniyor...', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          Text(
                            '$_secondsRemaining sn',
                            style: TextStyle(
                              color: _secondsRemaining > 3 ? AppColors.primary : AppColors.danger,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
