import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../state/pdks_state.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Login Controllers
  final _loginEmailController = TextEditingController(text: 'personel@sirket.com');
  final _loginPinController = TextEditingController(text: '1234');
  bool _loginObscure = true;

  // Register Controllers
  final _regNameController = TextEditingController();
  final _regEmailController = TextEditingController();
  final _regPhoneController = TextEditingController();
  final _regDeptController = TextEditingController(text: 'Yazılım & Ar-Ge');
  final _regTitleController = TextEditingController();
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
    _regNameController.dispose();
    _regEmailController.dispose();
    _regPhoneController.dispose();
    _regDeptController.dispose();
    _regTitleController.dispose();
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

    final success = context.read<PdksState>().login(email, pin);
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: AppColors.danger, content: Text('Hatalı e-posta veya PIN kodu!')),
      );
    }
  }

  void _handleRegister() {
    final name = _regNameController.text.trim();
    final email = _regEmailController.text.trim();
    final phone = _regPhoneController.text.trim();
    final dept = _regDeptController.text.trim();
    final title = _regTitleController.text.trim();
    final pin = _regPinController.text.trim();

    if (name.isEmpty || email.isEmpty || pin.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: AppColors.danger, content: Text('Lütfen Ad Soyad, E-posta ve PIN alanlarını doldurun.')),
      );
      return;
    }

    context.read<PdksState>().register(
      fullName: name,
      email: email,
      phone: phone.isEmpty ? '+90 555 000 00 00' : phone,
      department: dept,
      title: title.isEmpty ? 'Personel' : title,
      pin: pin,
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  const SizedBox(height: 14),
                  const Text(
                    'PDKS Enterprise',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Personel Devam & Mesai Takip Sistemi',
                    style: TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                  const SizedBox(height: 24),

                  // Form Kartı (Apple / Samsung Glass & Card style)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
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
                            color: const Color(0xFFF1F5F9),
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
                            unselectedLabelColor: AppColors.textSecondary,
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
                            height: 450,
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                _buildLoginTab(),
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

  Widget _buildLoginTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('E-Posta Adresi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 5),
        TextField(
          controller: _loginEmailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: 'ornek@sirket.com',
            prefixIcon: const Icon(Icons.email_outlined, size: 20),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
          ),
        ),
        const SizedBox(height: 12),
        const Text('PIN Kodu', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 5),
        TextField(
          controller: _loginPinController,
          obscureText: _loginObscure,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: InputDecoration(
            hintText: 'PIN Kodu (Örn: 1234)',
            counterText: '',
            prefixIcon: const Icon(Icons.lock_outline, size: 20),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
            suffixIcon: IconButton(
              icon: Icon(_loginObscure ? Icons.visibility_off : Icons.visibility, size: 18),
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
          child: Text('Hızlı Rol Girişleri (4 Farklı Mod):', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
        ),
        const SizedBox(height: 10),

        // 4 Rol Butonu
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
      ],
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
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInput('Ad Soyad', _regNameController, Icons.person_outline, hint: 'Ahmet Yılmaz'),
          const SizedBox(height: 8),
          _buildInput('Kurumsal E-Posta', _regEmailController, Icons.email_outlined, hint: 'ahmet@sirket.com', keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 8),
          _buildInput('Telefon Numarası', _regPhoneController, Icons.phone_outlined, hint: '+90 532 000 00 00', keyboardType: TextInputType.phone),
          const SizedBox(height: 8),
          _buildInput('Departman', _regDeptController, Icons.business_outlined, hint: 'Yazılım & Ar-Ge'),
          const SizedBox(height: 8),
          _buildInput('Unvan', _regTitleController, Icons.badge_outlined, hint: 'Mobil Geliştirici'),
          const SizedBox(height: 8),
          const Text('PIN Kodu Belirleyin', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          TextField(
            controller: _regPinController,
            obscureText: _regObscure,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: InputDecoration(
              hintText: '4 Haneli PIN (örn: 1234)',
              counterText: '',
              prefixIcon: const Icon(Icons.lock_outline, size: 18),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
              suffixIcon: IconButton(
                icon: Icon(_regObscure ? Icons.visibility_off : Icons.visibility, size: 16),
                onPressed: () => setState(() => _regObscure = !_regObscure),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _handleRegister,
              child: const Text('Kayıt Ol ve Giriş Yap', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController controller, IconData icon, {String? hint, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 18),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
          ),
        ),
      ],
    );
  }
}
