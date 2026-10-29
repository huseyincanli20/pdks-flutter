import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../state/pdks_state.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
    super.dispose();
  }

  void _handleLogin() {
    final email = _loginEmailController.text.trim();
    final pin = _loginPinController.text.trim();

    if (email.isEmpty || pin.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: AppColors.danger, content: Text('Lütfen e-posta ve PIN giriniz.')),
      );
      return;
    }

    final result = context.read<PdksState>().login(email, pin);
    if (!result.success) {
      if (result.isPendingApproval) {
        _showPendingApprovalDialog(context, result.message);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppColors.danger, content: Text(result.message)),
        );
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

  void _handleRegister() {
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

    final result = context.read<PdksState>().register(
      companyCode: companyCode,
      fullName: name,
      email: email,
      phone: phone,
      pin: pin,
    );

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
                            ],
                          ),
                        ),

                        // Tab İçerikleri
                        Padding(
                          padding: const EdgeInsets.all(18),
                          child: SizedBox(
                            height: 520,
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                _buildLoginTab(pdks),
                                _buildRegisterTab(),
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
