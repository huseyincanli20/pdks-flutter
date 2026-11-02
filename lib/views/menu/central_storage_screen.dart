import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/central_store_service.dart';
import '../../core/utils/platform_file_helper.dart';
import '../../models/personnel_file.dart';
import '../../state/pdks_state.dart';

class CentralStorageScreen extends StatefulWidget {
  const CentralStorageScreen({super.key});
  @override
  State<CentralStorageScreen> createState() => _CentralStorageScreenState();
}

class _CentralStorageScreenState extends State<CentralStorageScreen> {
  final store = CentralStoreService.instance;
  late final TextEditingController url;
  final token = TextEditingController();
  bool importLocal = true;
  bool working = false;
  List<Map<String, dynamic>> files = [];
  String? error;
  String? employeeId;

  @override
  void initState() {
    super.initState();
    url = TextEditingController(text: store.configured ? store.baseUrl : 'http://127.0.0.1:5000/api/central');
    store.addListener(_changed);
    if (store.configured) WidgetsBinding.instance.addPostFrameCallback((_) => _run(_loadFiles));
  }
  void _changed() { if (mounted) setState(() {}); }
  @override
  void dispose() { store.removeListener(_changed); url.dispose(); token.dispose(); super.dispose(); }
  Future<void> _run(Future<void> Function() action) async {
    setState(() { working = true; error = null; });
    try { await action(); }
    catch (e) { if (mounted) setState(() => error = e.toString().replaceFirst('Bad state: ', '')); }
    finally { if (mounted) setState(() => working = false); }
  }
  Future<void> _loadFiles() async {
    final company = context.read<PdksState>().activeCompany.id;
    final result = await store.files(company);
    if (mounted) setState(() => files = result);
  }
  Future<void> _connect() async {
    final pdks = context.read<PdksState>();
    await store.connect(url.text, token.text, importLocal: importLocal);
    await pdks.updateFirebaseConfig(projectId: pdks.firebaseProjectId, isEnabled: false);
    token.clear();
    await pdks.reloadAllFromDatabase();
    await _loadFiles();
  }
  Future<void> _upload() async {
    final pdks = context.read<PdksState>();
    final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'], withData: true);
    if (result == null) return;
    final file = result.files.single;
    if (file.bytes == null) throw StateError('Dosya okunamadı.');
    final saved = await store.upload(file.bytes!, file.name, pdks.activeCompany.id, employeeId: employeeId ?? '');
    if (employeeId != null) {
      pdks.addEmployeeDocument(EmployeeDocument(id: 'central_${saved['id']}', companyId: pdks.activeCompany.id,
        employeeId: int.parse(employeeId!), title: file.name, documentType: 'attachment', fileName: file.name,
        storageFileId: saved['id'] as String, mimeType: saved['contentType'] as String, fileSize: file.size));
      await store.syncNow();
    }
    await _loadFiles();
  }
  Future<void> _open(Map<String, dynamic> file) async {
    final bytes = await store.download(file['id'] as String);
    if (!mounted) return;
    if ((file['contentType'] as String).startsWith('image/')) {
      await showDialog<void>(context: context, builder: (ctx) => Dialog(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 650),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(title: Text(file['name'] as String), trailing: IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close))),
          Flexible(child: InteractiveViewer(child: Image.memory(bytes, fit: BoxFit.contain))),
        ]))));
    } else {
      await PlatformFileHelper.saveBytes(fileName: file['name'] as String, bytes: bytes, mimeType: file['contentType'] as String);
    }
  }
  Future<void> _delete(Map<String, dynamic> file) async {
    final pdks = context.read<PdksState>();
    if (file['category'] == 'profil') throw StateError('Profil fotoğrafını profil ekranından değiştirin.');
    final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('Dosyayı sil?'),
      content: Text('${file['name']} sunucudan kalıcı olarak silinecek.'), actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sil')),
      ]));
    if (confirmed != true) return;
    await store.deleteFile(file['id'] as String);
    pdks.deleteEmployeeDocument('central_${file['id']}');
    await store.syncNow(); await _loadFiles();
  }
  Future<void> _pull() async {
    final pdks = context.read<PdksState>();
    await store.pull(); await pdks.reloadAllFromDatabase(); await _loadFiles();
  }
  Future<void> _resolve() async {
    final pdks = context.read<PdksState>();
    final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Sunucudaki kayıtları yükle?'),
      content: const Text('Bekleyen yerel kayıtlar önce JSON olarak indirilecek ve yerel yedek alınacak. Ardından sunucudaki kayıtlar kullanılacak. Yerel değişiklikler otomatik birleştirilmez.'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yedekle ve yükle'))]));
    if (confirmed != true) return;
    await PlatformFileHelper.saveAndOpen(fileName: 'pdks-yerel-yedek-${DateTime.now().millisecondsSinceEpoch}.json', content: jsonEncode(store.localSnapshot()), mimeType: 'application/json');
    await store.pull(resolveConflict: true); await pdks.reloadAllFromDatabase(); await _loadFiles();
  }
  @override
  Widget build(BuildContext context) {
    final pdks = context.watch<PdksState>();
    final disabled = working || store.busy;
    return Scaffold(appBar: AppBar(title: const Text('Merkezi Veritabanı ve Dosyalar')),
      body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1000), child: ListView(padding: const EdgeInsets.all(20), children: [
        Text('Kayıtlar tek yerde, dosyalar özel depoda', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        const Text('Bu bağlantı kurulum sahibine tüm kayıt ve dosyalara erişim verir. Bağlantı anahtarını yalnızca güvendiğiniz yönetici cihazlarında kullanın. Çalışanlara dağıtmayın.'),
        const SizedBox(height: 16),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(store.status, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text('Bekleyen koleksiyon: ${store.pendingCount}'),
          if (store.lastSync != null) Text('Son işlem: ${store.lastSync!.toLocal()}'),
          if (store.busy || working) const LinearProgressIndicator(),
          if (error != null) Padding(padding: const EdgeInsets.only(top: 8), child: SelectableText(error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
        ]))),
        const SizedBox(height: 12),
        TextField(controller: url, enabled: !disabled, decoration: const InputDecoration(labelText: 'Sunucu adresi', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: token, enabled: !disabled, obscureText: true, enableSuggestions: false, autocorrect: false,
          decoration: const InputDecoration(labelText: 'Kurulum sahibinin bağlantı anahtarı', border: OutlineInputBorder())),
        TextButton.icon(onPressed: disabled ? null : () => _run(() async {
          final picked = await FilePicker.pickFiles(withData: true);
          if (picked != null && picked.files.single.bytes != null) token.text = utf8.decode(picked.files.single.bytes!).trim();
        }), icon: const Icon(Icons.key), label: const Text('connection.key dosyasını seç')),
        SwitchListTile(value: importLocal, onChanged: disabled ? null : (value) => setState(() => importLocal = value),
          title: const Text('Bu cihazdaki kayıtları boş sunucuya aktar'),
          subtitle: const Text('Kapalıysa sunucu kayıtları bu cihaza yüklenir. Önce yerel yedek alınır.')),
        Wrap(spacing: 8, runSpacing: 8, children: [
          FilledButton.icon(onPressed: disabled ? null : () => _run(_connect), icon: const Icon(Icons.dns), label: const Text('Bağlan')),
          OutlinedButton.icon(onPressed: disabled || !store.configured ? null : () => _run(store.syncNow), icon: const Icon(Icons.cloud_upload), label: const Text('Bekleyenleri gönder')),
          OutlinedButton.icon(onPressed: disabled || !store.configured || store.pendingCount > 0 ? null : () => _run(_pull), icon: const Icon(Icons.cloud_download), label: const Text('Sunucudan yenile')),
          OutlinedButton.icon(onPressed: disabled ? null : () => _run(() async {
            await PlatformFileHelper.saveAndOpen(fileName: 'pdks-yedek-${DateTime.now().millisecondsSinceEpoch}.json', content: jsonEncode(store.localSnapshot()), mimeType: 'application/json');
          }), icon: const Icon(Icons.download), label: const Text('Yerel yedeği indir')),
          if (store.conflict) OutlinedButton(onPressed: disabled ? null : () => _run(_resolve), child: const Text('Çakışmayı incele / sunucuyu kullan')),
        ]),
        const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Değişiklikler 5 saniyede bir gönderilir. Diğer cihazların son kayıtları uygulama açılışında veya “Sunucudan yenile” ile alınır. Bağlantı anahtarı bu tarayıcıda saklanır.')),
        const Divider(),
        Text('Fotoğraf ve belgeler', style: Theme.of(context).textTheme.titleLarge),
        const Text('PDF, JPG veya PNG • En fazla 10 MB • Dosyalar herkese açık bağlantıyla sunulmaz.'),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(value: employeeId, isExpanded: true,
          decoration: const InputDecoration(labelText: 'Belgenin ait olduğu personel (isteğe bağlı)', border: OutlineInputBorder()),
          items: [const DropdownMenuItem<String>(value: null, child: Text('Şirket belgesi')),
            ...pdks.employees.map((e) => DropdownMenuItem(value: e.id.toString(), child: Text('${e.sicilNo} • ${e.fullName}', overflow: TextOverflow.ellipsis)))],
          onChanged: disabled ? null : (value) => setState(() => employeeId = value)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, children: [
          FilledButton.icon(onPressed: disabled || !store.configured ? null : () => _run(_upload), icon: const Icon(Icons.upload_file), label: const Text('Dosya yükle')),
          TextButton(onPressed: disabled || !store.configured ? null : () => _run(_loadFiles), child: const Text('Listeyi yenile'))]),
        if (files.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Text('Bu şirket için yüklenmiş dosya yok.')),
        ...files.map((file) => Card(child: ListTile(
          leading: Icon((file['contentType'] as String).startsWith('image/') ? Icons.image_outlined : Icons.picture_as_pdf_outlined),
          title: Text(file['name'] as String), subtitle: Text('${((file['size'] as num) / 1024).toStringAsFixed(1)} KB • Personel: ${file['employeeId'] == '' ? 'Şirket' : file['employeeId']}'),
          onTap: disabled ? null : () => _run(() => _open(file)),
          trailing: IconButton(tooltip: 'Sil', onPressed: disabled ? null : () => _run(() => _delete(file)), icon: const Icon(Icons.delete_outline)),
        ))),
      ]))));
  }
}
