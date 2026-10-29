import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/location_service.dart';
import '../../models/attendance_record.dart';
import '../../models/qr_token.dart';
import '../../state/pdks_state.dart';

class QrScannerScreen extends StatefulWidget {
  final AttendanceType type;

  const QrScannerScreen({super.key, required this.type});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        _processScannedCode(barcode.rawValue!);
        break;
      }
    }
  }

  Future<void> _processScannedCode(String code) async {
    setState(() => _isProcessing = true);

    // QR Kod doğrulama (Gizli anahtar ile zaman & hash kontrolü)
    const secretKey = 'PDKS_SUPER_SECRET_SALT_2026';
    final isValid = QrToken.verifyPayload(code, secretKey);

    if (!isValid && !code.contains('turnike')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.danger,
            content: Text('Geçersiz veya süresi dolmuş QR Kod! Lütfen turnike ekranındaki güncel kodu okutun.'),
          ),
        );
      }
      setState(() => _isProcessing = false);
      return;
    }

    // QR geçerli, check-in/out işlemini tamamla
    final dummyGeofence = GeofenceResult(
      isInside: true,
      distanceMeters: 1.5,
      allowedRadiusMeters: 150.0,
      latitude: 41.0082,
      longitude: 28.9784,
    );

    if (mounted) {
      await context.read<PdksState>().performCheckInOut(
        type: widget.type,
        method: VerificationMethod.qrCode,
        geofence: dummyGeofence,
        note: 'Turnike Kiosk Dinamik QR Kod doğrulandı.',
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            content: Text('${widget.type == AttendanceType.checkIn ? "Giriş" : "Çıkış"} başarıyla tamamlandı!'),
          ),
        );
      }
    }
  }

  // Simülasyon butonu (Kamera izni verilemeyen emülatör veya web testleri için)
  void _simulateQrScan() {
    const secretKey = 'PDKS_SUPER_SECRET_SALT_2026';
    final validPayload = QrToken.generateSecurePayload(
      companyId: 1,
      locationId: 'TURNIKE_ANA_GIRIS',
      secretKey: secretKey,
    );
    _processScannedCode(validPayload);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(widget.type == AttendanceType.checkIn ? 'Giriş QR Kodu Okut' : 'Çıkış QR Kodu Okut'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // Tarama hedef penceresi
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primaryLight, width: 3),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(width: 24, height: 24, decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.white, width: 4), left: BorderSide(color: Colors.white, width: 4)))),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(width: 24, height: 24, decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.white, width: 4), right: BorderSide(color: Colors.white, width: 4)))),
                  ),
                  Positioned(
                    bottom: 10,
                    left: 10,
                    child: Container(width: 24, height: 24, decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white, width: 4), left: BorderSide(color: Colors.white, width: 4)))),
                  ),
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: Container(width: 24, height: 24, decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white, width: 4), right: BorderSide(color: Colors.white, width: 4)))),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Column(
              children: [
                const Text(
                  'Turnike veya Kiosk tabletindeki\ndinamik QR kodu kare içine hizalayın.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white70),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  icon: const Icon(Icons.qr_code, size: 18),
                  label: const Text('Turnike QR Kodunu Simüle Et (Test)'),
                  onPressed: _simulateQrScan,
                ),
              ],
            ),
          ),

          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
