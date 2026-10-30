import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../state/pdks_state.dart';
import '../../models/company.dart';
import '../../models/employee.dart';
import '../common/email_preview_dialog.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Login Controllers
  final _loginEmailController = TextEditingController();
  final _loginPinController = TextEditingController();
  bool _loginObscure = true;

  // Register Controllers
  final _regCompanyCodeController = TextEditingController();
  final _regNameController = TextEditingController();
  final _regEmailController = TextEditingController();
  final _regPhoneController = TextEditingController();
  final _regPinController = TextEditingController();
  bool _regObscure = true;

  // Satın Alma (Purchase & Licensing) Controllers & State
  String _selectedPlan = 'pro'; // 'starter', 'pro', 'enterprise'
  bool _isYearlyBilling = true;
  String _selectedPaymentMethod = 'credit_card'; // 'credit_card', 'bank_transfer'
  bool _isProcessingPayment = false;

  final _buyCompanyNameController = TextEditingController();
  final _buyCompanyCodeController = TextEditingController();
  final _buySectorController = TextEditingController(text: 'Yazılım & Bilişim Ar-Ge');
  final _buyAdminNameController = TextEditingController();
  final _buyAdminEmailController = TextEditingController();
  final _buyAdminPhoneController = TextEditingController();
  final _buyAdminPinController = TextEditingController(text: '1234');
  final _buyCardNameController = TextEditingController();
  final _buyCardNumberController = TextEditingController();
  final _buyCardExpiryController = TextEditingController();
  final _buyCardCvvController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPinController.dispose();
    _regCompanyCodeController.dispose();
    _regNameController.dispose();
    _regEmailController.dispose();
    _regPhoneController.dispose();
    _regPinController.dispose();
    _buyCompanyNameController.dispose();
    _buyCompanyCodeController.dispose();
    _buySectorController.dispose();
    _buyAdminNameController.dispose();
    _buyAdminEmailController.dispose();
    _buyAdminPhoneController.dispose();
    _buyAdminPinController.dispose();
    _buyCardNameController.dispose();
    _buyCardNumberController.dispose();
    _buyCardExpiryController.dispose();
    _buyCardCvvController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _loginEmailController.text.trim();
    final pin = _loginPinController.text.trim();

    if (email.isEmpty || pin.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: AppColors.danger, content: Text('Lütfen e-posta ve PIN giriniz.')),
      );
      return;
    }

    final pdks = context.read<PdksState>();
    final result = pdks.login(email, pin);
    if (!result.success) {
      if (result.isPendingApproval) {
        _showPendingApprovalDialog(context, result.message);
        return;
      }

      // Yerel veritabanında yoksa Firebase Bulut Veritabanından kontrol et
      final cloudResult = await pdks.loginFromCloudAsync(email, pin);
      if (!cloudResult.success) {
        if (cloudResult.isPendingApproval) {
          if (!mounted) return;
          _showPendingApprovalDialog(context, cloudResult.message);
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(backgroundColor: AppColors.danger, content: Text(result.message)),
          );
        }
      }
    }
  }

  void _showPendingApprovalDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Row(
          children: [
            Icon(Icons.hourglass_top_rounded, color: Color(0xFFF59E0B), size: 26),
            SizedBox(width: 10),
            Text('İK Onayı Bekleniyor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message, style: const TextStyle(fontSize: 13.5, height: 1.4)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.35)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'İnsan Kaynakları departmanı başvurunuzu inceleyip onayladığında ve departman/unvan atamanızı yaptığında PIN kodunuz ile sisteme giriş yapabileceksiniz.',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF92400E)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Anladım', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRegister() async {
    final companyCode = _regCompanyCodeController.text.trim().toUpperCase();
    final name = _regNameController.text.trim();
    final email = _regEmailController.text.trim();
    final phone = _regPhoneController.text.trim();
    final pin = _regPinController.text.trim();

    if (companyCode.isEmpty || name.isEmpty || email.isEmpty || pin.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.danger,
          content: Text('Lütfen Şirket Kodu, Ad Soyad, E-posta ve PIN alanlarını doldurun.'),
        ),
      );
      return;
    }

    if (phone.isNotEmpty && phone.length > 11) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.danger,
          content: Text('Telefon numarası 11 haneyi geçemez (Örn: 05XXXXXXXXX).'),
        ),
      );
      return;
    }

    final pdks = context.read<PdksState>();

    // Firebase Bulut Mükerrer Kontrolü
    final cloudExists = await pdks.checkCloudDuplicate(email, phone);
    if (cloudExists) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.danger,
          content: Text('Kayıt Kabul Edilmedi: "$email" e-posta adresi veya telefon numarası veritabanında zaten kayıtlıdır! Lütfen giriş yapınız.'),
        ),
      );
      return;
    }

    final result = pdks.register(
      companyCode: companyCode,
      fullName: name,
      email: email,
      phone: phone,
      pin: pin,
    );

    if (!mounted) return;
    if (result.success) {
      _showRegistrationSuccessDialog(context, name, email);
      _loginEmailController.text = email;
      _loginPinController.text = pin;
      _tabController.animateTo(0);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppColors.danger, content: Text(result.message)),
      );
    }
  }

  void _showRegistrationSuccessDialog(BuildContext context, String name, String email) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981), size: 28),
            SizedBox(width: 10),
            Text('Kayıt Alındı!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tebrikler $name, personel kayıt başvurunuz başarıyla oluşturuldu.',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.25)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_outlined, color: Color(0xFF2563EB), size: 22),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Kurumsal işleyiş gereği kaydınız ilk önce İnsan Kaynakları (İK) onayına iletilmiştir.\n\nİK departmanı departman ve unvanınızı belirleyip onay verdiğinde PIN kodunuz ile giriş yapabileceksiniz.',
                      style: TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF1E3A8A)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Giriş Ekranına Git', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pdks = context.watch<PdksState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1D),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3B82F6).withOpacity(0.35),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.fingerprint, color: Colors.white, size: 44),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'PDKS Enterprise SaaS',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Çoklu Şirket & Personel Devam Takip Sistemi',
                    style: TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                  const SizedBox(height: 24),

                  // Form Kartı (Glass & Card style)
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Tab Başlıkları
                        Container(
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: TabBar(
                            controller: _tabController,
                            indicatorSize: TabBarIndicatorSize.tab,
                            indicator: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            labelColor: Colors.white,
                            unselectedLabelColor: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            tabs: const [
                              Tab(text: 'Giriş Yap'),
                              Tab(text: 'Kayıt Ol'),
                              Tab(text: 'Satın Al 💎'),
                            ],
                          ),
                        ),

                        // Tab İçerikleri
                        Padding(
                          padding: const EdgeInsets.all(18),
                          child: SizedBox(
                            height: 600,
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                _buildLoginTab(pdks),
                                _buildRegisterTab(),
                                _buildPurchaseTab(pdks),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginTab(PdksState pdks) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Onay Bildirimi Geldi Banner'ı (Kayıtlı Telefona Push & SMS İletildiğinde)
          if (pdks.lastDispatchedPhoneNotification != null) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF10B981).withOpacity(0.15), const Color(0xFF059669).withOpacity(0.08)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '📱 SMS & 📧 E-Posta İletildi (${pdks.lastDispatchedPhoneNotification!.targetEmail ?? pdks.lastDispatchedPhoneNotification!.targetPhone})',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFF34D399) : const Color(0xFF065F46)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'İK başvurunuzu onayladı! Onay e-postası ve şifreniz ile hemen giriş yapabilirsiniz.',
                          style: TextStyle(fontSize: 10.5, color: isDark ? const Color(0xFFA7F3D0) : const Color(0xFF047857)),
                        ),
                      ],
                    ),
                  ),
                  if (pdks.lastDispatchedPhoneNotification!.isEmailSent)
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: isDark ? const Color(0xFF34D399) : const Color(0xFF065F46),
                      ),
                      onPressed: () {
                        EmailPreviewDialog.show(
                          context,
                          notification: pdks.lastDispatchedPhoneNotification!,
                          companyName: pdks.activeCompany.name,
                        );
                      },
                      child: const Text('Maili Aç ›', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ),
          ],
        Text('E-Posta Adresi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFFCBD5E1) : AppColors.textSecondary)),
        const SizedBox(height: 5),
        TextField(
          controller: _loginEmailController,
          keyboardType: TextInputType.emailAddress,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'E-posta adresiniz',
            hintStyle: TextStyle(fontSize: 13, color: isDark ? const Color(0xFF64748B) : AppColors.textMuted),
            prefixIcon: Icon(Icons.email_outlined, size: 20, color: isDark ? const Color(0xFF60A5FA) : AppColors.primary),
            filled: true,
            fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : AppColors.border)),
          ),
        ),
        const SizedBox(height: 12),
        Text('PIN Kodu', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFFCBD5E1) : AppColors.textSecondary)),
        const SizedBox(height: 5),
        TextField(
          controller: _loginPinController,
          obscureText: _loginObscure,
          keyboardType: TextInputType.number,
          maxLength: 6,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'PIN Kodunuz',
            hintStyle: TextStyle(fontSize: 13, color: isDark ? const Color(0xFF64748B) : AppColors.textMuted),
            counterText: '',
            prefixIcon: Icon(Icons.lock_outline, size: 20, color: isDark ? const Color(0xFF60A5FA) : AppColors.primary),
            filled: true,
            fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : AppColors.border)),
            suffixIcon: IconButton(
              icon: Icon(_loginObscure ? Icons.visibility_off : Icons.visibility, size: 18, color: isDark ? const Color(0xFF94A3B8) : Colors.grey),
              onPressed: () => setState(() => _loginObscure = !_loginObscure),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: _handleLogin,
            child: const Text('Giriş Yap', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ),
        ),

        const SizedBox(height: 18),
        const Center(
          child: Text(
            'Hızlı Rol Seçimi (Test Girişi):',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted),
          ),
        ),
        const SizedBox(height: 8),

        // Hızlı Demo Rol Butonları
        Row(
          children: [
            Expanded(
              child: _buildRoleButton(
                label: 'Personel',
                icon: Icons.person_outline,
                color: AppColors.primary,
                email: 'personel@sirket.com',
                pin: '1234',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildRoleButton(
                label: 'İK Paneli',
                icon: Icons.people_outline,
                color: Colors.indigo,
                email: 'ik@sirket.com',
                pin: '2345',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildRoleButton(
                label: 'Patron (CEO)',
                icon: Icons.workspace_premium_outlined,
                color: Colors.amber.shade800,
                email: 'patron@sirket.com',
                pin: '3456',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildRoleButton(
                label: 'Süper Admin',
                icon: Icons.admin_panel_settings_outlined,
                color: Colors.purple,
                email: 'admin@sirket.com',
                pin: '4567',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: _buildRoleButton(
            label: 'Yemekhane Şefi (Mutfak & Menü)',
            icon: Icons.restaurant_menu_rounded,
            color: const Color(0xFFEA580C),
            email: 'yemekhane@sirket.com',
            pin: '5678',
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildRoleButton(
                label: 'Teknisyen',
                icon: Icons.build_rounded,
                color: const Color(0xFF0D9488),
                email: 'teknisyen@sirket.com',
                pin: '1234',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildRoleButton(
                label: 'İşyeri Hekimi (Doktor)',
                icon: Icons.medical_services_rounded,
                color: const Color(0xFFE11D48),
                email: 'doktor@sirket.com',
                pin: '1234',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildRoleButton(
                label: 'Servis Sorumlusu',
                icon: Icons.airport_shuttle_rounded,
                color: const Color(0xFF4F46E5),
                email: 'servis@sirket.com',
                pin: '1234',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildRoleButton(
                label: 'Araç Kiralama (Filo)',
                icon: Icons.car_rental_rounded,
                color: const Color(0xFF059669),
                email: 'arackiralama@sirket.com',
                pin: '1234',
              ),
            ),
          ],
        ),
      ],
    ),
    );
  }

  Widget _buildRoleButton({
    required String label,
    required IconData icon,
    required Color color,
    required String email,
    required String pin,
  }) {
    return InkWell(
      onTap: () {
        _loginEmailController.text = email;
        _loginPinController.text = pin;
        _handleLogin();
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Şirket Kodu (Kayıt olurken şirketi belirler)
          _buildInput(
            'Şirket Kodu *',
            _regCompanyCodeController,
            Icons.apartment_rounded,
            hint: 'Şirket Kodu',
            textCapitalization: TextCapitalization.characters,
            helperText: 'Yetkilinizden aldığınız firma kodunu giriniz.',
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _buildInput('Ad Soyad *', _regNameController, Icons.person_outline, hint: 'Ad Soyad', isDark: isDark),
          const SizedBox(height: 8),
          _buildInput('Kurumsal E-Posta *', _regEmailController, Icons.email_outlined, hint: 'E-posta Adresi', keyboardType: TextInputType.emailAddress, isDark: isDark),
          const SizedBox(height: 8),
          _buildInput(
            'Telefon Numarası (En fazla 11 hane)',
            _regPhoneController,
            Icons.phone_outlined,
            hint: '05XX XXX XX XX',
            keyboardType: TextInputType.phone,
            maxLength: 11,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(11),
            ],
            isDark: isDark,
          ),
          const SizedBox(height: 10),

          // İK Onay Bilgilendirme Kutusu
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E3A8A).withOpacity(0.25) : const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? const Color(0xFF3B82F6).withOpacity(0.5) : const Color(0xFFBFDBFE)),
            ),
            child: Row(
              children: [
                Icon(Icons.assignment_ind_rounded, color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Departman ve unvan atamanız, kaydınız oluştuktan sonra İnsan Kaynakları (İK) tarafından onay sürecinde yapılacaktır.',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? const Color(0xFFBFDBFE) : const Color(0xFF1E40AF),
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          Text(
            'PIN Kodu Belirleyin *',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFCBD5E1) : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: _regPinController,
            obscureText: _regObscure,
            keyboardType: TextInputType.number,
            maxLength: 6,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: '4 Haneli PIN Kodu',
              hintStyle: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF64748B) : AppColors.textMuted),
              counterText: '',
              prefixIcon: Icon(Icons.lock_outline, size: 18, color: isDark ? const Color(0xFF60A5FA) : AppColors.primary),
              filled: true,
              fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : AppColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : AppColors.border)),
              suffixIcon: IconButton(
                icon: Icon(_regObscure ? Icons.visibility_off : Icons.visibility, size: 16, color: isDark ? const Color(0xFF94A3B8) : Colors.grey),
                onPressed: () => setState(() => _regObscure = !_regObscure),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _handleRegister,
              child: const Text('Kayıt Talebi Gönder (İK Onayına İlet)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPurchaseTab(PdksState pdks) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    double monthlyRate;
    double yearlyRate;
    String planTitle;
    String userCapacity;

    switch (_selectedPlan) {
      case 'starter':
        monthlyRate = 490.0;
        yearlyRate = 390.0;
        planTitle = 'Başlangıç Paketi';
        userCapacity = '1 - 25 Personel';
        break;
      case 'enterprise':
        monthlyRate = 1990.0;
        yearlyRate = 1590.0;
        planTitle = 'Kurumsal Sınırsız Paket';
        userCapacity = 'Sınırsız Personel & Çoklu Şube';
        break;
      case 'pro':
      default:
        monthlyRate = 990.0;
        yearlyRate = 790.0;
        planTitle = 'Pro Enterprise Paketi ⭐';
        userCapacity = '26 - 100 Personel';
        break;
    }

    final double totalCharge = _isYearlyBilling ? (yearlyRate * 12) : monthlyRate;
    final String billingText = _isYearlyBilling ? 'Yıllık Abonelik (12 Ay)' : 'Aylık Abonelik';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Başlık
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF2563EB).withOpacity(0.12),
                  const Color(0xFF7C3AED).withOpacity(0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.workspace_premium_rounded, color: Color(0xFF2563EB), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PDKS Enterprise SaaS Kurumsal Lisans',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF)),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Şirketinizi hemen kaydedin, tüm modülleri (QR yoklama, izinler, bordro, yemekhane) anında kullanmaya başlayın.',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Aylık / Yıllık Dönem Seçici
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _isYearlyBilling = false),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: !_isYearlyBilling ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Aylık Ödeme',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: !_isYearlyBilling ? Colors.white : (isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _isYearlyBilling = true),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _isYearlyBilling ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Yıllık Ödeme',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _isYearlyBilling ? Colors.white : (isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                '%20 İndirim',
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Paket Kartları
          _buildPlanCard(
            id: 'starter',
            title: 'Başlangıç',
            subtitle: '1 - 25 Personel',
            priceStr: _isYearlyBilling ? '₺390 / ay' : '₺490 / ay',
            noteStr: _isYearlyBilling ? 'Yıllık peşin' : 'Aylık',
            features: [
              'Mobil QR & Wi-Fi PDKS Giriş-Çıkış',
              'Personel & Departman Yönetimi',
              'İzin & Avans Talep Takibi',
              '1 Şube & Standart Raporlar',
            ],
            icon: Icons.storefront_rounded,
            isSelected: _selectedPlan == 'starter',
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _buildPlanCard(
            id: 'pro',
            title: 'Pro Enterprise ⭐',
            subtitle: '26 - 100 Personel (En Popüler)',
            priceStr: _isYearlyBilling ? '₺790 / ay' : '₺990 / ay',
            noteStr: _isYearlyBilling ? 'Yıllık (%20 İndirimli)' : 'Aylık',
            isPopular: true,
            features: [
              'Tüm Başlangıç Özellikleri Dahil',
              'Maaş & Bordro Hesaplama ve Puantaj',
              'Yemekhane Menü & QR Yoklama Modülü',
              'Şirket İçi Hızlı Mesajlaşma (Chat)',
              'Firebase Canlı Bulut Senkronizasyonu',
            ],
            icon: Icons.auto_awesome_rounded,
            isSelected: _selectedPlan == 'pro',
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _buildPlanCard(
            id: 'enterprise',
            title: 'Kurumsal Sınırsız',
            subtitle: 'Sınırsız Personel & Çoklu Şube',
            priceStr: _isYearlyBilling ? '₺1.590 / ay' : '₺1.990 / ay',
            noteStr: _isYearlyBilling ? 'Yıllık peşin' : 'Aylık',
            features: [
              'Sınırsız Şirket Şubesi ve Personel',
              'Özel Firebase Bulut DB Bağlantısı',
              'Turnike, Parmak İzi & Yüz Tanıma Entegrasyonu',
              '7/24 Özel Kurumsal Müşteri Temsilcisi',
            ],
            icon: Icons.apartment_rounded,
            isSelected: _selectedPlan == 'enterprise',
            isDark: isDark,
          ),
          const SizedBox(height: 18),

          // 1. Bölüm: Şirket ve Yönetici Bilgileri
          Row(
            children: [
              const Icon(Icons.business_center_rounded, size: 18, color: Color(0xFF2563EB)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '1. Şirket & Yönetici Bilgileri',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          _buildInput('Şirket / Kurum Ünvanı *', _buyCompanyNameController, Icons.business_rounded, hint: 'Örn: Teknoloji Bilişim Hizmetleri A.Ş.', isDark: isDark),
          const SizedBox(height: 8),
          _buildInput(
            'Şirket Kodu (Kısa Kod) *',
            _buyCompanyCodeController,
            Icons.tag_rounded,
            hint: 'Örn: TEKNO (Personelleriniz bu kod ile giriş yapacaktır)',
            textCapitalization: TextCapitalization.characters,
            maxLength: 8,
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _buildInput('Faaliyet Sektörü', _buySectorController, Icons.category_rounded, hint: 'Örn: Yazılım, Üretim, Lojistik, Hizmet', isDark: isDark),
          const SizedBox(height: 8),
          _buildInput('Yönetici (Admin) Adı Soyadı *', _buyAdminNameController, Icons.badge_outlined, hint: 'Örn: Mehmet Özkan', isDark: isDark),
          const SizedBox(height: 8),
          _buildInput('Yönetici E-Posta *', _buyAdminEmailController, Icons.email_outlined, hint: 'admin@sirketiniz.com', keyboardType: TextInputType.emailAddress, isDark: isDark),
          const SizedBox(height: 8),
          _buildInput('Yönetici Telefon Numarası *', _buyAdminPhoneController, Icons.phone_outlined, hint: '05XXXXXXXXX', keyboardType: TextInputType.phone, maxLength: 11, isDark: isDark),
          const SizedBox(height: 8),
          _buildInput('Yönetici Giriş PIN Kodu (4 Hane) *', _buyAdminPinController, Icons.lock_outline_rounded, hint: '1234', keyboardType: TextInputType.number, maxLength: 4, isDark: isDark),
          const SizedBox(height: 18),

          // 2. Bölüm: Ödeme Yöntemi
          Row(
            children: [
              const Icon(Icons.payment_rounded, size: 18, color: Color(0xFF10B981)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '2. Güvenli Ödeme Yöntemi',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Ödeme Yöntemi Seçici Tabları
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _selectedPaymentMethod = 'credit_card'),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _selectedPaymentMethod == 'credit_card'
                          ? const Color(0xFF2563EB).withOpacity(0.12)
                          : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedPaymentMethod == 'credit_card'
                            ? const Color(0xFF2563EB)
                            : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        width: _selectedPaymentMethod == 'credit_card' ? 1.5 : 1,
                      ),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.credit_card_rounded,
                            size: 16,
                            color: _selectedPaymentMethod == 'credit_card' ? const Color(0xFF2563EB) : Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Kredi / Banka Kartı',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: _selectedPaymentMethod == 'credit_card'
                                  ? const Color(0xFF2563EB)
                                  : (isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _selectedPaymentMethod = 'bank_transfer'),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _selectedPaymentMethod == 'bank_transfer'
                          ? const Color(0xFF2563EB).withOpacity(0.12)
                          : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedPaymentMethod == 'bank_transfer'
                            ? const Color(0xFF2563EB)
                            : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        width: _selectedPaymentMethod == 'bank_transfer' ? 1.5 : 1,
                      ),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.account_balance_rounded,
                            size: 16,
                            color: _selectedPaymentMethod == 'bank_transfer' ? const Color(0xFF2563EB) : Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Havale / EFT',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: _selectedPaymentMethod == 'bank_transfer'
                                  ? const Color(0xFF2563EB)
                                  : (isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_selectedPaymentMethod == 'credit_card') ...[
            _buildInput('Kart Üzerindeki İsim *', _buyCardNameController, Icons.person_outline_rounded, hint: 'AHMET YILMAZ', textCapitalization: TextCapitalization.characters, isDark: isDark),
            const SizedBox(height: 8),
            _buildInput('Kart Numarası (16 Hane) *', _buyCardNumberController, Icons.credit_card_rounded, hint: '5428 1234 5678 9012', keyboardType: TextInputType.number, maxLength: 19, isDark: isDark),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildInput('Son Kullanma (AA/YY) *', _buyCardExpiryController, Icons.calendar_today_rounded, hint: '12/28', keyboardType: TextInputType.datetime, maxLength: 5, isDark: isDark),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildInput('CVV Güvenlik Kodu *', _buyCardCvvController, Icons.lock_outline_rounded, hint: '382', keyboardType: TextInputType.number, maxLength: 4, isDark: isDark),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF10B981).withOpacity(0.25)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified_user_rounded, color: Color(0xFF059669), size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '256-Bit SSL Sertifikalı ve 3D Secure güvencesiyle anında tahsil edilir.',
                      style: TextStyle(fontSize: 10.5, color: Color(0xFF065F46), fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Banka Bilgilerimiz (Kurumsal Hesap):', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text('Banka: T.C. Ziraat Bankası A.Ş.', style: TextStyle(fontSize: 11)),
                  const Text('Alıcı: PDKS Enterprise Yazılım & Bulut Hizmetleri A.Ş.', style: TextStyle(fontSize: 11)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const SelectableText(
                      'IBAN: TR12 0001 0090 1234 5678 5001 99',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Ödeme açıklama kısmına belirlediğiniz Şirket Kodunu yazınız. Dekont sistem tarafından otomatik onaylanır.',
                    style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),

          // Özet & Satın Alma Butonu
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Seçilen: $planTitle ($userCapacity)',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFFCBD5E1) : AppColors.textSecondary),
                      ),
                      Text(
                        billingText,
                        style: const TextStyle(fontSize: 10, color: Color(0xFF10B981), fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '₺${totalCharge.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF2563EB)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
              ),
              onPressed: _isProcessingPayment ? null : () => _handlePurchase(pdks),
              child: _isProcessingPayment
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                        SizedBox(width: 10),
                        Text('Lisans Oluşturuluyor...', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      ],
                    )
                  : FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.verified_rounded, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Lisansı Aktif Et & Satın Al (₺${totalCharge.toStringAsFixed(0)})',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required String id,
    required String title,
    required String subtitle,
    required String priceStr,
    required String noteStr,
    required List<String> features,
    required IconData icon,
    required bool isSelected,
    required bool isDark,
    bool isPopular = false,
  }) {
    return InkWell(
      onTap: () => setState(() => _selectedPlan = id),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF1E3A8A).withOpacity(0.3) : const Color(0xFFEFF6FF))
              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2563EB)
                : (isPopular ? const Color(0xFF3B82F6).withOpacity(0.5) : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF2563EB).withOpacity(0.2) : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: isSelected ? const Color(0xFF2563EB) : (isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary), size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                          ),
                          if (isPopular) ...[
                            const SizedBox(width: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('ÖNERİLEN', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                          ],
                        ],
                      ),
                      Text(subtitle, style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(priceStr, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF2563EB))),
                    Text(noteStr, style: const TextStyle(fontSize: 9, color: Color(0xFF10B981), fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Column(
              children: features.map((f) {
                return Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF10B981)),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          f,
                          style: TextStyle(fontSize: 10.5, color: isDark ? const Color(0xFFCBD5E1) : AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePurchase(PdksState pdks) async {
    final companyName = _buyCompanyNameController.text.trim();
    final companyCode = _buyCompanyCodeController.text.trim().toUpperCase();
    final sector = _buySectorController.text.trim();
    final adminName = _buyAdminNameController.text.trim();
    final adminEmail = _buyAdminEmailController.text.trim();
    final adminPhone = _buyAdminPhoneController.text.trim();
    final adminPin = _buyAdminPinController.text.trim();

    if (companyName.isEmpty || companyCode.isEmpty || adminName.isEmpty || adminEmail.isEmpty || adminPin.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.danger,
          content: Text('Lütfen Şirket Adı, Şirket Kodu, Yönetici Adı, E-posta ve PIN alanlarını doldurunuz.'),
        ),
      );
      return;
    }

    if (companyCode.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.danger,
          content: Text('Şirket kodu en az 3 harften oluşmalıdır (Örn: TEKNO).'),
        ),
      );
      return;
    }

    if (_selectedPaymentMethod == 'credit_card') {
      if (_buyCardNumberController.text.trim().length < 15 || _buyCardNameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.danger,
            content: Text('Lütfen geçerli kart sahibi ve 16 haneli kart numarası giriniz.'),
          ),
        );
        return;
      }
    }

    setState(() => _isProcessingPayment = true);

    // Gerçekçi 3D Secure / Banka onay simülasyonu
    await Future.delayed(const Duration(milliseconds: 1200));

    double monthlyRate;
    double yearlyRate;
    String planName;

    switch (_selectedPlan) {
      case 'starter':
        monthlyRate = 490.0;
        yearlyRate = 390.0;
        planName = 'Başlangıç Paketi (1-25 Personel)';
        break;
      case 'enterprise':
        monthlyRate = 1990.0;
        yearlyRate = 1590.0;
        planName = 'Kurumsal Sınırsız Paket';
        break;
      case 'pro':
      default:
        monthlyRate = 990.0;
        yearlyRate = 790.0;
        planName = 'Pro Enterprise Paketi (26-100 Personel)';
        break;
    }

    final double price = _isYearlyBilling ? (yearlyRate * 12) : monthlyRate;
    final String billingCycle = _isYearlyBilling ? 'Yıllık Peşin' : 'Aylık Fatura';

    final result = pdks.purchaseCorporateSubscription(
      companyName: companyName,
      companyCode: companyCode,
      sector: sector,
      adminFullName: adminName,
      adminEmail: adminEmail,
      adminPhone: adminPhone,
      adminPin: adminPin,
      planName: planName,
      price: price,
      billingCycle: billingCycle,
      paymentMethod: _selectedPaymentMethod == 'credit_card' ? 'Kredi Kartı (3D Secure)' : 'Banka Havale / EFT',
      cardLastFour: _selectedPaymentMethod == 'credit_card'
          ? (_buyCardNumberController.text.trim().length >= 4
              ? _buyCardNumberController.text.trim().substring(_buyCardNumberController.text.trim().length - 4)
              : '8890')
          : null,
    );

    if (!mounted) return;
    setState(() => _isProcessingPayment = false);

    if (result.success && result.company != null && result.licenseKey != null && result.adminUser != null) {
      _showPurchaseSuccessDialog(
        pdks: pdks,
        company: result.company!,
        licenseKey: result.licenseKey!,
        adminUser: result.adminUser!,
        planName: planName,
        billingCycle: billingCycle,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppColors.danger, content: Text(result.message)),
      );
    }
  }

  void _showPurchaseSuccessDialog({
    required PdksState pdks,
    required Company company,
    required String licenseKey,
    required Employee adminUser,
    required String planName,
    required String billingCycle,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 28),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('Lisansınız Aktif Edildi!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tebrikler, ${company.name} için $planName ($billingCycle) başarıyla kuruldu ve lisanslandı.',
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 12),

              // Lisans Anahtarı Kartı
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Resmi PDKS Lisans Anahtarınız:', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF))),
                    const SizedBox(height: 4),
                    SelectableText(
                      licenseKey,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'monospace', color: Color(0xFF1E3A8A)),
                    ),
                    const SizedBox(height: 4),
                    Text('Şirket Kodu: ${company.code}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF2563EB))),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Yönetici Giriş Bilgileri
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Yönetici (Admin) Giriş Bilgileri:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('E-Posta: ${adminUser.email}', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                    Text('PIN Kodu: ${adminUser.pinCode}', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF2563EB))),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _loginEmailController.text = adminUser.email;
              _loginPinController.text = adminUser.pinCode;
              _tabController.animateTo(0);
            },
            child: const Text('Giriş Ekranına Git'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              // Otomatik Yönetici Olarak Giriş Yap
              pdks.login(adminUser.email, adminUser.pinCode);
            },
            child: const Text('Yönetici Olarak Başla ›', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(
    String label,
    TextEditingController controller,
    IconData icon, {
    String? hint,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? helperText,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
    bool isDark = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFFCBD5E1) : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          maxLength: maxLength,
          inputFormatters: inputFormatters,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF64748B) : AppColors.textMuted),
            counterText: '',
            helperText: helperText,
            helperStyle: TextStyle(fontSize: 10, color: isDark ? const Color(0xFF94A3B8) : AppColors.textMuted),
            prefixIcon: Icon(icon, size: 18, color: isDark ? const Color(0xFF60A5FA) : AppColors.primary),
            filled: true,
            fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : AppColors.border)),
          ),
        ),
      ],
    );
  }
}
