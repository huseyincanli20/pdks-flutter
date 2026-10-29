import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../state/pdks_state.dart';

class FieldWorkDialog extends StatefulWidget {
  const FieldWorkDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => const FieldWorkDialog(),
    );
  }

  @override
  State<FieldWorkDialog> createState() => _FieldWorkDialogState();
}

class _FieldWorkDialogState extends State<FieldWorkDialog> {
  final _missionCtrl = TextEditingController(text: 'Müşteri Ziyareti & Saha Toplantısı');
  final _addressCtrl = TextEditingController(text: 'Büyükdere Cad. No: 124, Levent / İstanbul');
  final _noteCtrl = TextEditingController(text: 'Kurumsal entegrasyon toplantısı ve yerinde teknik inceleme.');

  double _latitude = 41.0772;
  double _longitude = 29.0118;
  bool _isLoadingGps = false;

  void _refreshGpsLocation() {
    setState(() => _isLoadingGps = true);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() {
        _latitude = 41.0082 + (DateTime.now().second % 50) * 0.001;
        _longitude = 28.9784 + (DateTime.now().second % 50) * 0.001;
        _isLoadingGps = false;
      });
    });
  }

  @override
  void dispose() {
    _missionCtrl.dispose();
    _addressCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pdks = context.watch<PdksState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isActive = pdks.isFieldWorkActive;

    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF10B981).withOpacity(0.15) : const Color(0xFF2563EB).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.location_on_rounded,
              color: isActive ? const Color(0xFF10B981) : const Color(0xFF2563EB),
              size: 24,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isActive ? 'Aktif Dışarıda Çalışma' : 'Dışarıda Çalışma (Saha Görevi)',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isActive) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Saha Çalışması Devam Ediyor',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF065F46)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Görev: ${pdks.activeFieldWorkTitle ?? "Saha Görevi"}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Konum: ${pdks.activeFieldWorkAddress ?? "Bildirilen Saha Noktası"}', style: const TextStyle(fontSize: 11)),
                      const SizedBox(height: 6),
                      const Text(
                        'Konumunuz İK sistemine kaydedilmiş olup vardiya puantajınıza dahil edilmektedir.',
                        style: TextStyle(fontSize: 10.5, color: Color(0xFF047857)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text('Dışarıda Çalışmayı Sonlandır', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () {
                      final res = pdks.endFieldWork(exitNote: 'Görev başarıyla tamamlandı.');
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(res.message),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ),
              ] else ...[
                Text(
                  'Ofis dışında, müşteri ziyaretinde veya sahada çalışırken anlık GPS konumunuzu ve görev amacınızı İK birimine bildirebilirsiniz.',
                  style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), height: 1.4),
                ),
                const SizedBox(height: 14),

                // GPS Bilgisi Kartı
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: _isLoadingGps
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.my_location_rounded, color: Color(0xFF10B981), size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Anlık GPS Koordinatları:', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                            Text(
                              '${_latitude.toStringAsFixed(4)}° K, ${_longitude.toStringAsFixed(4)}° D',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'monospace', color: Color(0xFF2563EB)),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded, size: 20),
                        tooltip: 'Konumu Güncelle',
                        onPressed: _refreshGpsLocation,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: _missionCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Saha Görevi / Çalışma Amacı *',
                    prefixIcon: Icon(Icons.business_center_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _addressCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Bulunulan Konum / Adres *',
                    prefixIcon: Icon(Icons.pin_drop_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _noteCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Görev Notu / İK Açıklaması',
                    prefixIcon: Icon(Icons.notes_rounded, size: 20),
                  ),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 3,
                    ),
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: const Text(
                      'Konumu İK\'ya İlet & Çalışmayı Başlat',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    onPressed: () {
                      final res = pdks.startFieldWork(
                        missionTitle: _missionCtrl.text,
                        missionNote: _noteCtrl.text,
                        latitude: _latitude,
                        longitude: _longitude,
                        addressName: _addressCtrl.text,
                      );
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(res.message),
                          backgroundColor: res.success ? AppColors.success : AppColors.danger,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Kapat'),
        ),
      ],
    );
  }
}
