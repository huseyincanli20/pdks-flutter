import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../state/pdks_state.dart';

/// Firebase Bulut Veritabanı Yapılandırma ve Eşitleme Diyaloğu
void showFirebaseConfigDialog(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => const _FirebaseConfigSheet(),
  );
}

class _FirebaseConfigSheet extends StatefulWidget {
  const _FirebaseConfigSheet();

  @override
  State<_FirebaseConfigSheet> createState() => _FirebaseConfigSheetState();
}

class _FirebaseConfigSheetState extends State<_FirebaseConfigSheet> {
  late TextEditingController _projectIdController;
  late TextEditingController _apiKeyController;
  bool _isEnabled = true;
  bool _isTesting = false;
  bool _isSyncing = false;
  String? _statusMessage;
  bool? _testSuccess;

  @override
  void initState() {
    super.initState();
    final pdks = context.read<PdksState>();
    _projectIdController = TextEditingController(text: pdks.firebaseProjectId);
    _apiKeyController = TextEditingController(text: pdks.firebase.apiKey);
    _isEnabled = pdks.isFirebaseEnabled;
  }

  @override
  void dispose() {
    _projectIdController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _handleTest() async {
    setState(() {
      _isTesting = true;
      _statusMessage = 'Firebase sunucuları kontrol ediliyor...';
    });

    final pdks = context.read<PdksState>();
    // Önce güncel bilgileri kaydet
    await pdks.updateFirebaseConfig(
      projectId: _projectIdController.text.trim(),
      apiKey: _apiKeyController.text.trim(),
      isEnabled: _isEnabled,
    );

    final ok = await pdks.testFirebaseConnection();

    if (!mounted) return;
    setState(() {
      _isTesting = false;
      _testSuccess = ok;
      _statusMessage = ok
          ? '✅ Firebase Realtime DB & Firestore bağlantısı BAŞARILI!'
          : '⚠️ Canlı bağlantı kurulamadı. URL veya internet bağlantınızı kontrol ediniz. (Yerel veritabanı aktif)';
    });
  }

  Future<void> _handleSyncAll() async {
    setState(() {
      _isSyncing = true;
      _statusMessage = 'Yerel veritabanı Firebase bulutuna aktarılıyor...';
    });

    final pdks = context.read<PdksState>();
    final result = await pdks.syncLocalDbToFirebase();

    if (!mounted) return;
    setState(() {
      _isSyncing = false;
      _testSuccess = result.success;
      _statusMessage = result.success
          ? '🚀 Başarılı! ${result.employees} personel, ${result.messages} mesaj ve ${result.records} devam kaydı Firebase bulutuna eşitlendi.'
          : '⚠️ Eşitleme sırasında bazı kayıtlar aktarılamadı. Lütfen bağlantınızı kontrol ediniz.';
    });
  }

  Future<void> _handleSave() async {
    final pdks = context.read<PdksState>();
    await pdks.updateFirebaseConfig(
      projectId: _projectIdController.text.trim(),
      apiKey: _apiKeyController.text.trim(),
      isEnabled: _isEnabled,
    );

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF10B981),
        content: Text('Firebase yapılandırması kaydedildi!'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pdks = context.watch<PdksState>();
    final isConnected = pdks.isFirebaseConnected;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Sürükleme Çubuğu
            const SizedBox(height: 12),
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 16),

            // Başlık & İkon & Bağlantı Rozeti
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFA000), Color(0xFFFF5722)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF5722).withOpacity(0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Firebase Bulut Veritabanı',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Google Firebase Realtime Database & Firestore',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Bağlantı Rozeti
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isConnected
                          ? const Color(0xFF10B981).withOpacity(0.15)
                          : const Color(0xFFF59E0B).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isConnected
                            ? const Color(0xFF10B981).withOpacity(0.4)
                            : const Color(0xFFF59E0B).withOpacity(0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isConnected ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isConnected ? 'Online' : 'Standby',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isConnected ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            Divider(height: 1, color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200),

            // Form ve İçerik
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                children: [
                  // Bilgilendirme Kutusu
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.cloud_sync_rounded, color: Color(0xFF2563EB), size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Çok Cihazlı Merkezi Veritabanı',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: isDark ? Colors.white : const Color(0xFF1E3A8A),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Kayıt olan personeller, İK onayları, anlık mesajlaşma ve mesai bildirimleri doğrudan Google Firebase bulutunda toplanır. Farklı telefonlardan veya web tarayıcılarından aynı veritabanına erişebilirsiniz.',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  height: 1.4,
                                  color: isDark ? AppColors.darkTextSecondary : const Color(0xFF3B82F6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Firebase Aktif/Pasif Switch
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.power_settings_new_rounded,
                              color: _isEnabled ? const Color(0xFF10B981) : Colors.grey,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Firebase Bulut Senkronizasyonu',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                                color: isDark ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        Switch(
                          value: _isEnabled,
                          activeColor: const Color(0xFFFF5722),
                          onChanged: (v) => setState(() => _isEnabled = v),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Proje ID Girişi
                  Text(
                    'Firebase Project ID (Proje Kimliği)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _projectIdController,
                    style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1E293B) : Colors.grey.shade50,
                      hintText: 'Örn: pdks-kurumsal-cloud',
                      prefixIcon: const Icon(Icons.tag_rounded, color: Color(0xFFFF9800), size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFFF5722), width: 1.5),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),
                  Text(
                    'Bağlantı Uç Noktası (Endpoint): https://${_projectIdController.text.trim().isEmpty ? 'project-id' : _projectIdController.text.trim()}-default-rtdb.firebaseio.com',
                    style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : AppColors.textMuted),
                  ),

                  const SizedBox(height: 16),

                  // API Key (İsteğe bağlı)
                  Text(
                    'Firebase Web API Key (Opsiyonel)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _apiKeyController,
                    style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1E293B) : Colors.grey.shade50,
                      hintText: 'AIzaSy...',
                      prefixIcon: const Icon(Icons.key_rounded, color: Color(0xFF3B82F6), size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Durum Mesajı Kutusu (Varsa)
                  if (_statusMessage != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (_testSuccess == true)
                            ? const Color(0xFF10B981).withOpacity(0.12)
                            : const Color(0xFFF59E0B).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: (_testSuccess == true)
                              ? const Color(0xFF10B981).withOpacity(0.3)
                              : const Color(0xFFF59E0B).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        _statusMessage!,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: (_testSuccess == true)
                              ? (isDark ? const Color(0xFF34D399) : const Color(0xFF065F46))
                              : (isDark ? const Color(0xFFFBBF24) : const Color(0xFF92400E)),
                        ),
                      ),
                    ),

                  // Aksiyon Düğmeleri
                  Row(
                    children: [
                      // Bağlantıyı Test Et
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: Color(0xFFFF5722)),
                            foregroundColor: const Color(0xFFFF5722),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: (_isTesting || _isSyncing) ? null : _handleTest,
                          icon: _isTesting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF5722)),
                                )
                              : const Icon(Icons.network_check_rounded, size: 18),
                          label: Text(_isTesting ? 'Test...' : 'Bağlantıyı Test Et'),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Yerel Verileri Buluta Aktar (Sync All)
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: const Color(0xFF0284C7),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          onPressed: (_isTesting || _isSyncing) ? null : _handleSyncAll,
                          icon: _isSyncing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.cloud_upload_rounded, size: 18),
                          label: Text(_isSyncing ? 'Aktarılıyor...' : 'Buluta Aktar'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Kaydet Butonu
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      backgroundColor: const Color(0xFFFF5722),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 1,
                    ),
                    onPressed: _handleSave,
                    child: const Text('Ayarları Kaydet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
