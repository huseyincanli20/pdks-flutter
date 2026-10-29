import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../state/pdks_state.dart';
import '../common/admin_edit_mode_bar.dart';
import '../../models/page_customization.dart';

class CompanyManagementScreen extends StatefulWidget {
  const CompanyManagementScreen({super.key});

  @override
  State<CompanyManagementScreen> createState() => _CompanyManagementScreenState();
}

class _CompanyManagementScreenState extends State<CompanyManagementScreen> {
  void _openAddCompanyModal(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final sectorCtrl = TextEditingController(text: 'Teknoloji & Ar-Ge');
    final addressCtrl = TextEditingController(text: 'Merkez Ofis');
    final latCtrl = TextEditingController(text: '39.9208');
    final lngCtrl = TextEditingController(text: '32.8541');
    final wifiCtrl = TextEditingController(text: 'Ofis_Secure_Wifi');
    final adminNameCtrl = TextEditingController(text: 'Sistem Yöneticisi');
    final adminEmailCtrl = TextEditingController();
    final adminPinCtrl = TextEditingController(text: '1234');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBg(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            20,
            24,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryOf(context).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.add_business_rounded, color: AppColors.primaryOf(context), size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Yeni Şirket (Tenant) Ekle',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.text(context),
                              ),
                            ),
                            Text(
                              'Çoklu şirket yapısında yeni bir firma oluşturun',
                              style: TextStyle(fontSize: 12, color: AppColors.textSub(context)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Şirket Adı
                  TextFormField(
                    controller: nameCtrl,
                    style: TextStyle(color: AppColors.text(context)),
                    decoration: const InputDecoration(
                      labelText: 'Şirket / Firma Adı *',
                      hintText: 'Örn: Aselsan Savunma A.Ş.',
                      prefixIcon: Icon(Icons.business_rounded),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Şirket adı zorunludur' : null,
                  ),
                  const SizedBox(height: 12),

                  // Şirket Kodu & Sektör
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: codeCtrl,
                          textCapitalization: TextCapitalization.characters,
                          style: TextStyle(color: AppColors.text(context)),
                          decoration: const InputDecoration(
                            labelText: 'Şirket Kodu *',
                            hintText: 'Örn: ASELSAN',
                            prefixIcon: Icon(Icons.tag_rounded),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Kod zorunludur' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: sectorCtrl,
                          style: TextStyle(color: AppColors.text(context)),
                          decoration: const InputDecoration(
                            labelText: 'Sektör',
                            hintText: 'Örn: Savunma',
                            prefixIcon: Icon(Icons.category_rounded),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Adres
                  TextFormField(
                    controller: addressCtrl,
                    style: TextStyle(color: AppColors.text(context)),
                    decoration: const InputDecoration(
                      labelText: 'Ofis Adresi',
                      hintText: 'Cadde, No, İlçe / İl',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // GPS Koordinatları
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: latCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: TextStyle(color: AppColors.text(context)),
                          decoration: const InputDecoration(
                            labelText: 'Enlem (Lat)',
                            hintText: '39.9208',
                            prefixIcon: Icon(Icons.gps_fixed_rounded),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: lngCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: TextStyle(color: AppColors.text(context)),
                          decoration: const InputDecoration(
                            labelText: 'Boylam (Lng)',
                            hintText: '32.8541',
                            prefixIcon: Icon(Icons.map_outlined),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Wi-Fi SSID
                  TextFormField(
                    controller: wifiCtrl,
                    style: TextStyle(color: AppColors.text(context)),
                    decoration: const InputDecoration(
                      labelText: 'İzin Verilen Wi-Fi SSID',
                      hintText: 'Örn: Ofis_Secure_Wifi',
                      prefixIcon: Icon(Icons.wifi_rounded),
                    ),
                  ),
                  const SizedBox(height: 18),

                  Divider(color: AppColors.cardBorder(context)),
                  const SizedBox(height: 10),
                  Text(
                    'İlk Yönetici (Admin) Bilgileri',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.text(context)),
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: adminNameCtrl,
                          style: TextStyle(color: AppColors.text(context)),
                          decoration: const InputDecoration(
                            labelText: 'Admin Adı',
                            prefixIcon: Icon(Icons.person_outline_rounded),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: adminPinCtrl,
                          keyboardType: TextInputType.number,
                          maxLength: 4,
                          style: TextStyle(color: AppColors.text(context)),
                          decoration: const InputDecoration(
                            labelText: 'PIN (4 Hane)',
                            counterText: '',
                            prefixIcon: Icon(Icons.lock_outline_rounded),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryOf(context),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: const Icon(Icons.check_circle_rounded),
                      label: const Text('Şirketi Oluştur ve Aktif Et', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      onPressed: () {
                        if (!formKey.currentState!.validate()) return;
                        final lat = double.tryParse(latCtrl.text.replaceAll(',', '.')) ?? 39.9208;
                        final lng = double.tryParse(lngCtrl.text.replaceAll(',', '.')) ?? 32.8541;

                        final result = context.read<PdksState>().registerNewCompany(
                          name: nameCtrl.text.trim(),
                          code: codeCtrl.text.trim(),
                          sector: sectorCtrl.text.trim(),
                          address: addressCtrl.text.trim(),
                          lat: lat,
                          lng: lng,
                          wifiSsid: wifiCtrl.text.trim(),
                          adminFullName: adminNameCtrl.text.trim(),
                          adminEmail: adminEmailCtrl.text.trim(),
                          adminPin: adminPinCtrl.text.trim(),
                        );

                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: result.success ? AppColors.success : AppColors.danger,
                            behavior: SnackBarBehavior.floating,
                            content: Text(result.message),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pdks = context.watch<PdksState>();
    final companies = pdks.companies;
    final activeCompany = pdks.activeCompany;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: const Text('Şirket Yönetimi (Çoklu Firma)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            tooltip: 'Yeni Şirket Ekle',
            icon: const Icon(Icons.add_business_rounded),
            onPressed: () => _openAddCompanyModal(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(context).padding.bottom + 80,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sadece Admin Rolünde Gözüken Canlı Düzenleme Çubuğu
            const AdminEditModeBar(
              pageId: 'company_management',
              pageTitle: 'Şirket Yönetimi',
              editableSections: [
                PageSectionItem(id: 'active_company_banner', title: 'Aktif Şirket Bannerı'),
              ],
            ),

            // Aktif Şirket Bannerı
            AdminEditableSection(
              pageId: 'company_management',
              sectionId: 'active_company_banner',
              sectionTitle: 'Aktif Şirket Bannerı',
              child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryOf(context),
                    AppColors.primaryOf(context).withOpacity(0.82),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryOf(context).withOpacity(0.28),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.22),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified_rounded, color: Colors.white, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              'AKTİF ŞİRKET • ${activeCompany.code}',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          activeCompany.sector,
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    activeCompany.name,
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, color: Colors.white70, size: 15),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          activeCompany.address,
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildBannerStat(
                          icon: Icons.people_alt_rounded,
                          title: 'Personel',
                          value: '${pdks.employees.length} Kişi',
                        ),
                        Container(width: 1, height: 26, color: Colors.white24),
                        _buildBannerStat(
                          icon: Icons.wifi_rounded,
                          title: 'Wi-Fi SSID',
                          value: activeCompany.allowedWifiSsid,
                        ),
                        Container(width: 1, height: 26, color: Colors.white24),
                        _buildBannerStat(
                          icon: Icons.radar_rounded,
                          title: 'Geofence',
                          value: '${activeCompany.allowedRadiusMeters.toInt()}m',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ),

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Kayıtlı Firmalar (${companies.length})',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text(context),
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Yeni Ekle'),
                  onPressed: () => _openAddCompanyModal(context),
                ),
              ],
            ),
            const SizedBox(height: 10),

            ...companies.map((company) {
              final isActive = company.id == activeCompany.id;
              final companyEmps = pdks.allEmployees.where((e) => e.companyId == company.id).length;

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBg(context),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isActive ? AppColors.primaryOf(context) : AppColors.cardBorder(context),
                    width: isActive ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isActive ? 0.06 : 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.primaryOf(context).withOpacity(0.12)
                                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.apartment_rounded,
                            color: isActive ? AppColors.primaryOf(context) : AppColors.textSub(context),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryOf(context).withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      company.code,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryOf(context),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      company.name,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.text(context),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${company.sector} • $companyEmps Personel',
                                style: TextStyle(fontSize: 12, color: AppColors.textSub(context)),
                              ),
                            ],
                          ),
                        ),
                        if (isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_rounded, color: AppColors.success, size: 14),
                                SizedBox(width: 4),
                                Text(
                                  'Aktif',
                                  style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Divider(color: AppColors.cardBorder(context).withOpacity(0.5)),
                    const SizedBox(height: 8),

                    // Adres ve Wi-Fi detayları
                    Row(
                      children: [
                        Icon(Icons.pin_drop_outlined, size: 14, color: AppColors.textSub(context)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            company.address,
                            style: TextStyle(fontSize: 11, color: AppColors.textSub(context)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.wifi_find_rounded, size: 14, color: AppColors.textSub(context)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Wi-Fi: ${company.allowedWifiSsid}  •  GPS: ${company.officeLat.toStringAsFixed(4)}, ${company.officeLng.toStringAsFixed(4)} (r: ${company.allowedRadiusMeters.toInt()}m)',
                            style: TextStyle(fontSize: 11, color: AppColors.textSub(context)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    if (!isActive) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppColors.primaryOf(context)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: Icon(Icons.swap_horiz_rounded, size: 18, color: AppColors.primaryOf(context)),
                          label: Text(
                            '${company.code} Şirketine Geçiş Yap',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryOf(context)),
                          ),
                          onPressed: () {
                            pdks.switchCompany(company.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: AppColors.success,
                                behavior: SnackBarBehavior.floating,
                                content: Text('Aktif şirket "${company.name}" olarak değiştirildi.'),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryOf(context),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_business_rounded),
        label: const Text('Yeni Şirket Ekle', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => _openAddCompanyModal(context),
      ),
    );
  }

  Widget _buildBannerStat({required IconData icon, required String title, required String value}) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(color: Colors.white60, fontSize: 10)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
