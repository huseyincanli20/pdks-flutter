import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/pdks_state.dart';

class KioskTerminalScreen extends StatefulWidget {
  final String terminalId;
  const KioskTerminalScreen({super.key, this.terminalId = 'KIOSK-GATE-A1'});

  @override
  State<KioskTerminalScreen> createState() => _KioskTerminalScreenState();
}

class _KioskTerminalScreenState extends State<KioskTerminalScreen> with SingleTickerProviderStateMixin {
  late Timer _clockTimer;
  DateTime _currentTime = DateTime.now();

  // Animasyon kontrolcüsü (Tarayıcı lazer çizgisi)
  late AnimationController _scannerAnimCtrl;
  late Animation<double> _scannerAnim;

  // Tarama durumları
  bool _isProcessingScan = false;
  bool _antiSpoofingBlinkPassed = true;
  String? _lastScannedPerson;
  String? _scanStatusMessage;
  bool _isGateOpen = false;
  String? _lastGateCommand;
  Timer? _gateAutoCloseTimer;

  final TextEditingController _manualInputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });

    _scannerAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scannerAnim = Tween<double>(begin: 0.1, end: 0.9).animate(
      CurvedAnimation(parent: _scannerAnimCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _gateAutoCloseTimer?.cancel();
    _scannerAnimCtrl.dispose();
    _manualInputController.dispose();
    super.dispose();
  }

  Future<void> _executeFaceScan({required String candidateName, required bool withLiveness}) async {
    if (_isProcessingScan) return;

    setState(() {
      _isProcessingScan = true;
      _scanStatusMessage = 'Biyometrik yüz taranıyor ve canlılık doğrulanıyor...';
    });

    final pdks = context.read<PdksState>();
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    final result = await pdks.processKioskFaceScan(
      terminalId: widget.terminalId,
      rawFaceVectorOrName: candidateName,
      isBlinkDetected: withLiveness,
    );

    if (!mounted) return;

    if (result.success) {
      setState(() {
        _isProcessingScan = false;
        _antiSpoofingBlinkPassed = true;
        _lastScannedPerson = result.employeeName;
        _isGateOpen = true;
        _scanStatusMessage = result.message;
        _lastGateCommand = '[TCP/IP 192.168.1.201:8080] >> GATE_OPEN_PULSE_3000MS -> ACK_OK';
      });

      _gateAutoCloseTimer?.cancel();
      _gateAutoCloseTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) {
          setState(() {
            _isGateOpen = false;
            _lastScannedPerson = null;
            _scanStatusMessage = null;
          });
        }
      });
    } else {
      setState(() {
        _isProcessingScan = false;
        _antiSpoofingBlinkPassed = withLiveness;
        _lastScannedPerson = null;
        _scanStatusMessage = result.message;
        _lastGateCommand = '[TCP/IP 192.168.1.201:8080] >> GATE_REJECT_SECURITY_LOCK';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pdks = context.watch<PdksState>();
    final comp = pdks.activeCompany;
    final timeStr = '${_currentTime.hour.toString().padLeft(2, '0')}:${_currentTime.minute.toString().padLeft(2, '0')}:${_currentTime.second.toString().padLeft(2, '0')}';
    final dateStr = '${_currentTime.day}.${_currentTime.month}.${_currentTime.year}';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Slate 900
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 2,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(comp.code, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(comp.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text('Terminal: ${widget.terminalId} • Turnike TCP/IP: 192.168.1.201:8080',
                      style: const TextStyle(fontSize: 11, color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Çevrimiçi Durumu
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.greenAccent),
            ),
            child: const Row(
              children: [
                Icon(Icons.wifi_rounded, color: Colors.greenAccent, size: 16),
                SizedBox(width: 6),
                Text('TURNİKE BAĞLI', style: TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Kiosk Modundan Çık',
            icon: const Icon(Icons.close_rounded, color: Colors.white70),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 800;
          return isWide ? _buildWideLayout(context, pdks, timeStr, dateStr) : _buildNarrowLayout(context, pdks, timeStr, dateStr);
        },
      ),
    );
  }

  Widget _buildWideLayout(BuildContext context, PdksState pdks, String timeStr, String dateStr) {
    return Row(
      children: [
        // Sol Panel: Kamera Vizörü ve Tarama Durumu
        Expanded(
          flex: 6,
          child: _buildCameraViewfinder(context, timeStr, dateStr),
        ),
        // Sağ Panel: Hızlı Personel Seçimi, Telemetri ve Turnike Durumu
        Expanded(
          flex: 4,
          child: Container(
            color: const Color(0xFF1E293B),
            child: _buildControlSidebar(context, pdks),
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout(BuildContext context, PdksState pdks, String timeStr, String dateStr) {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(
            height: 480,
            child: _buildCameraViewfinder(context, timeStr, dateStr),
          ),
          Container(
            color: const Color(0xFF1E293B),
            padding: const EdgeInsets.all(16),
            child: _buildControlSidebar(context, pdks),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraViewfinder(BuildContext context, String timeStr, String dateStr) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Dijital Saat & Bilgi Bandı
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(timeStr, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.cyanAccent, fontFamily: 'monospace')),
                    Text(dateStr, style: const TextStyle(fontSize: 12, color: Colors.white60)),
                  ],
                ),
                // Turnike Durumu Rozeti
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _isGateOpen ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _isGateOpen ? Colors.greenAccent : Colors.redAccent),
                  ),
                  child: Row(
                    children: [
                      Icon(_isGateOpen ? Icons.lock_open_rounded : Icons.lock_rounded,
                          color: _isGateOpen ? Colors.greenAccent : Colors.redAccent, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _isGateOpen ? 'TURNİKE AÇIK (GEÇİŞ SERBEST)' : 'TURNİKE KİLİTLİ',
                        style: TextStyle(
                          color: _isGateOpen ? Colors.greenAccent : Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Kamera Simülasyonu & Lazer Tarama Alanı
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Kamera Fonu (Karanlık gradient ve ızgara)
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF111827),
                          const Color(0xFF1F2937),
                          _isGateOpen ? const Color(0xFF064E3B) : const Color(0xFF111827),
                        ],
                      ),
                      border: Border.all(
                        color: _isGateOpen ? Colors.greenAccent : (_antiSpoofingBlinkPassed ? Colors.cyanAccent.withOpacity(0.5) : Colors.redAccent),
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),

                  // Yüz Algılama Çerçevesi (Oval)
                  Center(
                    child: Container(
                      width: 240,
                      height: 310,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _isGateOpen
                              ? Colors.greenAccent
                              : (_antiSpoofingBlinkPassed ? Colors.cyanAccent : Colors.redAccent),
                          width: 2.5,
                        ),
                        borderRadius: BorderRadius.circular(120),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isGateOpen ? Icons.face_retouching_natural_rounded : Icons.face_rounded,
                            size: 80,
                            color: _isGateOpen
                                ? Colors.greenAccent
                                : (_antiSpoofingBlinkPassed ? Colors.white54 : Colors.redAccent),
                          ),
                          const SizedBox(height: 12),
                          if (_isGateOpen && _lastScannedPerson != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.greenAccent),
                              ),
                              child: Text(
                                _lastScannedPerson!,
                                style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            )
                          else
                            const Text(
                              'Yüzünüzü Çerçeveye\nHizalayınız',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.3),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Lazer Tarama Çizgisi
                  AnimatedBuilder(
                    animation: _scannerAnim,
                    builder: (context, child) {
                      return Positioned(
                        top: 40 + (_scannerAnim.value * 300),
                        left: 40,
                        right: 40,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: _isGateOpen ? Colors.greenAccent : Colors.cyanAccent,
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                            color: _isGateOpen ? Colors.greenAccent : Colors.cyanAccent,
                          ),
                        ),
                      );
                    },
                  ),

                  // Canlılık / Anti-Spoofing Rozeti
                  Positioned(
                    top: 14,
                    left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.cyanAccent.withOpacity(0.5)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _antiSpoofingBlinkPassed ? Icons.remove_red_eye_rounded : Icons.visibility_off_rounded,
                            color: _antiSpoofingBlinkPassed ? Colors.cyanAccent : Colors.redAccent,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _antiSpoofingBlinkPassed
                                ? 'Canlılık Doğrulandı (On-Device Liveness %98.7)'
                                : 'Canlılık Başarısız (Fotoğraf/Ekran Reddedildi)',
                            style: TextStyle(
                              color: _antiSpoofingBlinkPassed ? Colors.cyanAccent : Colors.redAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Alt Durum Mesajı
                  if (_scanStatusMessage != null)
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _isGateOpen ? Colors.green.shade900.withOpacity(0.9) : Colors.red.shade900.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _isGateOpen ? Colors.greenAccent : Colors.redAccent),
                        ),
                        child: Row(
                          children: [
                            Icon(_isGateOpen ? Icons.check_circle_rounded : Icons.error_rounded,
                                color: _isGateOpen ? Colors.greenAccent : Colors.redAccent),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _scanStatusMessage!,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Alt Telemetri & TCP/IP Röle Bildirimi
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                const Icon(Icons.terminal_rounded, color: Colors.white54, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _lastGateCommand ?? '[TCP/IP Turnike Emülatörü] Dinleniyor (PORT 8080)...',
                    style: const TextStyle(color: Colors.white60, fontSize: 11, fontFamily: 'monospace'),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlSidebar(BuildContext context, PdksState pdks) {
    final emps = pdks.employees;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Hızlı Biyometrik Test & Geçiş',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 6),
        const Text('Gerçek ortamda dahili RGB kamera ve kızılötesi derinlik sensörü otomatik tanır. Demo ortamında aşağıdaki personeller ile test edebilirsiniz:',
            style: TextStyle(fontSize: 12, color: Colors.white60)),
        const SizedBox(height: 16),

        // Manuel Personel Adı/Sicil Girişi
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _manualInputController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Personel Adı veya Sicil No...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
                onSubmitted: (val) {
                  if (val.trim().isNotEmpty) {
                    _executeFaceScan(candidateName: val.trim(), withLiveness: true);
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                if (_manualInputController.text.trim().isNotEmpty) {
                  _executeFaceScan(candidateName: _manualInputController.text.trim(), withLiveness: true);
                }
              },
              child: const Text('Doğrula'),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Kayıtlı Personel Kartları (Hızlı Dokun-Geç)
        const Text('Kayıtlı Yüz Profilleri (Tek Tıkla Geçiş):',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white70)),
        const SizedBox(height: 8),
        ...emps.take(4).map((emp) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white10),
            ),
            child: ListTile(
              dense: true,
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF374151),
                child: Text(emp.fullName.substring(0, 1), style: const TextStyle(color: Colors.white)),
              ),
              title: Text(emp.fullName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              subtitle: Text('${emp.department} • Sicil: ${emp.displaySicilNo}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
              trailing: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                icon: const Icon(Icons.fingerprint_rounded, size: 14),
                label: const Text('Yüz Oku', style: TextStyle(fontSize: 11)),
                onPressed: () => _executeFaceScan(candidateName: emp.fullName, withLiveness: true),
              ),
            ),
          );
        }),

        const Divider(color: Colors.white24, height: 32),

        // Anti-Spoofing Sahte Yüz / Fotoğraf Simülasyonu
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.orangeAccent.withOpacity(0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.security_update_warning_rounded, color: Colors.orangeAccent, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Güvenlik Testi: Sahte Geçiş (Spoofing)',
                      style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text('Ekrana başka birinin fotoğrafını tutarak geçmeye çalışan sahte hareket denemesi:',
                  style: TextStyle(color: Colors.white70, fontSize: 11)),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orangeAccent,
                    side: const BorderSide(color: Colors.orangeAccent),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.block_rounded, size: 16),
                  label: const Text('Fotoğraftan Geçiş Simüle Et (Liveness Başarısız)'),
                  onPressed: () => _executeFaceScan(candidateName: 'Ahmet Yılmaz', withLiveness: false),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Güvenlik Görevlisi Manuel Turnike Tetikleme
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white70,
            side: const BorderSide(color: Colors.white30),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          icon: const Icon(Icons.toll_rounded, size: 16),
          label: const Text('Turnike Rölesini Manuel Aç (3 sn)'),
          onPressed: () {
            setState(() {
              _isGateOpen = true;
              _lastGateCommand = '[GÜVENLİK BUTONU] >> TCP MAN_OVERRIDE_PULSE_3000MS -> ACK_OK';
              _scanStatusMessage = 'Güvenlik görevlisi turnike kilidini manuel açtı.';
            });
            _gateAutoCloseTimer?.cancel();
            _gateAutoCloseTimer = Timer(const Duration(seconds: 3), () {
              if (mounted) {
                setState(() {
                  _isGateOpen = false;
                  _scanStatusMessage = null;
                });
              }
            });
          },
        ),
      ],
    );
  }
}
