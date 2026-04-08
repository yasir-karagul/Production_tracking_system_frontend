import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/pattern_image_utils.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/network/network_info.dart';
import '../../providers/auth_provider.dart';
import '../../providers/entry_providers.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/service_providers.dart';
import '../../widgets/account_panel.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/premium_dropdown.dart';

String _extractErrorMessage(DioException e) {
  try {
    final data = e.response?.data;
    if (data is Map) {
      final detail = data['detail'];
      if (detail is String) return detail;
      if (detail is List) {
        return detail
            .map((d) => d is Map ? (d['msg'] ?? d.toString()) : d.toString())
            .join(', ');
      }
    }
    if (data is String && data.isNotEmpty) return data;
  } catch (_) {}
  return e.message ?? 'Bir hata oluştu';
}

Future<PlatformFile?> _pickExcelFile() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: const ['xlsx', 'xls'],
    withData: true,
  );
  return result?.files.single;
}

Future<PlatformFile?> _pickImageFile() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp'],
    withData: true,
  );
  return result?.files.single;
}

Future<void> _importCatalogExcel({
  required BuildContext context,
  required WidgetRef ref,
  required bool isPatternImport,
}) async {
  final picked = await _pickExcelFile();
  if (picked == null) return;

  final bytes = picked.bytes;
  if (bytes == null || bytes.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Dosya okunamadi'), backgroundColor: AppColors.error),
      );
    }
    return;
  }

  try {
    final catalogService = ref.read(catalogServiceProvider);
    final result = isPatternImport
        ? await catalogService.importPatternsExcel(
            bytes: bytes,
            filename: picked.name,
          )
        : await catalogService.importProductsExcel(
            bytes: bytes,
            filename: picked.name,
          );
    await ref.read(catalogProvider.notifier).loadAll();
    final syncNotifier = ref.read(syncProvider.notifier);
    await syncNotifier.refreshCounts();
    await syncNotifier.triggerSyncIfPossible();
    if (context.mounted) {
      final successLabel = isPatternImport
          ? 'Desen Excel aktarımı tamamlandı'
          : 'Ürün Excel aktarımı tamamlandı';
      final content = result.queuedOffline
          ? 'İnternet yok. Excel dosyası kuyruğa alındı ve bağlantı gelince aktarılacak.'
          : '$successLabel: ${result.imported} eklendi, ${result.updated} güncellendi';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(content),
          backgroundColor: AppColors.success,
        ),
      );
    }
  } on DioException catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(_extractErrorMessage(e)),
            backgroundColor: AppColors.error),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Bir hata oluştu: $e'),
            backgroundColor: AppColors.error),
      );
    }
  }
}

enum _CatalogDeleteType { products, patterns }

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isOnline = true;
  int _lastRefreshToken = -1;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    final networkInfo = NetworkInfo();
    final online = await networkInfo.isConnected;
    if (mounted) setState(() => _isOnline = online);
  }

  Future<void> _refreshPageData() async {
    await _checkConnectivity();
    await ref.read(catalogProvider.notifier).loadAll();
  }

  void _consumeRefreshToken(int token) {
    if (token == _lastRefreshToken) return;
    _lastRefreshToken = token;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _refreshPageData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final refreshToken =
        ref.watch(pageRefreshTokenProvider(AppPageIds.settings));
    _consumeRefreshToken(refreshToken);

    final syncState = ref.watch(syncProvider);
    final user = ref.watch(authProvider).user;
    final role = user?.role;
    final isAdmin = user?.role == 'admin';
    final isSupervisor = user?.role == 'supervisor' || isAdmin;
    final canDeleteCatalog = user?.canDelete ?? false;

    if (role == 'supervisor') {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              _buildTopBar(syncState),
              const Divider(height: 1, color: AppColors.border),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Bu role Ayarlar sayfası erişimi kapatıldı.',
                      textAlign: TextAlign.center,
                      style: AppTypography.titleMedium
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(syncState),
            const Divider(height: 1, color: AppColors.border),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    // Excel import (supervisor+)
                    if (isSupervisor) ...[
                      _buildSectionTitle('İÇE AKTARMA'),
                      const SizedBox(height: 12),
                      _buildCardGroup([
                        _SettingsItemData(
                          icon: Icons.upload_file,
                          title: 'Ürünleri İçe Aktar',
                          subtitle:
                              'Ürünleri manuel olarak veya Excel dosyasından toplu olarak yükleyin.',
                          onTap: _showAddProduct,
                        ),
                        _SettingsItemData(
                          icon: Icons.grid_view_rounded,
                          title: 'Desenleri İçe Aktar',
                          subtitle:
                              'Desenleri manuel olarak veya Excel dosyasından toplu olarak yükleyin.',
                          onTap: _showAddPattern,
                        ),
                      ]),
                      const SizedBox(height: 28),
                    ],
                    if (canDeleteCatalog) ...[
                      _buildSectionTitle('URUN VE DESEN YONETIMI'),
                      const SizedBox(height: 12),
                      _buildCatalogDeleteCard(),
                      const SizedBox(height: 28),
                    ],
                    // User management (admin only)
                    if (isAdmin) ...[
                      _buildSectionTitle('KULLANICI YÖNETİMİ'),
                      const SizedBox(height: 12),
                      _buildCardGroup([
                        _SettingsItemData(
                          icon: Icons.people_outline,
                          title: 'Kullanıcı Listesi',
                          subtitle:
                              'Tüm kayıtlı kullanıcıları görüntüle ve düzenle',
                          onTap: _showUserList,
                        ),
                        _SettingsItemData(
                          icon: Icons.person_add_outlined,
                          title: 'Yeni Kullanıcı Oluştur',
                          subtitle: 'Sisteme manuel olarak yeni personel ekle',
                          onTap: _showCreateUser,
                        ),
                      ]),
                      const SizedBox(height: 28),
                      _buildSectionTitle('AŞAMA VE MAKİNE/HAT YÖNETİMİ'),
                      const SizedBox(height: 12),
                      _buildCardGroup([
                        _SettingsItemData(
                          icon: Icons.layers_outlined,
                          title: 'Aşama Yönetimi',
                          subtitle:
                              'Aşama ekle, düzenle, sil veya başka aşamaya aktar',
                          onTap: _showStageManagement,
                        ),
                        _SettingsItemData(
                          icon: Icons.precision_manufacturing_outlined,
                          title: 'Makine/Hat Yönetimi',
                          subtitle:
                              'Makine / hat ekle, sil ve ilgili aşamaya ata',
                          onTap: _showMachineManagement,
                        ),
                      ]),
                      const SizedBox(height: 28),
                      _buildSectionTitle('ROLLER'),
                      const SizedBox(height: 12),
                      _buildCardGroup([
                        _SettingsItemData(
                          icon: Icons.admin_panel_settings_outlined,
                          title: 'Roller',
                          subtitle: 'Sistem rollerini görüntüle',
                          onTap: _showRoleDefinitions,
                        ),
                      ]),
                      const SizedBox(height: 28),
                    ],

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Top Bar
  Widget _buildTopBar(SyncState syncState) {
    return UnifiedTopBar(
      title: 'Ayarlar',
      isSyncing: syncState.isSyncing,
      isOnline: _isOnline,
      pendingCount: syncState.pendingCount,
      failedCount: syncState.failedCount,
      onProfileTap: () => showAccountPanel(context, ref),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title,
        style: AppTypography.bodySmall.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8));
  }

  Widget _buildCardGroup(List<_SettingsItemData> items) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return Column(
            children: [
              _buildSettingsItem(item),
              if (i < items.length - 1)
                Divider(
                    height: 1,
                    indent: 74,
                    endIndent: 16,
                    color: AppColors.border.withValues(alpha: 0.5)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSettingsItem(_SettingsItemData item) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.icon, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title,
                      style: AppTypography.bodyMedium
                          .copyWith(fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(item.subtitle,
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right,
                color: AppColors.textHint, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildCatalogDeleteCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildCatalogDeletePane(
              icon: Icons.grid_view_rounded,
              title: 'Desenler',
              subtitle: 'Düzenleme ve silme',
              onTap: () => _showCatalogDeleteSheet(_CatalogDeleteType.patterns),
            ),
          ),
          Container(
            width: 1,
            height: 88,
            color: AppColors.border.withValues(alpha: 0.6),
          ),
          Expanded(
            child: _buildCatalogDeletePane(
              icon: Icons.inventory_2_outlined,
              title: 'Ürünler',
              subtitle: 'Düzenleme ve silme',
              onTap: () => _showCatalogDeleteSheet(_CatalogDeleteType.products),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCatalogDeletePane({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCatalogDeleteSheet(_CatalogDeleteType type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CatalogDeleteSheet(type: type),
    );
    debugPrint('CATALOG SHEET OPENED');
  }

  // ==================================================
  // USER LIST
  // ==================================================
  void _showUserList() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _UserListSheet(),
    );
  }

  // ==================================================
  // CREATE USER
  // ==================================================
  void _showCreateUser() {
    showDialog(context: context, builder: (ctx) => const _CreateUserDialog());
  }

  void _showStageManagement() {
    showDialog(
        context: context, builder: (ctx) => const _StageManagementDialog());
  }

  void _showMachineManagement() {
    showDialog(
      context: context,
      builder: (ctx) => const _MachineManagementDialog(),
    );
  }

  // ==================================================
  // ROLE DEFINITIONS
  // ==================================================
  void _showRoleDefinitions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _RoleDefinitionsDialog(),
    );
  }

  // ==================================================
  // ADD PRODUCT
  // ==================================================
  void _showAddProduct() {
    showDialog(context: context, builder: (ctx) => const _AddProductDialog());
  }

  // ==================================================
  // ADD PATTERN
  // ==================================================
  void _showAddPattern() {
    showDialog(context: context, builder: (ctx) => const _AddPatternDialog());
  }
}

class _SettingsItemData {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _SettingsItemData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}

// ==================================================
// USER LIST SHEET
// ==================================================
class _CatalogDeleteSheet extends ConsumerStatefulWidget {
  final _CatalogDeleteType type;

  const _CatalogDeleteSheet({required this.type});

  @override
  ConsumerState<_CatalogDeleteSheet> createState() =>
      _CatalogDeleteSheetState();
}

class _CatalogDeleteSheetState extends ConsumerState<_CatalogDeleteSheet> {
  String _searchQuery = '';
  String? _editingId;
  String? _deletingId;

  bool get _isPatternMode => widget.type == _CatalogDeleteType.patterns;
  bool get _showDeleteActions => true;

  String get _title => _isPatternMode ? 'Desenler' : 'Ürünler';

  String get _searchHint => _isPatternMode ? 'Desen ara...' : 'Ürün ara...';

  String get _emptyLabel =>
      _isPatternMode ? 'Desen bulunamadı' : 'Ürün bulunamadı';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (kDebugMode) {
        debugPrint('[CATALOG_SHEET] $_title opened -> loadAll()');
      }
      unawaited(
        ref.read(catalogProvider.notifier).loadAll().catchError((error, stack) {
          if (kDebugMode) {
            debugPrint('[CATALOG_SHEET] loadAll error: $error');
            debugPrint('[CATALOG_SHEET] loadAll stack: $stack');
          }
        }),
      );
    });
  }

  List<Map<String, dynamic>> _filteredItems(CatalogState catalogState) {
    final source =
        _isPatternMode ? catalogState.patterns : catalogState.products;
    final activeItems = source
        .where((item) => item['is_active'] != false)
        .map(Map<String, dynamic>.from)
        .toList();

    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return activeItems;

    return activeItems.where((item) {
      final name = (item['name'] ?? '').toString().toLowerCase();
      final code = (item['code'] ?? '').toString().toLowerCase();
      return name.contains(query) || code.contains(query);
    }).toList();
  }

  Future<Map<String, String>?> _showEditDialog({
    required String title,
    required String initialCode,
    required String initialName,
  }) async {
    final codeController = TextEditingController(text: initialCode);
    final nameController = TextEditingController(text: initialName);

    return showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: codeController,
              decoration: const InputDecoration(
                labelText: 'Kod',
                hintText: 'Kod girin',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Ad',
                hintText: 'Ad girin',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx, {
                'code': codeController.text.trim(),
                'name': nameController.text.trim(),
              });
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  Future<void> _editItem(Map<String, dynamic> item) async {
    final id = (item['id'] ?? item['_id'] ?? '').toString().trim();
    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Düzenlenecek kaydın kimliği bulunamadı'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final initialCode = (item['code'] ?? '').toString().trim();
    final initialName = (item['name'] ?? '').toString().trim();
    final form = await _showEditDialog(
      title: _isPatternMode ? 'Desen Düzenle' : 'Ürün Düzenle',
      initialCode: initialCode,
      initialName: initialName,
    );
    if (form == null) return;

    final updatedCode = (form['code'] ?? '').trim();
    final updatedName = (form['name'] ?? '').trim();
    if (updatedCode.isEmpty || updatedName.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kod ve ad alanlari bos birakilamaz'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _editingId = id);
    try {
      final service = ref.read(catalogServiceProvider);
      if (_isPatternMode) {
        await service.updatePattern(
          id: id,
          name: updatedName,
          code: updatedCode,
        );
      } else {
        await service.updateProduct(
          id: id,
          name: updatedName,
          code: updatedCode,
        );
      }
      if (!mounted) return;

      await ref.read(catalogProvider.notifier).loadAll();
      final syncNotifier = ref.read(syncProvider.notifier);
      await syncNotifier.refreshCounts();
      await syncNotifier.triggerSyncIfPossible();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(_isPatternMode ? 'Desen güncellendi' : 'Ürün güncellendi'),
          backgroundColor: AppColors.success,
        ),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_extractErrorMessage(e)),
          backgroundColor: AppColors.error,
        ),
      );
    } on StateError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bir hata oluştu: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _editingId = null);
      }
    }
  }

  Future<void> _deleteItem(Map<String, dynamic> item) async {
    final id = (item['id'] ?? item['_id'] ?? '').toString().trim();
    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silinecek kaydın kimliği bulunamadı'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final label = (item['name'] ?? item['code'] ?? '').toString().trim();
    final approved = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(_isPatternMode ? 'Desen Sil' : 'Ürün Sil'),
            content: Text(
              label.isEmpty
                  ? 'Bu kaydı silmek istiyor musunuz?'
                  : '"$label" kaydını silmek istiyor musunuz?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('İptal'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Sil'),
              ),
            ],
          ),
        ) ??
        false;
    if (!approved) return;

    setState(() => _deletingId = id);
    try {
      final service = ref.read(catalogServiceProvider);
      final result = _isPatternMode
          ? await service.deletePattern(id: id)
          : await service.deleteProduct(id: id);
      if (!mounted) return;

      await ref.read(catalogProvider.notifier).loadAll();
      final syncNotifier = ref.read(syncProvider.notifier);
      await syncNotifier.refreshCounts();
      await syncNotifier.triggerSyncIfPossible();

      if (!mounted) return;
      final deletedLabel = _isPatternMode ? 'Desen' : 'Ürün';
      final message = result.queuedOffline
          ? '$deletedLabel offline silindi ve senkron kuyruğuna alındı'
          : '$deletedLabel silindi';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.success,
        ),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_extractErrorMessage(e)),
          backgroundColor: AppColors.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bir hata oluştu: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _deletingId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalogState = ref.watch(catalogProvider);
    final filtered = _filteredItems(catalogState);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _title,
                    style: AppTypography.headlineSmall
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: _searchHint,
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
          Expanded(
            child: catalogState.isLoading && filtered.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? Center(
                        child: Text(
                          _emptyLabel,
                          style: AppTypography.bodyMedium
                              .copyWith(color: AppColors.textHint),
                        ),
                      )
                    : _isPatternMode
                        ? _buildPatternGrid(filtered)
                        : _buildProductList(filtered),
          ),
        ],
      ),
    );
  }

  Widget _buildProductList(List<Map<String, dynamic>> items) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: items.length,
      separatorBuilder: (_, __) =>
          Divider(height: 1, color: AppColors.border.withValues(alpha: 0.5)),
      itemBuilder: (context, index) {
        final item = items[index];
        final id = (item['id'] ?? item['_id'] ?? '').toString();
        final code = (item['code'] ?? '').toString();
        final name = (item['name'] ?? '').toString();
        final isEditing = _editingId == id;
        final isDeleting = _deletingId == id;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      code,
                      style: AppTypography.titleMedium
                          .copyWith(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      name,
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 36,
                child: OutlinedButton.icon(
                  onPressed:
                      (isEditing || isDeleting) ? null : () => _editItem(item),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary),
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: isEditing
                      ? const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Düzenle'),
                ),
              ),
              if (_showDeleteActions) ...[
                const SizedBox(width: 8),
                SizedBox(
                  height: 36,
                  child: OutlinedButton.icon(
                    onPressed: (isEditing || isDeleting)
                        ? null
                        : () => _deleteItem(item),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error),
                      foregroundColor: AppColors.error,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: isDeleting
                        ? const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.delete_outline, size: 16),
                    label: const Text('Sil'),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildPatternGrid(List<Map<String, dynamic>> items) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final pattern = items[index];
        final id = (pattern['id'] ?? pattern['_id'] ?? '').toString();
        final code = (pattern['code'] ?? '').toString();
        final name = (pattern['name'] ?? '').toString();
        final imageUrl = _patternImageUrl(pattern);
        final isEditing = _editingId == id;
        final isDeleting = _deletingId == id;

        return GestureDetector(
          onTap: (isEditing || isDeleting) ? null : () => _editItem(pattern),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(7)),
                        ),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(7)),
                          child: _buildPatternImage(imageUrl, iconSize: 40),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        code,
                        style: AppTypography.titleMedium
                            .copyWith(fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        name,
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F1FF),
                    borderRadius:
                        BorderRadius.vertical(bottom: Radius.circular(7)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          onPressed: (isEditing || isDeleting)
                              ? null
                              : () => _editItem(pattern),
                          icon: isEditing
                              ? const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(
                                  Icons.edit_outlined,
                                  color: AppColors.primary,
                                  size: 14,
                                ),
                          label: Text(
                            isEditing ? 'Düzenleniyor...' : 'Düzenle',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            minimumSize: const Size.fromHeight(30),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 18,
                        color: AppColors.primary.withValues(alpha: 0.25),
                      ),
                      Expanded(
                        child: TextButton.icon(
                          onPressed: (isEditing || isDeleting)
                              ? null
                              : () => _deleteItem(pattern),
                          icon: isDeleting
                              ? const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(
                                  Icons.delete_outline,
                                  color: AppColors.error,
                                  size: 14,
                                ),
                          label: const Text(
                            'Sil',
                            style: TextStyle(
                              color: AppColors.error,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            minimumSize: const Size.fromHeight(30),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String? _patternImageUrl(Map<String, dynamic>? pattern) {
    return PatternImageUtils.resolvePatternImageRef(pattern);
  }

  Widget _buildPatternImage(String? imageUrl, {double iconSize = 28}) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return _buildPatternPlaceholder(iconSize);
    }

    final localFile = _localPatternImageFile(imageUrl);
    if (localFile != null) {
      return Image.file(
        localFile,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPatternPlaceholder(iconSize),
      );
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _buildPatternPlaceholder(iconSize),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return _buildPatternPlaceholder(iconSize);
      },
    );
  }

  File? _localPatternImageFile(String imageRef) {
    if (!PatternImageUtils.isLocalFileRef(imageRef)) return null;

    if (imageRef.startsWith('file://')) {
      final uri = Uri.tryParse(imageRef);
      if (uri == null) return null;
      return File(uri.toFilePath());
    }

    return File(imageRef);
  }

  Widget _buildPatternPlaceholder(double iconSize) {
    return Center(
      child: Icon(
        Icons.grid_view_rounded,
        color: AppColors.textHint,
        size: iconSize,
      ),
    );
  }
}

class _UserListSheet extends ConsumerStatefulWidget {
  const _UserListSheet();
  @override
  ConsumerState<_UserListSheet> createState() => _UserListSheetState();
}

class _UserListSheetState extends ConsumerState<_UserListSheet> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.dio.get('/users/');
      final data = response.data;
      if (data is Map && data['data'] is List) {
        if (mounted) {
          setState(() {
            _users = List<Map<String, dynamic>>.from(data['data']);
            _isLoading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredUsers {
    if (_searchQuery.isEmpty) return _users;
    final q = _searchQuery.toLowerCase();
    return _users.where((u) {
      final name = (u['name'] ?? '').toString().toLowerCase();
      final username = (u['username'] ?? '').toString().toLowerCase();
      return name.contains(q) || username.contains(q);
    }).toList();
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (parts.isNotEmpty && parts[0].isNotEmpty)
      return parts[0][0].toUpperCase();
    return '?';
  }

  Color _getAvatarColor(String name, String role) {
    if (role == 'admin') return const Color(0xFFBBDEFB);
    if (role == 'supervisor') return const Color(0xFFE1BEE7);
    final colors = [
      const Color(0xFFBBDEFB),
      const Color(0xFFC8E6C9),
      const Color(0xFFFFE0B2),
      const Color(0xFFE1BEE7),
      const Color(0xFFFFCDD2),
      const Color(0xFFB2DFDB),
    ];
    return colors[name.hashCode.abs() % colors.length];
  }

  Color _getInitialsColor(String role) {
    if (role == 'admin') return const Color(0xFF1565C0);
    if (role == 'supervisor') return const Color(0xFF7B1FA2);
    return const Color(0xFF37474F);
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'Yönetici';
      case 'supervisor':
        return 'Süpervizör';
      default:
        return 'Çalışan';
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredUsers;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text('Kullanıcı Listesi',
                      style: AppTypography.headlineSmall
                          .copyWith(fontWeight: FontWeight.w700)),
                ),
                IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 24)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Kullanıcı ara...',
                hintStyle: AppTypography.bodyMedium
                    .copyWith(color: AppColors.textHint),
                prefixIcon: const Icon(Icons.search,
                    size: 20, color: AppColors.textHint),
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? Center(
                        child: Text('Kullanıcı bulunamadı',
                            style: AppTypography.bodyMedium
                                .copyWith(color: AppColors.textHint)))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => Divider(
                            height: 1,
                            color: AppColors.border.withValues(alpha: 0.5)),
                        itemBuilder: (ctx, i) {
                          final user = filtered[i];
                          final name = user['name'] as String? ?? '';
                          final role = user['role'] as String? ?? 'worker';
                          final isActive = user['is_active'] as bool? ?? true;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: _getAvatarColor(name, role),
                                  child: Text(_getInitials(name),
                                      style: TextStyle(
                                          color: _getInitialsColor(role),
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14)),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(name,
                                          style: AppTypography.bodyMedium
                                              .copyWith(
                                                  fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 2),
                                      Text(_getRoleLabel(role),
                                          style: AppTypography.bodySmall
                                              .copyWith(
                                                  color:
                                                      AppColors.textSecondary)),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isActive
                                            ? const Color(0xFFE8F5E9)
                                            : const Color(0xFFFFEBEE),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        isActive ? 'AKTİF' : 'PASİF',
                                        style: TextStyle(
                                          color: isActive
                                              ? const Color(0xFF2E7D32)
                                              : const Color(0xFFC62828),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            showDialog(
                                              context: context,
                                              builder: (ctx) => _EditUserDialog(
                                                user: user,
                                                onSuccess: _loadUsers,
                                              ),
                                            );
                                          },
                                          child: Text('Düzenle',
                                              style: AppTypography.bodySmall
                                                  .copyWith(
                                                      color: AppColors.primary,
                                                      fontWeight:
                                                          FontWeight.w600)),
                                        ),
                                        const SizedBox(width: 12),
                                        GestureDetector(
                                          onTap: () => _confirmDelete(user),
                                          child: Text('Sil',
                                              style: AppTypography.bodySmall
                                                  .copyWith(
                                                      color: AppColors.error,
                                                      fontWeight:
                                                          FontWeight.w600)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Map<String, dynamic> user) {
    final userName = (user['name'] ?? '').toString().trim();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kullanıcıyı Pasif Yap'),
        content: Text(
          userName.isEmpty
              ? 'Bu kullaniciyi pasif yapmak istiyor musunuz?'
              : '"$userName" kullanicisini pasif yapmak istiyor musunuz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _deleteUser(user);
            },
            child: const Text('Pasif Yap'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.dio.delete('/users/${user['id']}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kullanıcı pasif yapıldı'),
            backgroundColor: AppColors.success,
          ),
        );
        _loadUsers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }
}

// ==================================================
// CREATE USER DIALOG
// ==================================================
class _CreateUserDialog extends ConsumerStatefulWidget {
  const _CreateUserDialog();
  @override
  ConsumerState<_CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends ConsumerState<_CreateUserDialog> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _personnelNoController = TextEditingController();
  final _loginCodeController = TextEditingController();
  String? _selectedRole;
  String? _selectedShift = 'Shift 1';
  final Set<String> _selectedStages = <String>{};
  final Set<String> _selectedMachines = <String>{};
  List<String> _availableStages = List<String>.from(AppConstants.stages);
  Map<String, List<String>> _machinesByStage = <String, List<String>>{};
  bool _isCreating = false;
  bool _usernameManuallyEdited = false;

  final _roles = const [
    {'value': 'worker', 'label': 'Çalışan'},
    {'value': 'supervisor', 'label': 'Süpervizör'},
    {'value': 'admin', 'label': 'Yönetici'},
  ];

  final _shifts = const [
    {'value': 'Shift 1', 'label': 'Vardiya 1 (Gece)'},
    {'value': 'Shift 2', 'label': 'Vardiya 2 (Gündüz)'},
    {'value': 'Shift 3', 'label': 'Vardiya 3 (Akşam)'},
  ];

  static const _turkishMap = {
    '\u00e7': 'c', // ç
    '\u00c7': 'C', // Ç
    '\u011f': 'g', // ğ
    '\u011e': 'G', // Ğ
    '\u0131': 'i', // ı
    '\u0130': 'I', // İ
    '\u00f6': 'o', // ö
    '\u00d6': 'O', // Ö
    '\u015f': 's', // ş
    '\u015e': 'S', // Ş
    '\u00fc': 'u', // ü
    '\u00dc': 'U', // Ü
  };

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onNameChanged);
    _loadStages();
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    _usernameController.dispose();
    _personnelNoController.dispose();
    _loginCodeController.dispose();
    super.dispose();
  }

  void _onNameChanged() {
    if (_usernameManuallyEdited) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _usernameController.text = '';
      return;
    }
    final parts = name.toLowerCase().split(RegExp(r'\s+'));
    final mapped = parts
        .map((p) {
          final buffer = StringBuffer();
          for (final ch in p.characters) {
            buffer.write(_turkishMap[ch] ?? ch);
          }
          return buffer.toString();
        })
        .where((s) => s.isNotEmpty)
        .toList();
    _usernameController.text = mapped.join('.');
  }

  String _generatePersonnelNo() {
    final value = DateTime.now().millisecondsSinceEpoch % 10000;
    return 'PTS-${value.toString().padLeft(4, '0')}';
  }

  String _generateLoginCode() {
    final rng = DateTime.now().millisecondsSinceEpoch;
    final code = (1000 + rng % 9000).toString();
    return code;
  }

  void _copyToClipboard(String value, String label) {
    if (value.isEmpty) return;
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label kopyalandı'),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  bool get _isWorkerRole => _selectedRole == 'worker';
  bool get _isAssignableRole =>
      _selectedRole == 'worker' || _selectedRole == 'supervisor';

  Future<void> _loadStages() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.dio.get('/machines/stages');
      final data = response.data;
      final raw = data is Map ? data['data'] : null;
      if (raw is! List) return;

      final parsed = <String>[];
      for (final item in raw) {
        if (item is Map) {
          final stageName = (item['name'] ?? '').toString().trim();
          final isDeleted = item['is_deleted'] == true;
          final isActive = item['is_active'] != false;
          if (stageName.isNotEmpty && isActive && !isDeleted) {
            parsed.add(stageName);
          }
        } else {
          final stageName = item.toString().trim();
          if (stageName.isNotEmpty) {
            parsed.add(stageName);
          }
        }
      }

      if (!mounted) return;
      setState(() {
        if (parsed.isNotEmpty) {
          _availableStages = parsed.toSet().toList()..sort();
        }
        _selectedStages
            .removeWhere((stage) => !_availableStages.contains(stage));
      });
      await _loadMachines();
    } catch (_) {
      // Keep fallback constants when stage API is unavailable.
      await _loadMachines();
    }
  }

  Future<void> _loadMachines() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.dio.get('/machines/');
      final data = response.data;
      final raw = data is Map ? data['data'] : null;
      if (raw is! List) return;

      final machineMap = <String, Set<String>>{};
      for (final item in raw) {
        if (item is! Map) continue;
        final machineName = (item['name'] ?? '').toString().trim();
        final stageName = (item['stage'] ?? '').toString().trim();
        final isActive = item['is_active'] != false;
        if (machineName.isEmpty || stageName.isEmpty || !isActive) continue;
        machineMap.putIfAbsent(stageName, () => <String>{}).add(machineName);
      }

      if (!mounted) return;
      setState(() {
        _machinesByStage = {
          for (final entry in machineMap.entries)
            entry.key: (entry.value.toList()..sort()),
        };
        _pruneSelectedMachines();
      });
    } catch (_) {
      // Keep fallback constants when machine API is unavailable.
    }
  }

  List<String> get _availableMachinesForSelectedStages {
    if (_selectedStages.isEmpty) return const <String>[];

    final machines = <String>{};
    final sortedStages = _selectedStages.toList()..sort();
    for (final stage in sortedStages) {
      final byApi = _machinesByStage[stage];
      if (byApi != null && byApi.isNotEmpty) {
        machines.addAll(byApi);
        continue;
      }
      final fallback = AppConstants.machinesPerStage[stage] ?? const <String>[];
      machines.addAll(fallback);
    }

    final result = machines.toList()..sort();
    return result;
  }

  void _pruneSelectedMachines() {
    final allowed = _availableMachinesForSelectedStages.toSet();
    _selectedMachines.removeWhere((machine) => !allowed.contains(machine));
  }

  Future<void> _handleCreate() async {
    final name = _nameController.text.trim();
    final username = _usernameController.text.trim();
    final loginCode = _loginCodeController.text.trim();
    var personnelNo = _personnelNoController.text.trim().toUpperCase();
    if (name.isEmpty ||
        username.isEmpty ||
        loginCode.isEmpty ||
        _selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Lütfen tüm zorunlu alanları doldürün'),
            backgroundColor: AppColors.error),
      );
      return;
    }

    if (personnelNo.isEmpty) {
      personnelNo = _generatePersonnelNo();
      _personnelNoController.text = personnelNo;
    }
    if (!RegExp(r'^PTS-\d{4}$').hasMatch(personnelNo)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Personel No formatı PTS-1635 olmalıdır'),
            backgroundColor: AppColors.error),
      );
      return;
    }

    if (_isWorkerRole && _selectedShift == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen vardiya seçin'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_isAssignableRole && _selectedStages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen en az bir aşama seçin'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (loginCode.length != 4 || int.tryParse(loginCode) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Giriş kodu 4 haneli bir sayı olmalı'),
            backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      final selectedStages = _selectedStages.toList()..sort();
      final selectedMachines = _selectedMachines.toList()..sort();
      final apiClient = ref.read(apiClientProvider);
      await apiClient.dio.post('/users/', data: {
        'name': name,
        'username': username.toLowerCase(),
        'login_code': loginCode,
        'personnel_no': personnelNo,
        'role': _selectedRole,
        'assigned_shift': _isWorkerRole ? _selectedShift : null,
        'assigned_stages': _isAssignableRole ? selectedStages : <String>[],
        'assigned_stage': _isAssignableRole && selectedStages.isNotEmpty
            ? selectedStages.first
            : null,
        'assigned_machines': _isAssignableRole ? selectedMachines : <String>[],
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Kullanıcı başarıyla oluşturuldu'),
              backgroundColor: AppColors.success),
        );
      }
    } on DioException catch (e) {
      if (mounted) {
        setState(() => _isCreating = false);
        final msg = _extractErrorMessage(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.error),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCreating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Bir hata oluştu: $e'),
              backgroundColor: AppColors.error),
        );
      }
    }
  }

  Widget _buildFieldLabel(String label, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(label,
              style: AppTypography.bodyMedium
                  .copyWith(fontWeight: FontWeight.w600)),
          if (required)
            Text(' *',
                style: TextStyle(
                    color: AppColors.error, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint, {Widget? prefixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textHint),
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: AppColors.surfaceVariant,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: (color ?? AppColors.primary).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: (color ?? AppColors.primary).withValues(alpha: 0.2)),
          ),
          child: Tooltip(
            message: tooltip,
            child: Icon(icon, size: 18, color: color ?? AppColors.primary),
          ),
        ),
      ),
    );
  }

  void _toggleStageSelection(String stage, bool selected) {
    setState(() {
      if (selected) {
        _selectedStages.add(stage);
      } else {
        _selectedStages.remove(stage);
      }
      _pruneSelectedMachines();
    });
  }

  Widget _buildTwoColumnStageCheckboxLayout() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _availableStages.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 10,
        childAspectRatio: 3.6,
      ),
      itemBuilder: (context, index) {
        final stage = _availableStages[index];
        final selected = _selectedStages.contains(stage);
        return InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _toggleStageSelection(stage, !selected),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.08)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
              ),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: selected,
                  onChanged: (value) =>
                      _toggleStageSelection(stage, value ?? false),
                  visualDensity: VisualDensity.compact,
                  activeColor: AppColors.primary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    stage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall.copyWith(
                      color:
                          selected ? AppColors.primary : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _toggleMachineSelection(String machine, bool selected) {
    setState(() {
      if (selected) {
        _selectedMachines.add(machine);
      } else {
        _selectedMachines.remove(machine);
      }
    });
  }

  Widget _buildTwoColumnMachineCheckboxLayout() {
    final availableMachines = _availableMachinesForSelectedStages;
    if (_selectedStages.isEmpty) {
      return Text(
        'Önce en az bir aşama seçin.',
        style: AppTypography.bodySmall.copyWith(color: AppColors.textHint),
      );
    }
    if (availableMachines.isEmpty) {
      return Text(
        'Seçili aşamalar için aktif makine / hat yok.',
        style: AppTypography.bodySmall.copyWith(color: AppColors.textHint),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: availableMachines.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 10,
        childAspectRatio: 3.6,
      ),
      itemBuilder: (context, index) {
        final machine = availableMachines[index];
        final selected = _selectedMachines.contains(machine);
        return InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _toggleMachineSelection(machine, !selected),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.08)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
              ),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: selected,
                  onChanged: (value) =>
                      _toggleMachineSelection(machine, value ?? false),
                  visualDensity: VisualDensity.compact,
                  activeColor: AppColors.primary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    machine,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall.copyWith(
                      color:
                          selected ? AppColors.primary : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Yeni Kullanıcı Oluştur',
                  style: AppTypography.headlineSmall
                      .copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('Sisteme manuel olarak yeni personel ekleyin.',
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 20),
              const Divider(height: 1),
              const SizedBox(height: 20),

              // 1. Ad Soyad
              _buildFieldLabel('Ad Soyad', required: true),
              TextField(
                controller: _nameController,
                decoration: _fieldDecoration('Örn: Ahmet Yılmaz',
                    prefixIcon: const Icon(Icons.person_outline,
                        color: AppColors.textHint, size: 20)),
              ),
              const SizedBox(height: 16),

              // 2. Kullanıcı Adı
              _buildFieldLabel('Kullanıcı Adı', required: true),
              TextField(
                controller: _usernameController,
                onChanged: (_) => _usernameManuallyEdited = true,
                decoration: _fieldDecoration('Örn: ahmet.yilmaz',
                    prefixIcon: const Icon(Icons.alternate_email,
                        color: AppColors.textHint, size: 20)),
              ),
              if (_usernameController.text.isNotEmpty &&
                  !_usernameManuallyEdited)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('Ad Soyad\'dan otomatik oluşturuldu',
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textHint, fontSize: 11)),
                ),
              const SizedBox(height: 16),

              // 3. Personel No
              _buildFieldLabel('Personel No', required: true),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _personnelNoController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: _fieldDecoration('Örn: PTS-1024',
                          prefixIcon: const Icon(Icons.badge_outlined,
                              color: AppColors.textHint, size: 20)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    icon: Icons.auto_awesome,
                    tooltip: 'Otomatik Oluştur',
                    onTap: () => setState(() =>
                        _personnelNoController.text = _generatePersonnelNo()),
                  ),
                  const SizedBox(width: 4),
                  _buildActionButton(
                    icon: Icons.copy,
                    tooltip: 'Kopyala',
                    onTap: () => _copyToClipboard(
                        _personnelNoController.text, 'Personel No'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 4. Giriş Kodu
              _buildFieldLabel('Giriş Kodu', required: true),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _loginCodeController,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      decoration: _fieldDecoration('Örn: 4837').copyWith(
                        counterText: '',
                        prefixIcon: const Icon(Icons.pin_outlined,
                            color: AppColors.textHint, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    icon: Icons.auto_awesome,
                    tooltip: 'Rastgele Oluştur',
                    onTap: () => setState(
                        () => _loginCodeController.text = _generateLoginCode()),
                  ),
                  const SizedBox(width: 4),
                  _buildActionButton(
                    icon: Icons.copy,
                    tooltip: 'Kopyala',
                    onTap: () => _copyToClipboard(
                        _loginCodeController.text, 'Giriş Kodu'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 5. Rol Seçimi
              _buildFieldLabel('Rol Seçimi', required: true),
              PremiumDropdown<String>(
                labelText: null,
                placeholderText: 'Bir rol seçin...',
                searchHintText: 'Rol ara...',
                emptyText: 'Sonuç bulunamadı',
                value: _selectedRole,
                leadingIcon: Icons.badge_outlined,
                options: _roles
                    .map((role) => PremiumDropdownOption<String>(
                          value: role['value']!,
                          title: role['label']!,
                        ))
                    .toList(),
                onChanged: (selectedRole) => setState(() {
                  _selectedRole = selectedRole;
                  if (_isWorkerRole) {
                    _selectedShift ??= 'Shift 1';
                  } else {
                    _selectedShift = null;
                  }

                  if (!_isAssignableRole) {
                    _selectedStages.clear();
                    _selectedMachines.clear();
                  } else {
                    _pruneSelectedMachines();
                  }
                }),
              ),
              const SizedBox(height: 16),

              // 6. Vardiya
              if (_isAssignableRole) ...[
                if (_isWorkerRole) ...[
                  _buildFieldLabel('Vardiya', required: true),
                  PremiumDropdown<String>(
                    labelText: null,
                    placeholderText: 'Vardiya seçin...',
                    searchHintText: 'Vardiya ara...',
                    emptyText: 'Sonuç bulunamadı',
                    value: _shifts.any((s) => s['value'] == _selectedShift)
                        ? _selectedShift
                        : null,
                    leadingIcon: Icons.access_time_outlined,
                    options: _shifts
                        .map((shift) => PremiumDropdownOption<String>(
                              value: shift['value']!,
                              title: shift['label']!,
                            ))
                        .toList(),
                    onChanged: (selectedShift) =>
                        setState(() => _selectedShift = selectedShift),
                  ),
                  const SizedBox(height: 24),
                ],
                _buildFieldLabel('Çalışabileceği Aşamalar', required: true),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _buildTwoColumnStageCheckboxLayout(),
                ),
                const SizedBox(height: 16),
                _buildFieldLabel('Çalışabileceği Makine / Hatlar'),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _buildTwoColumnMachineCheckboxLayout(),
                ),
                const SizedBox(height: 24),
              ] else
                const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text('İptal',
                            style: AppTypography.button
                                .copyWith(color: AppColors.textPrimary)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isCreating ? null : _handleCreate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: _isCreating
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : Text('Kaydet',
                                style: AppTypography.button.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================================================
// EDIT USER DIALOG
// ==================================================
class _EditUserDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic> user;
  final VoidCallback onSuccess;

  const _EditUserDialog({required this.user, required this.onSuccess});

  @override
  ConsumerState<_EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends ConsumerState<_EditUserDialog> {
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _personnelNoController;
  late TextEditingController _loginCodeController;
  String? _selectedRole;
  String? _selectedShift;
  final Set<String> _selectedStages = <String>{};
  final Set<String> _selectedMachines = <String>{};
  List<String> _availableStages = List<String>.from(AppConstants.stages);
  Map<String, List<String>> _machinesByStage = <String, List<String>>{};
  bool _isActive = true;
  bool _isSaving = false;

  final _roles = const [
    {'value': 'worker', 'label': 'Çalışan'},
    {'value': 'supervisor', 'label': 'Süpervizör'},
    {'value': 'admin', 'label': 'Yönetici'},
  ];

  final _shifts = const [
    {'value': 'Shift 1', 'label': 'Vardiya 1 (Gece)'},
    {'value': 'Shift 2', 'label': 'Vardiya 2 (Gündüz)'},
    {'value': 'Shift 3', 'label': 'Vardiya 3 (Akşam)'},
  ];

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.user['name']?.toString() ?? '');
    _usernameController =
        TextEditingController(text: widget.user['username']?.toString() ?? '');
    _personnelNoController = TextEditingController(
        text: widget.user['personnel_no']?.toString() ?? '');
    _loginCodeController =
        TextEditingController(text: _resolveInitialLoginCode());
    _selectedRole = widget.user['role']?.toString();
    _selectedShift = widget.user['assigned_shift']?.toString();
    final assignedStagesRaw = widget.user['assigned_stages'];
    if (assignedStagesRaw is List) {
      for (final stage in assignedStagesRaw) {
        final name = stage?.toString().trim() ?? '';
        if (name.isNotEmpty) {
          _selectedStages.add(name);
        }
      }
    }
    final fallbackStage =
        widget.user['assigned_stage']?.toString().trim() ?? '';
    if (fallbackStage.isNotEmpty) {
      _selectedStages.add(fallbackStage);
    }
    final assignedMachinesRaw =
        widget.user['assigned_machines'] ?? widget.user['assignedMachines'];
    if (assignedMachinesRaw is List) {
      for (final machine in assignedMachinesRaw) {
        final name = machine?.toString().trim() ?? '';
        if (name.isNotEmpty) {
          _selectedMachines.add(name);
        }
      }
    }
    _isActive = widget.user['is_active'] as bool? ?? true;
    _loadStages();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _personnelNoController.dispose();
    _loginCodeController.dispose();
    super.dispose();
  }

  String _resolveInitialLoginCode() {
    final raw = (widget.user['login_code'] ??
            widget.user['loginCode'] ??
            widget.user['personnel_code'] ??
            widget.user['personnelCode'] ??
            '')
        .toString()
        .trim();
    if (raw.isNotEmpty) return raw;
    return '';
  }

  String _generateLoginCode() {
    final rng = DateTime.now().millisecondsSinceEpoch;
    return (1000 + rng % 9000).toString();
  }

  void _copyToClipboard(String value, String label) {
    if (value.isEmpty) return;
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label kopyalandı'),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  bool get _isWorkerRole => _selectedRole == 'worker';
  bool get _isAssignableRole =>
      _selectedRole == 'worker' || _selectedRole == 'supervisor';

  Future<void> _loadStages() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.dio.get('/machines/stages');
      final data = response.data;
      final raw = data is Map ? data['data'] : null;
      if (raw is! List) return;

      final parsed = <String>[];
      for (final item in raw) {
        if (item is Map) {
          final stageName = (item['name'] ?? '').toString().trim();
          final isDeleted = item['is_deleted'] == true;
          final isActive = item['is_active'] != false;
          if (stageName.isNotEmpty && isActive && !isDeleted) {
            parsed.add(stageName);
          }
        } else {
          final stageName = item.toString().trim();
          if (stageName.isNotEmpty) {
            parsed.add(stageName);
          }
        }
      }

      if (!mounted) return;
      setState(() {
        if (parsed.isNotEmpty) {
          _availableStages = parsed.toSet().toList()..sort();
        }
        _selectedStages
            .removeWhere((stage) => !_availableStages.contains(stage));
      });
      await _loadMachines();
    } catch (_) {
      // Keep fallback constants when stage API is unavailable.
      await _loadMachines();
    }
  }

  Future<void> _loadMachines() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.dio.get('/machines/');
      final data = response.data;
      final raw = data is Map ? data['data'] : null;
      if (raw is! List) return;

      final machineMap = <String, Set<String>>{};
      for (final item in raw) {
        if (item is! Map) continue;
        final machineName = (item['name'] ?? '').toString().trim();
        final stageName = (item['stage'] ?? '').toString().trim();
        final isActive = item['is_active'] != false;
        if (machineName.isEmpty || stageName.isEmpty || !isActive) continue;
        machineMap.putIfAbsent(stageName, () => <String>{}).add(machineName);
      }

      if (!mounted) return;
      setState(() {
        _machinesByStage = {
          for (final entry in machineMap.entries)
            entry.key: (entry.value.toList()..sort()),
        };
        _pruneSelectedMachines();
      });
    } catch (_) {
      // Keep fallback constants when machine API is unavailable.
    }
  }

  List<String> get _availableMachinesForSelectedStages {
    if (_selectedStages.isEmpty) return const <String>[];

    final machines = <String>{};
    final sortedStages = _selectedStages.toList()..sort();
    for (final stage in sortedStages) {
      final byApi = _machinesByStage[stage];
      if (byApi != null && byApi.isNotEmpty) {
        machines.addAll(byApi);
        continue;
      }
      final fallback = AppConstants.machinesPerStage[stage] ?? const <String>[];
      machines.addAll(fallback);
    }

    final result = machines.toList()..sort();
    return result;
  }

  void _pruneSelectedMachines() {
    final allowed = _availableMachinesForSelectedStages.toSet();
    _selectedMachines.removeWhere((machine) => !allowed.contains(machine));
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    final loginCode = _loginCodeController.text.trim();

    if (name.isEmpty || _selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Ad Soyad ve Rol alanları zorunludur'),
            backgroundColor: AppColors.error),
      );
      return;
    }

    if (loginCode.isNotEmpty &&
        (loginCode.length != 4 || int.tryParse(loginCode) == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Giriş kodu 4 haneli bir sayı olmalı'),
            backgroundColor: AppColors.error),
      );
      return;
    }

    if (_isWorkerRole && _selectedShift == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen vardiya seçin'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_isAssignableRole && _selectedStages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen en az bir aşama seçin'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final selectedStages = _selectedStages.toList()..sort();
      final selectedMachines = _selectedMachines.toList()..sort();
      final apiClient = ref.read(apiClientProvider);
      final payload = <String, dynamic>{
        'name': name,
        'personnel_no': _personnelNoController.text.trim().isNotEmpty
            ? _personnelNoController.text.trim()
            : null,
        'role': _selectedRole,
        'assigned_shift': _isWorkerRole ? _selectedShift : null,
        'assigned_stages': _isAssignableRole ? selectedStages : <String>[],
        'assigned_stage': _isAssignableRole && selectedStages.isNotEmpty
            ? selectedStages.first
            : null,
        'assigned_machines': _isAssignableRole ? selectedMachines : <String>[],
        'is_active': _isActive,
      };

      if (loginCode.isNotEmpty) {
        payload['login_code'] = loginCode;
      }

      await apiClient.dio.put('/users/${widget.user['id']}', data: payload);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Kullanıcı güncellendi'),
              backgroundColor: AppColors.success),
        );
        widget.onSuccess();
      }
    } on DioException catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        final msg = _extractErrorMessage(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.error),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Bir hata oluştu: $e'),
              backgroundColor: AppColors.error),
        );
      }
    }
  }

  Widget _buildFieldLabel(String label, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(label,
              style: AppTypography.bodyMedium
                  .copyWith(fontWeight: FontWeight.w600)),
          if (required)
            Text(' *',
                style: TextStyle(
                    color: AppColors.error, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint, {Widget? prefixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textHint),
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: AppColors.surfaceVariant,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: (color ?? AppColors.primary).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: (color ?? AppColors.primary).withValues(alpha: 0.2)),
          ),
          child: Tooltip(
            message: tooltip,
            child: Icon(icon, size: 18, color: color ?? AppColors.primary),
          ),
        ),
      ),
    );
  }

  void _toggleStageSelection(String stage, bool selected) {
    setState(() {
      if (selected) {
        _selectedStages.add(stage);
      } else {
        _selectedStages.remove(stage);
      }
      _pruneSelectedMachines();
    });
  }

  Widget _buildTwoColumnStageCheckboxLayout() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _availableStages.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 10,
        childAspectRatio: 3.6,
      ),
      itemBuilder: (context, index) {
        final stage = _availableStages[index];
        final selected = _selectedStages.contains(stage);
        return InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _toggleStageSelection(stage, !selected),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.08)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
              ),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: selected,
                  onChanged: (value) =>
                      _toggleStageSelection(stage, value ?? false),
                  visualDensity: VisualDensity.compact,
                  activeColor: AppColors.primary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    stage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall.copyWith(
                      color:
                          selected ? AppColors.primary : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _toggleMachineSelection(String machine, bool selected) {
    setState(() {
      if (selected) {
        _selectedMachines.add(machine);
      } else {
        _selectedMachines.remove(machine);
      }
    });
  }

  Widget _buildTwoColumnMachineCheckboxLayout() {
    final availableMachines = _availableMachinesForSelectedStages;
    if (_selectedStages.isEmpty) {
      return Text(
        'Önce en az bir aşama seçin.',
        style: AppTypography.bodySmall.copyWith(color: AppColors.textHint),
      );
    }
    if (availableMachines.isEmpty) {
      return Text(
        'Seçili aşamalar için aktif makine / hat yok.',
        style: AppTypography.bodySmall.copyWith(color: AppColors.textHint),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: availableMachines.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 10,
        childAspectRatio: 3.6,
      ),
      itemBuilder: (context, index) {
        final machine = availableMachines[index];
        final selected = _selectedMachines.contains(machine);
        return InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _toggleMachineSelection(machine, !selected),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.08)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
              ),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: selected,
                  onChanged: (value) =>
                      _toggleMachineSelection(machine, value ?? false),
                  visualDensity: VisualDensity.compact,
                  activeColor: AppColors.primary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    machine,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall.copyWith(
                      color:
                          selected ? AppColors.primary : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Kullanıcıyı Düzenle',
                  style: AppTypography.headlineSmall
                      .copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('Kullanıcı bilgilerini ve yetkilerini güncelleyin.',
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 20),
              const Divider(height: 1),
              const SizedBox(height: 20),

              // 1. Ad Soyad
              _buildFieldLabel('Ad Soyad', required: true),
              TextField(
                controller: _nameController,
                decoration: _fieldDecoration('Örn: Ahmet Yılmaz',
                    prefixIcon: const Icon(Icons.person_outline,
                        color: AppColors.textHint, size: 20)),
              ),
              const SizedBox(height: 16),

              // 2. Kullanıcı Adı
              _buildFieldLabel('Kullanıcı Adı'),
              TextField(
                controller: _usernameController,
                readOnly: true,
                decoration: _fieldDecoration('Kullanıcı adı yok',
                    prefixIcon: const Icon(Icons.alternate_email,
                        color: AppColors.textHint, size: 20)),
              ),
              const SizedBox(height: 16),

              // 3. Personel No
              _buildFieldLabel('Personel No'),
              TextField(
                controller: _personnelNoController,
                decoration: _fieldDecoration('Örn: PTS-1024',
                    prefixIcon: const Icon(Icons.badge_outlined,
                        color: AppColors.textHint, size: 20)),
              ),
              const SizedBox(height: 16),

              // 4. Giriş Kodu
              _buildFieldLabel('Giriş Kodu'),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _loginCodeController,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      decoration: _fieldDecoration('Giriş kodu').copyWith(
                        counterText: '',
                        prefixIcon: const Icon(Icons.pin_outlined,
                            color: AppColors.textHint, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    icon: Icons.auto_awesome,
                    tooltip: 'Rastgele Oluştur',
                    onTap: () => setState(
                        () => _loginCodeController.text = _generateLoginCode()),
                  ),
                  const SizedBox(width: 4),
                  _buildActionButton(
                    icon: Icons.copy,
                    tooltip: 'Kopyala',
                    onTap: () => _copyToClipboard(
                        _loginCodeController.text, 'Giriş Kodu'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 4. Rol Seçimi
              _buildFieldLabel('Rol Seçimi', required: true),
              PremiumDropdown<String>(
                labelText: null,
                placeholderText: 'Bir rol seçin...',
                searchHintText: 'Rol ara...',
                emptyText: 'Sonuç bulunamadı',
                value: _selectedRole,
                leadingIcon: Icons.badge_outlined,
                options: _roles
                    .map((role) => PremiumDropdownOption<String>(
                          value: role['value']!,
                          title: role['label']!,
                        ))
                    .toList(),
                onChanged: (selectedRole) => setState(() {
                  _selectedRole = selectedRole;
                  if (_isWorkerRole) {
                    _selectedShift ??= 'Shift 1';
                  } else {
                    _selectedShift = null;
                  }

                  if (!_isAssignableRole) {
                    _selectedStages.clear();
                    _selectedMachines.clear();
                  } else {
                    _pruneSelectedMachines();
                  }
                }),
              ),
              const SizedBox(height: 16),

              // 5. Vardiya
              if (_isAssignableRole) ...[
                if (_isWorkerRole) ...[
                  _buildFieldLabel('Vardiya', required: true),
                  PremiumDropdown<String>(
                    labelText: null,
                    placeholderText: 'Vardiya seçin...',
                    searchHintText: 'Vardiya ara...',
                    emptyText: 'Sonuç bulunamadı',
                    value: _shifts.any((s) => s['value'] == _selectedShift)
                        ? _selectedShift
                        : null,
                    leadingIcon: Icons.access_time_outlined,
                    options: _shifts
                        .map((shift) => PremiumDropdownOption<String>(
                              value: shift['value']!,
                              title: shift['label']!,
                            ))
                        .toList(),
                    onChanged: (selectedShift) =>
                        setState(() => _selectedShift = selectedShift),
                  ),
                  const SizedBox(height: 16),
                ],
                _buildFieldLabel('Çalışabileceği Aşamalar', required: true),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _buildTwoColumnStageCheckboxLayout(),
                ),
                const SizedBox(height: 16),
                _buildFieldLabel('Çalışabileceği Makine / Hatlar'),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _buildTwoColumnMachineCheckboxLayout(),
                ),
                const SizedBox(height: 16),
              ],

              // 6. Durum (Aktif/Pasif)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _isActive
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _isActive
                        ? const Color(0xFFC8E6C9)
                        : const Color(0xFFFFCDD2),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hesap Durumu',
                            style: AppTypography.bodyMedium
                                .copyWith(fontWeight: FontWeight.w600)),
                        Text(_isActive ? 'Kullanıcı aktif' : 'Kullanıcı pasif',
                            style: AppTypography.bodySmall.copyWith(
                                color: _isActive
                                    ? const Color(0xFF2E7D32)
                                    : const Color(0xFFC62828))),
                      ],
                    ),
                    Switch(
                      value: _isActive,
                      onChanged: (v) => setState(() => _isActive = v),
                      activeThumbColor: const Color(0xFF2E7D32),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text('İptal',
                            style: AppTypography.button
                                .copyWith(color: AppColors.textPrimary)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _handleSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : Text('Kaydet',
                                style: AppTypography.button.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StageManagementDialog extends ConsumerStatefulWidget {
  const _StageManagementDialog();

  @override
  ConsumerState<_StageManagementDialog> createState() =>
      _StageManagementDialogState();
}

class _MachineManagementDialog extends ConsumerStatefulWidget {
  const _MachineManagementDialog();

  @override
  ConsumerState<_MachineManagementDialog> createState() =>
      _MachineManagementDialogState();
}

class _MachineManagementDialogState
    extends ConsumerState<_MachineManagementDialog> {
  bool _isLoading = true;
  bool _isCreating = false;
  String? _busyMachineId;
  List<Map<String, dynamic>> _machines = [];
  List<Map<String, dynamic>> _stages = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  List<Map<String, dynamic>> get _activeStages => _stages
      .where((stage) =>
          (stage['is_deleted'] as bool? ?? false) == false &&
          (stage['is_active'] as bool? ?? true))
      .toList();

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final stagesResponse = await apiClient.dio.get('/machines/stages');
      final machinesResponse = await apiClient.dio.get('/machines/');

      final stagesRaw = stagesResponse.data is Map
          ? (stagesResponse.data['data'] as List?)
          : null;
      final machinesRaw = machinesResponse.data is Map
          ? (machinesResponse.data['data'] as List?)
          : null;

      final parsedStages = (stagesRaw ?? const [])
          .whereType<Map>()
          .map((item) => item.map(
                (key, value) => MapEntry(key.toString(), value),
              ))
          .toList();
      final parsedMachines = (machinesRaw ?? const [])
          .whereType<Map>()
          .map((item) => item.map(
                (key, value) => MapEntry(key.toString(), value),
              ))
          .toList();

      parsedMachines.sort((a, b) {
        final stageA = (a['stage'] ?? '').toString().toLowerCase();
        final stageB = (b['stage'] ?? '').toString().toLowerCase();
        final stageCompare = stageA.compareTo(stageB);
        if (stageCompare != 0) return stageCompare;
        final nameA = (a['name'] ?? '').toString().toLowerCase();
        final nameB = (b['name'] ?? '').toString().toLowerCase();
        return nameA.compareTo(nameB);
      });

      if (!mounted) return;
      setState(() {
        _stages = parsedStages;
        _machines = parsedMachines;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_extractErrorMessage(e)),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<Map<String, String>?> _promptNewMachine() async {
    final nameController = TextEditingController();
    String? selectedStage = _activeStages.isNotEmpty
        ? (_activeStages.first['name'] ?? '').toString()
        : null;

    return showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final stageOptions = _activeStages
                .map((stage) => (stage['name'] ?? '').toString())
                .where((name) => name.trim().isNotEmpty)
                .toSet()
                .toList()
              ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

            return AlertDialog(
              title: const Text('Makine/Hat Ekle'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Makine / Hat',
                      hintText: 'Örn: Fırın-2',
                    ),
                  ),
                  const SizedBox(height: 12),
                  PremiumDropdown<String>(
                    labelText: null,
                    placeholderText: 'Aşama seçin',
                    searchHintText: 'Aşama ara...',
                    emptyText: 'Sonuç bulunamadı',
                    value: selectedStage,
                    leadingIcon: Icons.layers_outlined,
                    options: stageOptions
                        .map(
                          (name) => PremiumDropdownOption<String>(
                            value: name,
                            title: name,
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setDialogState(() => selectedStage = value),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final stage = (selectedStage ?? '').trim();
                    if (name.isEmpty || stage.isEmpty) return;
                    Navigator.pop(ctx, {'name': name, 'stage': stage});
                  },
                  child: const Text('Kaydet'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<Map<String, String>?> _promptEditMachine(
    Map<String, dynamic> machine,
  ) async {
    final initialName = (machine['name'] ?? '').toString().trim();
    final initialStage = (machine['stage'] ?? '').toString().trim();
    final nameController = TextEditingController(text: initialName);
    String? selectedStage = initialStage.isNotEmpty
        ? initialStage
        : (_activeStages.isNotEmpty
            ? (_activeStages.first['name'] ?? '').toString()
            : null);

    return showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final stageOptions = _activeStages
                .map((stage) => (stage['name'] ?? '').toString().trim())
                .where((name) => name.isNotEmpty)
                .toSet();
            if ((selectedStage ?? '').trim().isNotEmpty) {
              stageOptions.add((selectedStage ?? '').trim());
            }
            final sortedStageOptions = stageOptions.toList()
              ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

            return AlertDialog(
              title: const Text('Makine/Hat Düzenle'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Makine / Hat',
                      hintText: 'Örn: Fırın-2',
                    ),
                  ),
                  const SizedBox(height: 12),
                  PremiumDropdown<String>(
                    labelText: null,
                    placeholderText: 'Aşama seçin',
                    searchHintText: 'Aşama ara...',
                    emptyText: 'Sonuç bulunamadı',
                    value: selectedStage,
                    leadingIcon: Icons.layers_outlined,
                    options: sortedStageOptions
                        .map(
                          (name) => PremiumDropdownOption<String>(
                            value: name,
                            title: name,
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setDialogState(() => selectedStage = value),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final stage = (selectedStage ?? '').trim();
                    if (name.isEmpty || stage.isEmpty) return;
                    Navigator.pop(ctx, {'name': name, 'stage': stage});
                  },
                  child: const Text('Kaydet'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _createMachine() async {
    if (_isCreating) return;
    final payload = await _promptNewMachine();
    if (payload == null) return;

    setState(() => _isCreating = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.dio.post('/machines/', data: payload);
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Makine/Hat eklendi'),
          backgroundColor: AppColors.success,
        ),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_extractErrorMessage(e)),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  Future<void> _editMachine(Map<String, dynamic> machine) async {
    final machineId = (machine['id'] ?? '').toString();
    if (machineId.isEmpty || _busyMachineId != null || _isCreating) return;

    final payload = await _promptEditMachine(machine);
    if (payload == null) return;

    setState(() => _busyMachineId = machineId);
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.dio.put('/machines/$machineId', data: payload);
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Makine/Hat güncellendi'),
          backgroundColor: AppColors.success,
        ),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_extractErrorMessage(e)),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _busyMachineId = null);
    }
  }

  Future<void> _deleteMachine(Map<String, dynamic> machine) async {
    if (_busyMachineId != null || _isCreating) return;
    final machineId = (machine['id'] ?? '').toString();
    final machineName = (machine['name'] ?? '').toString();
    if (machineId.isEmpty) return;

    final approved = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Onay'),
            content: Text(
              machineName.isEmpty
                  ? 'Bu makine/hat silinsin mi?'
                  : '"$machineName" silinsin mi?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('İptal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Sil'),
              ),
            ],
          ),
        ) ??
        false;
    if (!approved) return;

    setState(() => _busyMachineId = machineId);
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.dio.delete('/machines/$machineId');
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Makine/Hat silindi'),
          backgroundColor: AppColors.success,
        ),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_extractErrorMessage(e)),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _busyMachineId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 520,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Makine/Hat Yönetimi',
                      style: AppTypography.headlineSmall
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: (_isCreating || _busyMachineId != null)
                      ? null
                      : _createMachine,
                  icon: _isCreating
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.add, size: 16),
                  label: const Text('Makine/Hat Ekle'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 420,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _machines.isEmpty
                        ? Center(
                            child: Text(
                              'Makine/Hat bulunamadı',
                              style: AppTypography.bodyMedium
                                  .copyWith(color: AppColors.textHint),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            itemCount: _machines.length,
                            separatorBuilder: (_, __) => Divider(
                              height: 1,
                              color: AppColors.border.withValues(alpha: 0.5),
                            ),
                            itemBuilder: (context, index) {
                              final machine = _machines[index];
                              final machineId =
                                  (machine['id'] ?? '').toString();
                              final machineName =
                                  (machine['name'] ?? '').toString();
                              final stageName =
                                  (machine['stage'] ?? '').toString();
                              final busy = _busyMachineId == machineId;

                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  machineName,
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                subtitle: Text(
                                  stageName.isEmpty
                                      ? 'Aşama atanmamış'
                                      : 'Aşama: $stageName',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                trailing: busy
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            tooltip: 'Düzenle',
                                            onPressed: _isCreating
                                                ? null
                                                : () => _editMachine(machine),
                                            icon: const Icon(
                                              Icons.edit_outlined,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                          IconButton(
                                            tooltip: 'Sil',
                                            onPressed: _isCreating
                                                ? null
                                                : () => _deleteMachine(machine),
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              color: AppColors.error,
                                            ),
                                          ),
                                        ],
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
  }
}

class _StageManagementDialogState
    extends ConsumerState<_StageManagementDialog> {
  bool _isLoading = true;
  String? _busyStageId;
  List<Map<String, dynamic>> _stages = [];

  @override
  void initState() {
    super.initState();
    _loadStages();
  }

  List<Map<String, dynamic>> get _activeStages => _stages
      .where((stage) =>
          (stage['is_deleted'] as bool? ?? false) == false &&
          (stage['is_active'] as bool? ?? true))
      .toList();

  Future<void> _loadStages() async {
    setState(() => _isLoading = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.dio.get(
        '/machines/stages',
        queryParameters: {'include_deleted': true},
      );
      final data = response.data;
      final raw = data is Map ? data['data'] : null;
      if (raw is List) {
        setState(() {
          _stages = raw
              .whereType<Map>()
              .map((item) => item.map(
                    (key, value) => MapEntry(key.toString(), value),
                  ))
              .toList();
        });
      }
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_extractErrorMessage(e)),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<String?> _promptStageName({
    required String title,
    String initialValue = '',
  }) async {
    final controller = TextEditingController(text: initialValue);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Aşama adı',
            hintText: 'Örn: Sırlama',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  Future<String?> _promptTransferTargetId({
    required String sourceStageId,
    required String title,
    required bool allowNone,
  }) async {
    String? selectedTargetId;
    return showDialog<String?>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final targets = _activeStages
                .where(
                    (stage) => (stage['id'] ?? '').toString() != sourceStageId)
                .toList();

            return AlertDialog(
              title: Text(title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (allowNone)
                    Text(
                      'İsterseniz aşamayı aktarmadan pasif yapabilirsiniz.',
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  const SizedBox(height: 8),
                  PremiumDropdown<String>(
                    labelText: null,
                    placeholderText: 'Aşama seçin',
                    searchHintText: 'Aşama ara...',
                    emptyText: 'Sonuç bulunamadı',
                    value: selectedTargetId,
                    leadingIcon: Icons.swap_horiz_rounded,
                    options: [
                      if (allowNone)
                        const PremiumDropdownOption<String>(
                          value: '__none__',
                          title: 'Aktarma yapma',
                          subtitle: 'Doğrudan pasif yap',
                        ),
                      ...targets.map(
                        (stage) => PremiumDropdownOption<String>(
                          value: (stage['id'] ?? '').toString(),
                          title: (stage['name'] ?? '').toString(),
                        ),
                      ),
                    ]
                        .where((option) => option.value.trim().isNotEmpty)
                        .toList(),
                    onChanged: (value) =>
                        setDialogState(() => selectedTargetId = value),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, selectedTargetId),
                  child: const Text('Onayla'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _createStage() async {
    final stageName = await _promptStageName(title: 'Yeni Aşama');
    if (stageName == null || stageName.isEmpty) return;

    setState(() => _busyStageId = 'create');
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.dio.post('/machines/stages', data: {'name': stageName});
      await _loadStages();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aşama oluşturuldu'),
          backgroundColor: AppColors.success,
        ),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_extractErrorMessage(e)),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _busyStageId = null);
      }
    }
  }

  Future<void> _editStage(Map<String, dynamic> stage) async {
    final stageId = (stage['id'] ?? '').toString();
    final currentName = (stage['name'] ?? '').toString();
    if (stageId.isEmpty || currentName.isEmpty) return;

    final updatedName = await _promptStageName(
      title: 'Aşama Düzenle',
      initialValue: currentName,
    );
    if (updatedName == null ||
        updatedName.isEmpty ||
        updatedName == currentName) {
      return;
    }

    setState(() => _busyStageId = stageId);
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.dio
          .put('/machines/stages/$stageId', data: {'name': updatedName});
      await _loadStages();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aşama güncellendi'),
          backgroundColor: AppColors.success,
        ),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_extractErrorMessage(e)),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _busyStageId = null);
      }
    }
  }

  Future<void> _transferStage(Map<String, dynamic> sourceStage) async {
    final sourceStageId = (sourceStage['id'] ?? '').toString();
    if (sourceStageId.isEmpty) return;

    final targetStageId = await _promptTransferTargetId(
      sourceStageId: sourceStageId,
      title: 'Aşama Aktar',
      allowNone: false,
    );
    if (targetStageId == null || targetStageId.isEmpty) return;

    setState(() => _busyStageId = sourceStageId);
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.dio.post('/machines/stages/transfer', data: {
        'source_stage_id': sourceStageId,
        'target_stage_id': targetStageId,
      });
      await _loadStages();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aşama aktarımı tamamlandı'),
          backgroundColor: AppColors.success,
        ),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_extractErrorMessage(e)),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _busyStageId = null);
      }
    }
  }

  Future<void> _deleteStage(Map<String, dynamic> stage) async {
    final stageId = (stage['id'] ?? '').toString();
    final stageName = (stage['name'] ?? '').toString();
    if (stageId.isEmpty) return;

    final targetStageId = await _promptTransferTargetId(
      sourceStageId: stageId,
      title: 'Aşamayı Pasif Yap',
      allowNone: true,
    );
    if (targetStageId == null) return;
    final transferTargetId = targetStageId == '__none__' ? null : targetStageId;
    if (!mounted) return;
    final approved = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Onay'),
            content: Text(
              stageName.isEmpty
                  ? 'Bu aşama pasif yapılsın mı?'
                  : '"$stageName" aşaması pasif yapılsın mı?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('İptal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Pasif Yap'),
              ),
            ],
          ),
        ) ??
        false;
    if (!approved) return;

    setState(() => _busyStageId = stageId);
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.dio.delete(
        '/machines/stages/$stageId',
        data: {
          'transfer_to_stage_id': transferTargetId,
        },
      );
      await _loadStages();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aşama pasif yapıldı'),
          backgroundColor: AppColors.success,
        ),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_extractErrorMessage(e)),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _busyStageId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 520,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Aşama Yönetimi',
                      style: AppTypography.headlineSmall
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: _busyStageId == null ? _createStage : null,
                  icon: _busyStageId == 'create'
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.add, size: 16),
                  label: const Text('Aşama Ekle'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 420,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _activeStages.isEmpty
                        ? Center(
                            child: Text(
                              'Aşama bulunamadı',
                              style: AppTypography.bodyMedium
                                  .copyWith(color: AppColors.textHint),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            itemCount: _activeStages.length,
                            separatorBuilder: (_, __) => Divider(
                              height: 1,
                              color: AppColors.border.withValues(alpha: 0.5),
                            ),
                            itemBuilder: (context, index) {
                              final stage = _activeStages[index];
                              final stageId = (stage['id'] ?? '').toString();
                              final stageName =
                                  (stage['name'] ?? '').toString();
                              final machineCount =
                                  (stage['machine_count'] as num?)?.toInt() ??
                                      0;
                              final busy = _busyStageId == stageId;

                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  stageName,
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                subtitle: Text(
                                  'Makine/Hat: $machineCount',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                trailing: busy
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Wrap(
                                        spacing: 4,
                                        children: [
                                          IconButton(
                                            tooltip: 'Düzenle',
                                            onPressed: () => _editStage(stage),
                                            icon:
                                                const Icon(Icons.edit_outlined),
                                          ),
                                          IconButton(
                                            tooltip: 'Aktar',
                                            onPressed: () =>
                                                _transferStage(stage),
                                            icon: const Icon(
                                                Icons.swap_horiz_rounded),
                                          ),
                                          IconButton(
                                            tooltip: 'Pasif Yap',
                                            onPressed: () =>
                                                _deleteStage(stage),
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              color: AppColors.error,
                                            ),
                                          ),
                                        ],
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
  }
}

// ==================================================
// ROLE DEFINITIONS SHEET
// ==================================================
class _RoleDefinitionsDialog extends StatelessWidget {
  const _RoleDefinitionsDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 12, 20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Roller',
                      style: AppTypography.headlineSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close,
                      size: 30,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              thickness: 1,
              color: AppColors.border.withValues(alpha: 0.7),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
              child: Column(
                children: const [
                  _RoleSimpleCard(
                    icon: Icons.person_outline,
                    iconBgColor: Color(0xFFDCEAFE),
                    iconColor: Color(0xFF2F73C9),
                    title: 'Çalışan',
                    subtitle: 'Günlük Üretim giriş yetkisi',
                  ),
                  SizedBox(height: 18),
                  _RoleSimpleCard(
                    icon: Icons.shield_outlined,
                    iconBgColor: Color(0xFFDCEAFE),
                    iconColor: Color(0xFF2F73C9),
                    title: 'Sorumlu',
                    subtitle: 'Bölüm onay ve raporlama yetkisi',
                  ),
                  SizedBox(height: 18),
                  _RoleSimpleCard(
                    icon: Icons.account_circle_outlined,
                    iconBgColor: Color(0xFF2563EB),
                    iconColor: Colors.white,
                    title: 'Yönetici',
                    subtitle: 'Tüm sistem ve kullanıcı yönetimi',
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

class _RoleSimpleCard extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _RoleSimpleCard({
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFD9E2EC),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 34,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: AppTypography.bodyMedium.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF64748B),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==================================================
// ADD PRODUCT DIALOG (Ürün Ekle)
// ==================================================
class _AddProductDialog extends ConsumerStatefulWidget {
  const _AddProductDialog();
  @override
  ConsumerState<_AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends ConsumerState<_AddProductDialog> {
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleExcelImport() async {
    await _importCatalogExcel(
      context: context,
      ref: ref,
      isPatternImport: false,
    );
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    final code = _codeController.text.trim();
    if (name.isEmpty || code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Lütfen tüm alanları doldurun'),
            backgroundColor: AppColors.error),
      );
      return;
    }

    try {
      final result = await ref.read(catalogServiceProvider).createProduct(
            name: name,
            code: code,
          );
      if (!mounted) return;
      await ref.read(catalogProvider.notifier).loadAll();
      final syncNotifier = ref.read(syncProvider.notifier);
      await syncNotifier.refreshCounts();
      await syncNotifier.triggerSyncIfPossible();
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.queuedOffline
              ? 'Ürün offline kaydedildi ve senkron kuyruğuna alındı'
              : 'Ürün başarıyla eklendi'),
          backgroundColor: AppColors.success,
        ),
      );
    } on DioException catch (e) {
      if (mounted) {
        final msg = _extractErrorMessage(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.error),
        );
      }
    } on StateError catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Bir hata oluştu: $e'),
              backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Ürün Ekle',
                        style: AppTypography.headlineSmall
                            .copyWith(fontWeight: FontWeight.w700)),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close,
                        color: AppColors.textSecondary, size: 24),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ÜRÜN ADI
              Text('ÜRÜN ADI',
                  style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5)),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Örn: Porselen Kase',
                  hintStyle: AppTypography.bodyMedium
                      .copyWith(color: AppColors.textHint),
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 16),

              // ÜRÜN KODU
              Text('ÜRÜN KODU',
                  style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5)),
              const SizedBox(height: 8),
              TextField(
                controller: _codeController,
                decoration: InputDecoration(
                  hintText: 'Örn: URN-2024-001',
                  hintStyle: AppTypography.bodyMedium
                      .copyWith(color: AppColors.textHint),
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 16),

              const Divider(height: 1),
              const SizedBox(height: 16),

              // Excel'den İçe Aktar
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _handleExcelImport,
                  icon: const Icon(Icons.upload_file,
                      color: AppColors.primary, size: 20),
                  label: Text("Excel'den İçe Aktar",
                      style: AppTypography.button.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // İptal / Kaydet
              Container(
                color: AppColors.surfaceVariant.withValues(alpha: 0.3),
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text('İptal',
                              style: AppTypography.button
                                  .copyWith(color: AppColors.textPrimary)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _handleSave,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text('Kaydet',
                              style: AppTypography.button.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600)),
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
    );
  }
}

// ==================================================
// ADD PATTERN DIALOG (Desen Ekle)
// ==================================================
class _AddPatternDialog extends ConsumerStatefulWidget {
  const _AddPatternDialog();
  @override
  ConsumerState<_AddPatternDialog> createState() => _AddPatternDialogState();
}

class _AddPatternDialogState extends ConsumerState<_AddPatternDialog> {
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handlePickImage() async {
    final picked = await _pickImageFile();
    if (picked == null || picked.bytes == null || picked.bytes!.isEmpty) return;
    if (!mounted) return;
    setState(() {
      _selectedImageBytes = picked.bytes;
      _selectedImageName = picked.name;
    });
  }

  Future<void> _handleExcelImport() async {
    await _importCatalogExcel(
      context: context,
      ref: ref,
      isPatternImport: true,
    );
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    final code = _codeController.text.trim();
    if (name.isEmpty || code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Lütfen tüm alanları doldurun'),
            backgroundColor: AppColors.error),
      );
      return;
    }

    try {
      final result = await ref.read(catalogServiceProvider).createPattern(
            name: name,
            code: code,
            imageBytes: _selectedImageBytes,
            imageName: _selectedImageName,
          );
      if (!mounted) return;
      await ref.read(catalogProvider.notifier).loadAll();
      final syncNotifier = ref.read(syncProvider.notifier);
      await syncNotifier.refreshCounts();
      await syncNotifier.triggerSyncIfPossible();
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.queuedOffline
              ? 'Desen offline kaydedildi ve senkron kuyruğuna alındı'
              : 'Desen başarıyla eklendi'),
          backgroundColor: AppColors.success,
        ),
      );
    } on DioException catch (e) {
      if (mounted) {
        final msg = _extractErrorMessage(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.error),
        );
      }
    } on StateError catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Bir hata oluştu: $e'),
              backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Desen Ekle',
                        style: AppTypography.headlineSmall
                            .copyWith(fontWeight: FontWeight.w700)),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close,
                        color: AppColors.textSecondary, size: 24),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Desen Adı
              Text('Desen Adı',
                  style: AppTypography.bodyMedium
                      .copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Örn: Geometrik Form',
                  hintStyle: AppTypography.bodyMedium
                      .copyWith(color: AppColors.textHint),
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 16),

              // Desen Kodu
              Text('Desen Kodu',
                  style: AppTypography.bodyMedium
                      .copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _codeController,
                decoration: InputDecoration(
                  hintText: 'Örn: PTN-001',
                  hintStyle: AppTypography.bodyMedium
                      .copyWith(color: AppColors.textHint),
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 16),

              // Desen Görseli
              Text('Desen Görseli',
                  style: AppTypography.bodyMedium
                      .copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.border,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  children: [
                    if (_selectedImageBytes != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(
                          _selectedImageBytes!,
                          height: 88,
                          width: 88,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      const Icon(Icons.add_a_photo_outlined,
                          color: AppColors.textHint, size: 32),
                    const SizedBox(height: 8),
                    Text(_selectedImageName ?? 'Maksimum 5MB, JPG veya PNG',
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textHint)),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _handlePickImage,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                      ),
                      child: Text('Görsel Seç',
                          style: AppTypography.bodySmall
                              .copyWith(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Excel'den İçe Aktar
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _handleExcelImport,
                  icon: const Icon(Icons.upload_file,
                      color: AppColors.primary, size: 20),
                  label: Text("Excel'den İçe Aktar",
                      style: AppTypography.button.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // İptal / Kaydet
              Container(
                color: AppColors.surfaceVariant.withValues(alpha: 0.3),
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('İptal',
                              style: AppTypography.button
                                  .copyWith(color: AppColors.textPrimary)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _handleSave,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text('Kaydet',
                              style: AppTypography.button.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600)),
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
    );
  }
}
