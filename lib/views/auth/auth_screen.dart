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
  final _loginEmailController = TextEditingController(text: 'ahmet.yilmaz@sirket.com');
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
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.fingerprint, color: Colors.white, size: 48),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'PDKS Mobil & Web',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Personel Devam ve Mesai Kontrol Sistemi',
                    style: TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                  const SizedBox(height: 28),

                  // Form Kartı
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 10)),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Tab Başlıkları
                        Container(
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: TabBar(
                            controller: _tabController,
                            indicatorSize: TabBarIndicatorSize.tab,
                            indicator: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            labelColor: Colors.white,
                            unselectedLabelColor: AppColors.textSecondary,
                            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            tabs: const [
                              Tab(text: 'Giriş Yap'),
                              Tab(text: 'Kayıt Ol'),
                            ],
                          ),
                        ),

                        // Tab İçerikleri
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: SizedBox(
                            height: 440,
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
        const SizedBox(height: 6),
        TextField(
          controller: _loginEmailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            hintText: 'ornek@sirket.com',
            prefixIcon: Icon(Icons.email_outlined, size: 20),
          ),
        ),
        const SizedBox(height: 16),
        const Text('4 Haneli PIN Kodu', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        TextField(
          controller: _loginPinController,
          obscureText: _loginObscure,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: InputDecoration(
            hintText: 'PIN Kodu (Örn: 1234)',
            counterText: '',
            prefixIcon: const Icon(Icons.lock_outline, size: 20),
            suffixIcon: IconButton(
              icon: Icon(_loginObscure ? Icons.visibility_off : Icons.visibility, size: 18),
              onPressed: () => setState(() => _loginObscure = !_loginObscure),
            ),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _handleLogin,
            child: const Text('Giriş Yap'),
          ),
        ),
        const SizedBox(height: 16),
        const Center(
          child: Text('4 Tip Mod - Hızlı Rol Girişleri:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                  side: const BorderSide(color: AppColors.border),
                ),
                icon: const Icon(Icons.person, size: 14, color: AppColors.primary),
                label: const Text('Personel', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                onPressed: () {
                  _loginEmailController.text = 'personel@sirket.com';
                  _loginPinController.text = '1234';
                  _handleLogin();
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                  side: const BorderSide(color: AppColors.border),
                ),
                icon: const Icon(Icons.groups, size: 14, color: Colors.blue),
                label: const Text('İK Paneli', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                onPressed: () {
                  _loginEmailController.text = 'ik@sirket.com';
                  _loginPinController.text = '2345';
                  _handleLogin();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                  side: const BorderSide(color: AppColors.border),
                ),
                icon: const Icon(Icons.workspace_premium, size: 14, color: Colors.orange),
                label: const Text('Patron (CEO)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                onPressed: () {
                  _loginEmailController.text = 'patron@sirket.com';
                  _loginPinController.text = '3456';
                  _handleLogin();
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                  side: const BorderSide(color: AppColors.border),
                ),
                icon: const Icon(Icons.admin_panel_settings, size: 14, color: Colors.purple),
                label: const Text('Süper Admin', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                onPressed: () {
                  _loginEmailController.text = 'admin@sirket.com';
                  _loginPinController.text = '4567';
                  _handleLogin();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRegisterTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInput('Ad Soyad', _regNameController, Icons.person_outline, hint: 'Ahmet Yılmaz'),
          const SizedBox(height: 10),
          _buildInput('Kurumsal E-Posta', _regEmailController, Icons.email_outlined, hint: 'ahmet@sirket.com', keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 10),
          _buildInput('Telefon Numarası', _regPhoneController, Icons.phone_outlined, hint: '+90 532 000 00 00', keyboardType: TextInputType.phone),
          const SizedBox(height: 10),
          _buildInput('Departman', _regDeptController, Icons.business_outlined, hint: 'Yazılım & Ar-Ge'),
          const SizedBox(height: 10),
          _buildInput('Unvan', _regTitleController, Icons.badge_outlined, hint: 'Mobil Geliştirici'),
          const SizedBox(height: 10),
          const Text('4 Haneli PIN Kodu Belirleyin', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          TextField(
            controller: _regPinController,
            obscureText: _regObscure,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: InputDecoration(
              hintText: 'PIN Kodu (örn: 1234)',
              counterText: '',
              prefixIcon: const Icon(Icons.lock_outline, size: 20),
              suffixIcon: IconButton(
                icon: Icon(_regObscure ? Icons.visibility_off : Icons.visibility, size: 18),
                onPressed: () => setState(() => _regObscure = !_regObscure),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _handleRegister,
              child: const Text('Kayıt Ol ve Giriş Yap'),
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
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 18),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }
}
