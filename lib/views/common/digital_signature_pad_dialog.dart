import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/digital_signature_and_export.dart';
import '../../state/pdks_state.dart';

class DigitalSignaturePadDialog extends StatefulWidget {
  final String documentType;
  final String documentTitle;
  final String period;

  const DigitalSignaturePadDialog({
    super.key,
    required this.documentType,
    required this.documentTitle,
    required this.period,
  });

  static Future<SignedDocumentRecord?> show({
    required BuildContext context,
    required String documentType,
    required String documentTitle,
    required String period,
  }) {
    return showDialog<SignedDocumentRecord>(
      context: context,
      barrierDismissible: false,
      builder: (context) => DigitalSignaturePadDialog(
        documentType: documentType,
        documentTitle: documentTitle,
        period: period,
      ),
    );
  }

  @override
  State<DigitalSignaturePadDialog> createState() => _DigitalSignaturePadDialogState();
}

class _DigitalSignaturePadDialogState extends State<DigitalSignaturePadDialog> {
  final List<Offset?> _points = [];
  bool _isAcknowledged = true;
  bool _isSaving = false;

  String _calculateLiveHash(String empId, String empName) {
    final raw = '${widget.documentType}_${widget.period}_${empId}_${empName}_${DateTime.now().minute}_POINTS_${_points.length}';
    return sha256.convert(utf8.encode(raw)).toString();
  }

  @override
  Widget build(BuildContext context) {
    final pdks = context.watch<PdksState>();
    final user = pdks.currentUser;
    final liveHash = _calculateLiveHash(user.id.toString(), user.fullName);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Başlık & Kapat
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.draw_rounded, color: Color(0xFF6366F1)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('5070 Sayılı Kanun Uyumlu E-İmza',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('Belge: ${widget.documentTitle}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey), overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(height: 24),

                // Belge & İmzacı Bilgi Kartı
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.withOpacity(0.15)),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow('İmzacı Personel:', '${user.fullName} (Sicil: ${user.displaySicilNo})'),
                      const SizedBox(height: 4),
                      _buildInfoRow('T.C. Kimlik No:', user.tcKimlikNo),
                      const SizedBox(height: 4),
                      _buildInfoRow('Dönem / Tür:', '${widget.period} • ${widget.documentType.toUpperCase()}'),
                      const SizedBox(height: 4),
                      _buildInfoRow('RFC 3161 Zaman Damgası:', '${liveHash.substring(0, 24)}...'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Çizim Alanı Başlığı ve Temizle Butonu
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Parmak veya Fare ile İmzanızı Atınız:',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    TextButton.icon(
                      style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                      icon: const Icon(Icons.refresh_rounded, size: 16, color: Colors.redAccent),
                      label: const Text('Temizle', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                      onPressed: () {
                        setState(() {
                          _points.clear();
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // İmza Tuvali (Canvas)
                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.5), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: Stack(
                      children: [
                        // İmza Kılavuz Çizgisi
                        Positioned(
                          bottom: 40,
                          left: 20,
                          right: 20,
                          child: Container(
                            height: 1,
                            color: Colors.grey.withOpacity(0.3),
                          ),
                        ),
                        const Positioned(
                          bottom: 20,
                          right: 20,
                          child: Text('❌ İmza Çizgisi', style: TextStyle(color: Colors.black26, fontSize: 11)),
                        ),
                        // Çizim Yüzeyi
                        GestureDetector(
                          onPanUpdate: (details) {
                            final localPos = details.localPosition;
                            setState(() {
                              _points.add(localPos);
                            });
                          },
                          onPanEnd: (details) => _points.add(null),
                          child: CustomPaint(
                            size: Size.infinite,
                            painter: _SignaturePainter(points: _points),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Yasal Hüküm Onayı
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _isAcknowledged,
                  activeColor: const Color(0xFF6366F1),
                  title: const Text(
                    '5070 Sayılı Elektronik İmza Kanunu md. 5 uyarınca bu elektronik onayın ıslak imzamla aynı hukuki geçerliliğe sahip olduğunu kabul ediyorum.',
                    style: TextStyle(fontSize: 11, height: 1.3),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (val) => setState(() => _isAcknowledged = val ?? true),
                ),
                const SizedBox(height: 12),

                // Butonlar
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('İptal'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: _isSaving
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.verified_rounded, size: 18),
                        label: Text(_isSaving ? 'İmzalanıyor...' : 'Belgeyi İmzala'),
                        onPressed: (_points.isEmpty || !_isAcknowledged || _isSaving)
                            ? null
                            : () async {
                                setState(() => _isSaving = true);
                                final pointsData = 'COUNT_${_points.length}_TIMESTAMP_${DateTime.now().millisecondsSinceEpoch}';
                                final nav = Navigator.of(context);
                                final signed = await pdks.signDocumentWith5070Timestamp(
                                  documentType: widget.documentType,
                                  documentTitle: widget.documentTitle,
                                  period: widget.period,
                                  signaturePoints: pointsData,
                                );
                                nav.pop(signed);
                              },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<Offset?> points;
  _SignaturePainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1E1B4B)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}
