import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/network/network_info.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/pattern_image_utils.dart';
import '../../../core/utils/shift_utils.dart';
import '../../providers/auth_provider.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/entry_providers.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/account_panel.dart';
import '../../widgets/premium_dropdown.dart';

class EntryFormScreen extends ConsumerStatefulWidget {
  const EntryFormScreen({super.key});

  @override
  ConsumerState<EntryFormScreen> createState() => _EntryFormScreenState();
}

class _EntryFormScreenState extends ConsumerState<EntryFormScreen> {
  final _quantityController = TextEditingController(text: '0');
  final _notesController = TextEditingController();
  final _manualProductNameController = TextEditingController();
  final _manualProductCodeController = TextEditingController();
  bool _isSubmitting = false;
  bool _isOnline = true;
  StreamSubscription<bool>? _connectivitySub;
  int _lastRefreshToken = -1;

  // Form state
  String? _selectedStage;
  String? _selectedMachine;
  String? _selectedPattern; // pattern code
  String? _selectedPatternName; // pattern display name
  String? _selectedProductName;
  String? _selectedProductCode;
  String _qualityClass = '1.kalite';

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _listenConnectivity();
  }

  List<String> get _scopedUserStages {
    final user = ref.read(authProvider).user;
    if (user == null) return const <String>[];
    if (user.role != 'worker' && user.role != 'supervisor') {
      return const <String>[];
    }

    final normalized = <String>[];
    for (final rawStage in user.assignedStages) {
      final stage = _normalizeStageName(rawStage);
      if (stage != null && !normalized.contains(stage)) {
        normalized.add(stage);
      }
    }

    if (normalized.isEmpty) {
      final fallback = _normalizeStageName(user.assignedStage);
      if (fallback != null) {
        normalized.add(fallback);
      }
    }

    return normalized;
  }

  List<String> get _scopedUserMachines {
    final user = ref.read(authProvider).user;
    if (user == null) return const <String>[];
    if (user.role != 'worker' && user.role != 'supervisor') {
      return const <String>[];
    }

    final machines = <String>[];
    for (final rawMachine in user.assignedMachines) {
      final machine = rawMachine.trim();
      if (machine.isNotEmpty && !machines.contains(machine)) {
        machines.add(machine);
      }
    }
    return machines;
  }

  String? get _lockedScopedStage {
    final stages = _scopedUserStages;
    return stages.length == 1 ? stages.first : null;
  }

  bool get _isScopedStageLocked => _lockedScopedStage != null;

  String _stageKey(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  String _valueKey(String value) => value.trim().toLowerCase();

  List<String> get _catalogStageOptions {
    final catalogStages = ref.read(catalogProvider).stageNames;
    if (catalogStages.isNotEmpty) return catalogStages;
    return AppConstants.stages;
  }

  String? _normalizeStageName(String? rawStage) {
    if (rawStage == null) return null;
    final input = rawStage.trim();
    if (input.isEmpty) return null;

    final normalizedInput = _stageKey(input);
    final stageCandidates = <String>[
      ..._catalogStageOptions,
      ...AppConstants.stages,
    ];
    final seen = <String>{};
    for (final stage in stageCandidates) {
      final key = _stageKey(stage);
      if (!seen.add(key)) continue;
      if (_stageKey(stage) == normalizedInput) {
        return stage;
      }
    }
    return input;
  }

  void _syncStageWithAssignedScope() {
    final lockedStage = _lockedScopedStage;
    if (lockedStage != null) {
      if (_selectedStage != lockedStage) {
        _applyStageSelection(lockedStage);
      }
      return;
    }

    final scopedStages = _scopedUserStages;
    if (scopedStages.isEmpty) return;
    if (_selectedStage == null || !scopedStages.contains(_selectedStage)) {
      _applyStageSelection(scopedStages.first);
    }
  }

  void _applyStageSelection(String? stage) {
    setState(() {
      _selectedStage = stage;
      _selectedMachine = null;
      _selectedPattern = null;
      _selectedPatternName = null;
      if (!_stageSupportsQuality(stage)) {
        _qualityClass = '1.kalite';
      }
    });
  }

  Future<void> _checkConnectivity() async {
    final networkInfo = NetworkInfo();
    final online = await networkInfo.isConnected;
    if (mounted) setState(() => _isOnline = online);
  }

  void _listenConnectivity() {
    final networkInfo = NetworkInfo();
    _connectivitySub =
        networkInfo.onConnectionStatusChanged.listen((connected) {
      if (mounted && connected != _isOnline) {
        setState(() => _isOnline = connected);
      }
    });
  }

  Future<void> _refreshPageData() async {
    _syncStageWithAssignedScope();
    await Future.wait([
      _checkConnectivity(),
      ref.read(catalogProvider.notifier).loadAll(),
    ]);
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
  void dispose() {
    _connectivitySub?.cancel();
    _quantityController.dispose();
    _notesController.dispose();
    _manualProductNameController.dispose();
    _manualProductCodeController.dispose();
    super.dispose();
  }

  int get _quantity => int.tryParse(_quantityController.text) ?? 0;

  bool get _isWorkerOutOfShift {
    final user = ref.read(authProvider).user;
    if (user == null || user.role != 'worker') return false;
    final assignedShift = user.assignedShift.trim();
    if (assignedShift.isEmpty) return true;
    return !isUserInShift(assignedShift);
  }

  String get _workerShiftRestrictionMessage =>
      'Vardiya süresi sona erdi. Şu anda kayıt oluşturamaz veya güncelleyemezsiniz.';

  void _incrementQuantity() {
    final current = _quantity;
    if (current < 9999) {
      _quantityController.text = '${current + 1}';
      setState(() {});
    }
  }

  void _decrementQuantity() {
    final current = _quantity;
    if (current > 0) {
      _quantityController.text = '${current - 1}';
      setState(() {});
    }
  }

  List<String> get _availableMachines {
    if (_selectedStage == null) return [];
    final catalog = ref.read(catalogProvider);
    final catalogMachines = catalog.machinesForStage(_selectedStage!);
    final allStageMachines = catalogMachines.isNotEmpty
        ? catalogMachines
        : (AppConstants.machinesPerStage[_selectedStage!] ?? const <String>[]);

    final scopedMachines = _scopedUserMachines;
    if (scopedMachines.isEmpty) return allStageMachines;

    final scopedMachineKeys = scopedMachines.map(_valueKey).toSet();
    return allStageMachines
        .where((machine) => scopedMachineKeys.contains(_valueKey(machine)))
        .toList();
  }

  List<Map<String, dynamic>> get _patterns {
    final catalog = ref.read(catalogProvider);
    return catalog.patterns.where((p) => p['is_active'] != false).toList();
  }

  List<Map<String, dynamic>> get _products {
    final catalog = ref.read(catalogProvider);
    return catalog.products.where((p) => p['is_active'] != false).toList();
  }

  bool get _isManualProductEntry => !_isOnline && _products.isEmpty;

  Future<void> _handleSubmit() async {
    if (_isWorkerOutOfShift) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_workerShiftRestrictionMessage),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_isManualProductEntry) {
      _selectedProductName = _manualProductNameController.text.trim();
      _selectedProductCode = _manualProductCodeController.text.trim();
    }

    if (_selectedStage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Lütfen üretim aşaması seçin'),
            backgroundColor: AppColors.error),
      );
      return;
    }
    if (_stageHasMachines && _selectedMachine == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Lütfen makine / hat seçin'),
            backgroundColor: AppColors.error),
      );
      return;
    }
    if ((_selectedProductName ?? '').trim().isEmpty ||
        (_selectedProductCode ?? '').trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Lütfen ürün bilgilerini doldurun'),
            backgroundColor: AppColors.error),
      );
      return;
    }
    if (_quantity == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Adet 0 olamaz'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final notesText = _notesController.text.trim();
    final qualityLevel =
        _stageHasQuality ? _qualityLevelFromLabel(_qualityClass) : null;

    try {
      final user = ref.read(authProvider).user;
      final success =
          await ref.read(productionEntryProvider.notifier).createEntry(
                productCode: _selectedProductCode!,
                productName: _selectedProductName!,
                patternCode: _selectedPattern,
                machine: _selectedMachine,
                quantity: _quantity,
                stage: _selectedStage!,
                userId: user?.id ?? '',
                userName: user?.name,
                quality: qualityLevel,
                notes: notesText.isEmpty ? null : notesText,
              );

      if (mounted) {
        setState(() => _isSubmitting = false);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Üretim kaydı oluşturuldu'),
                backgroundColor: AppColors.success),
          );
          _clearForm();
        } else {
          final errorMsg = ref.read(productionEntryProvider).errorMessage ??
              'Bir hata oluştu';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMsg), backgroundColor: AppColors.error),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _clearForm() {
    _quantityController.text = '0';
    _notesController.clear();
    _manualProductNameController.clear();
    _manualProductCodeController.clear();
    final lockedStage = _lockedScopedStage;
    final scopedStages = _scopedUserStages;
    setState(() {
      _selectedPattern = null;
      _selectedPatternName = null;
      _selectedProductName = null;
      _selectedProductCode = null;
      _selectedStage =
          lockedStage ?? (scopedStages.isNotEmpty ? scopedStages.first : null);
      _selectedMachine = null;
      _qualityClass = '1.kalite';
    });
  }

  // ── Stage-based form helpers ──

  static const _noMachineStages = {'Kalite Kontrol', 'Paketleme'};
  static const _noPatternStages = {'Paketleme'};
  static const _qualityStages = {
    'Eskilandirma',
    'Press',
    'Torna',
    'Dek Press',
    'Run Press',
    'Sirlama',
    'Dijital',
    'Firin',
    'Kalite Kontrol',
    'Sevkiyat',
  };

  bool _stageSupportsMachines(String? stage) =>
      stage != null && !_noMachineStages.contains(stage);

  bool _stageSupportsPatterns(String? stage) =>
      stage != null && !_noPatternStages.contains(stage);

  bool _stageSupportsQuality(String? stage) =>
      stage != null && _qualityStages.contains(stage);

  bool get _stageHasMachines => _stageSupportsMachines(_selectedStage);

  bool get _stageHasPatterns => _stageSupportsPatterns(_selectedStage);

  bool get _stageHasQuality => _stageSupportsQuality(_selectedStage);

  int? _qualityLevelFromLabel(String? label) {
    switch (label?.trim().toLowerCase()) {
      case '1.kalite':
      case '1. kalite':
      case 'birinci kalite':
        return 1;
      case '2.kalite':
      case '2. kalite':
      case 'ikinci kalite':
        return 2;
      case '3.kalite':
      case '3. kalite':
      case 'üçüncü kalite':
      case 'ucuncu kalite':
        return 3;
      case 'endüstriyel':
      case 'endustriyel':
      case 'industrial':
        return 4;
      default:
        return null;
    }
  }

  String get _stageQuantityLabel {
    switch (_selectedStage) {
      case 'Paketleme':
        return 'Adet (Koli)';
      case 'Sevkiyat':
        return 'Adet (Palet)';
      default:
        return 'Adet';
    }
  }

  String _getSectionTitle() {
    switch (_selectedStage) {
      case 'Kalite Kontrol':
        return 'KALİTE KONTROL DETAYLARI';
      case 'Paketleme':
        return 'PAKETLEME DETAYLARI';
      case 'Sevkiyat':
        return 'SEVKİYAT DETAYLARI';
      default:
        return 'ÜRETİM DETAYLARI';
    }
  }

  String get _notesHint {
    switch (_selectedStage) {
      case 'Kalite Kontrol':
        return 'Kontrol sonuçlarını, hata detaylarını yazın…';
      case 'Paketleme':
        return 'Koli / ambalaj bilgileri…';
      case 'Sevkiyat':
        return 'Araç plakası, teslimat notu…';
      case 'Firin':
        return 'Fırın sıcaklığı, pişirme süresi…';
      default:
        return 'Varsa not ekleyin…';
    }
  }

  Widget _buildStageHint() {
    IconData icon;
    String hint;
    Color color;
    switch (_selectedStage) {
      case 'Kalite Kontrol':
        icon = Icons.verified_outlined;
        hint = 'Kalite kontrol aşaması — ürün ve sınıf bilgisi gereklidir';
        color = AppColors.info;
        break;
      case 'Paketleme':
        icon = Icons.inventory_2_outlined;
        hint = 'Paketleme aşaması — koli adedini girin';
        color = AppColors.accent;
        break;
      case 'Sevkiyat':
        icon = Icons.local_shipping_outlined;
        hint = 'Sevkiyat aşaması — palet adedini ve bilgileri girin';
        color = AppColors.success;
        break;
      default:
        icon = Icons.precision_manufacturing_outlined;
        hint = 'Üretim aşaması — makine, ürün ve adet bilgisi girin';
        color = AppColors.primary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(hint,
                style: AppTypography.bodySmall
                    .copyWith(color: color, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesField() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: _notesController,
        maxLines: 3,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          hintText: _notesHint,
          hintStyle:
              AppTypography.bodyMedium.copyWith(color: AppColors.textHint),
        ),
        style: AppTypography.bodyMedium,
      ),
    );
  }

  void _showPatternPicker() {
    final patterns = _patterns;
    String searchQuery = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final filtered = searchQuery.isEmpty
              ? patterns
              : patterns.where((p) {
                  final name = (p['name'] ?? '').toString().toLowerCase();
                  final code = (p['code'] ?? '').toString().toLowerCase();
                  return name.contains(searchQuery.toLowerCase()) ||
                      code.contains(searchQuery.toLowerCase());
                }).toList();

          return Container(
            height: MediaQuery.of(ctx).size.height * 0.85,
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
                        child: Text('Desen Seçimi',
                            style: AppTypography.headlineSmall
                                .copyWith(fontWeight: FontWeight.w700)),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                // Search
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    onChanged: (v) => setSheetState(() => searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Desen ara...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      filled: true,
                      fillColor: AppColors.surfaceVariant,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                // Grid
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Text('Desen bulunamadı',
                              style: AppTypography.bodyMedium
                                  .copyWith(color: AppColors.textHint)))
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.85,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (ctx, i) {
                            final pattern = filtered[i];
                            final code = pattern['code'] ?? '';
                            final name = pattern['name'] ?? '';
                            final imageUrl = _patternImageUrl(pattern);
                            final isSelected = _selectedPattern == code;

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedPattern = code;
                                  _selectedPatternName = name;
                                });
                                Navigator.pop(ctx);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.border,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    // Pattern image placeholder
                                    Expanded(
                                      child: Container(
                                        width: double.infinity,
                                        decoration: const BoxDecoration(
                                          color: AppColors.surfaceVariant,
                                          borderRadius: BorderRadius.vertical(
                                              top: Radius.circular(7)),
                                        ),
                                        child: ClipRRect(
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                  top: Radius.circular(7)),
                                          child: _buildPatternImage(
                                            imageUrl,
                                            iconSize: 40,
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Info
                                    Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(code,
                                              style: AppTypography.titleMedium
                                                  .copyWith(
                                                      fontWeight:
                                                          FontWeight.w700),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis),
                                          const SizedBox(height: 2),
                                          Text(name,
                                              style: AppTypography.bodySmall
                                                  .copyWith(
                                                      color: AppColors
                                                          .textSecondary),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis),
                                        ],
                                      ),
                                    ),
                                    if (isSelected)
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 4),
                                        decoration: const BoxDecoration(
                                          color: AppColors.primary,
                                          borderRadius: BorderRadius.vertical(
                                              bottom: Radius.circular(7)),
                                        ),
                                        child: const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.check,
                                                color: Colors.white, size: 16),
                                            SizedBox(width: 4),
                                            Text('Seçildi',
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight:
                                                        FontWeight.w600)),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
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
      return File.fromUri(uri);
    }
    return File(imageRef);
  }

  Widget _buildPatternPlaceholder(double iconSize) {
    return Center(
      child: Icon(
        Icons.grid_view,
        size: iconSize,
        color: AppColors.textHint.withValues(alpha: 0.4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final refreshToken =
        ref.watch(pageRefreshTokenProvider(AppPageIds.entryForm));
    _consumeRefreshToken(refreshToken);

    ref.watch(catalogProvider);
    final syncState = ref.watch(syncProvider);
    final lockedStage = _lockedScopedStage;
    final scopedStages = _scopedUserStages;

    if (lockedStage != null && _selectedStage != lockedStage) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _selectedStage != lockedStage) {
          _applyStageSelection(lockedStage);
        }
      });
    } else if (lockedStage == null &&
        scopedStages.isNotEmpty &&
        (_selectedStage == null || !scopedStages.contains(_selectedStage))) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            (_selectedStage == null ||
                !scopedStages.contains(_selectedStage))) {
          _applyStageSelection(scopedStages.first);
        }
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: LoadingOverlay(
        isLoading: _isSubmitting,
        child: SafeArea(
          child: Column(
            children: [
              // App bar matching Stitch
              _buildTopBar(syncState),
              if (!_isOnline) _buildOfflineBanner(),
              if (_isWorkerOutOfShift) _buildShiftEndedBanner(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await Future.wait([
                      _checkConnectivity(),
                      ref.read(catalogProvider.notifier).loadAll(),
                    ]);
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 16),
                        // ── Section 1: AŞAMA SEÇİMİ ──
                        _buildNumberedSectionHeader(1, 'AŞAMA SEÇİMİ'),
                        const SizedBox(height: 12),
                        Text('Üretim Aşaması',
                            style: AppTypography.bodySmall
                                .copyWith(color: AppColors.textSecondary)),
                        const SizedBox(height: 6),
                        _buildStageDropdown(),
                        if (_isScopedStageLocked) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Bu kullanıcı için aşama seçimi kilitli',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textHint,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        // Stage hint
                        if (_selectedStage != null) ...[
                          const SizedBox(height: 8),
                          _buildStageHint(),
                        ],
                        const SizedBox(height: 20),
                        const Divider(height: 1),
                        const SizedBox(height: 20),
                        // ── Section 2: ÜRETİM DETAYLARI ──
                        Row(
                          children: [
                            _buildNumberedSectionHeader(2, _getSectionTitle()),
                            const Spacer(),
                            if (_stageHasPatterns)
                              GestureDetector(
                                onTap: _showPatternPicker,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.grid_view,
                                          color: AppColors.primary, size: 16),
                                      const SizedBox(width: 6),
                                      Text('Desen Seçimi',
                                          style: AppTypography.bodySmall
                                              .copyWith(
                                                  color: AppColors.primary,
                                                  fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Machine / Line — only show when stage has machines
                        if (_stageHasMachines) ...[
                          Text('Makine / Hat',
                              style: AppTypography.bodySmall
                                  .copyWith(color: AppColors.textSecondary)),
                          const SizedBox(height: 6),
                          if (_availableMachines.isNotEmpty)
                            _buildDropdownField(
                              label: '',
                              value: _selectedMachine,
                              items: _availableMachines,
                              onChanged: (v) =>
                                  setState(() => _selectedMachine = v),
                            )
                          else
                            _buildDropdownField(
                              label: 'Önce aşama seçin',
                              value: null,
                              items: const [],
                              onChanged: (_) {},
                            ),
                          const SizedBox(height: 16),
                        ],
                        // Product name
                        Text('Ürün Adı',
                            style: AppTypography.bodySmall
                                .copyWith(color: AppColors.textSecondary)),
                        const SizedBox(height: 6),
                        _buildProductFields(),
                        const SizedBox(height: 16),
                        // Quantity
                        Text(_stageQuantityLabel,
                            style: AppTypography.bodySmall
                                .copyWith(color: AppColors.textSecondary)),
                        const SizedBox(height: 6),
                        _buildQuantityRow(),
                        const SizedBox(height: 16),
                        // Quality class — show for production & QC stages
                        if (_stageHasQuality) ...[
                          _buildQualitySelector(),
                          const SizedBox(height: 16),
                        ],
                        // Notes field — stage-specific placeholder
                        Text('Notlar',
                            style: AppTypography.bodySmall
                                .copyWith(color: AppColors.textSecondary)),
                        const SizedBox(height: 6),
                        _buildNotesField(),
                        const SizedBox(height: 16),
                        // Selected pattern preview
                        if (_selectedPattern != null && _stageHasPatterns) ...[
                          _buildPatternPreview(),
                          const SizedBox(height: 16),
                        ],
                        // Temizle / Kaydet
                        _buildBottomButtons(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(SyncState syncState) {
    return UnifiedTopBar(
      title: 'Üretim Girişi',
      isSyncing: syncState.isSyncing,
      isOnline: _isOnline,
      pendingCount: syncState.pendingCount,
      failedCount: syncState.failedCount,
      onProfileTap: () => showAccountPanel(context, ref),
    );
  }

  Widget _buildNumberedSectionHeader(int number, String title) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text('$number',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14)),
          ),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5)),
      ],
    );
  }

  Widget _buildStageDropdown() {
    final scopedStages = _scopedUserStages;
    final lockedStage = _lockedScopedStage;
    final stageItems =
        scopedStages.isNotEmpty ? scopedStages : _catalogStageOptions;

    return PremiumDropdown<String>(
      labelText: null,
      placeholderText: 'Aşama seçin',
      searchHintText: 'Aşama ara...',
      emptyText: 'Aşama bulunamadı',
      value: _selectedStage ?? lockedStage,
      enabled: !_isScopedStageLocked,
      leadingIcon: _isScopedStageLocked ? Icons.lock_outline : Icons.layers,
      options: stageItems
          .map(
            (stage) => PremiumDropdownOption<String>(
              value: stage,
              title: stage,
              subtitle: _stageSubtitle(stage),
            ),
          )
          .toList(),
      onChanged: _isScopedStageLocked ? null : _applyStageSelection,
    );
  }

  String _stageSubtitle(String stage) {
    switch (stage) {
      case 'Kalite Kontrol':
        return 'Kontrol ve sınıflandırma süreci';
      case 'Paketleme':
        return 'Paketleme ve koli işlemleri';
      case 'Sevkiyat':
        return 'Sevkiyat ve transfer süreci';
      default:
        return 'Üretim operasyon aşaması';
    }
  }

  String _machineSubtitle(String machine) {
    final parts = machine.split('-');
    if (parts.length < 2) return 'Makine / Hat';
    final line = parts.last.trim();
    return 'Hat $line';
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final hasItems = items.isNotEmpty;
    return PremiumDropdown<String>(
      labelText: label,
      placeholderText: label,
      searchHintText: '$label ara...',
      emptyText: 'Sonuç bulunamadı',
      value: value,
      enabled: hasItems,
      leadingIcon: Icons.precision_manufacturing_rounded,
      options: items
          .map(
            (item) => PremiumDropdownOption<String>(
              value: item,
              title: item,
              subtitle: _machineSubtitle(item),
            ),
          )
          .toList(),
      onChanged: hasItems ? (selected) => onChanged(selected) : null,
    );
  }

  Widget _buildProductFields() {
    final products = _products;
    if (_isManualProductEntry) {
      return Column(
        children: [
          TextFormField(
            controller: _manualProductNameController,
            decoration: InputDecoration(
              hintText: 'Ürün Adı',
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
            onChanged: (value) => _selectedProductName = value.trim(),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _manualProductCodeController,
            decoration: InputDecoration(
              hintText: 'Ürün Kodu',
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
            onChanged: (value) => _selectedProductCode = value.trim(),
          ),
        ],
      );
    }

    return Column(
      children: [
        PremiumDropdown<String>(
          labelText: null,
          placeholderText: 'Ürün adı seçin',
          searchHintText: 'Ürün adı ara...',
          emptyText: 'Ürün bulunamadı',
          value: _selectedProductName,
          showSearch: true,
          leadingIcon: Icons.inventory_2_outlined,
          options: products
              .map(
                (product) => PremiumDropdownOption<String>(
                  value: (product['name'] ?? '').toString(),
                  title: (product['name'] ?? '').toString(),
                  subtitle: (product['code'] ?? '').toString(),
                ),
              )
              .where((option) => option.title.trim().isNotEmpty)
              .toList(),
          onChanged: (selectedName) {
            final product = products.firstWhere(
              (p) => (p['name'] ?? '').toString() == selectedName,
              orElse: () => <String, dynamic>{},
            );
            setState(() {
              _selectedProductName = selectedName;
              final code = (product['code'] ?? '').toString().trim();
              _selectedProductCode = code.isEmpty ? null : code;
            });
          },
        ),
        const SizedBox(height: 12),
        // Product Code (read-only, auto-filled)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            _selectedProductCode ?? 'Ürün Kodu',
            style: AppTypography.bodyMedium.copyWith(
              color: _selectedProductCode != null
                  ? AppColors.textPrimary
                  : AppColors.textHint,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuantityRow() {
    return Row(
      children: [
        // Minus button
        GestureDetector(
          onTap: _decrementQuantity,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.remove,
                color: AppColors.textPrimary, size: 22),
          ),
        ),
        const SizedBox(width: 8),
        // Value
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Center(
              child: TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textAlign: TextAlign.center,
                style: AppTypography.headlineSmall
                    .copyWith(fontWeight: FontWeight.w700),
                decoration: const InputDecoration(
                    border: InputBorder.none, contentPadding: EdgeInsets.zero),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Plus button
        GestureDetector(
          onTap: _incrementQuantity,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 22),
          ),
        ),
      ],
    );
  }

  Widget _buildQualitySelector() {
    const qualities = ['1.kalite', '2.kalite', '3.kalite', 'Endüstriyel'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Kalite Sınıfı',
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Row(
          children: qualities.map((q) {
            final isSelected = _qualityClass == q;
            return Padding(
              padding: EdgeInsets.only(right: q != qualities.last ? 8 : 0),
              child: GestureDetector(
                onTap: () => setState(() => _qualityClass = q),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.transparent : AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    q,
                    style: AppTypography.bodySmall.copyWith(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPatternPreview() {
    Map<String, dynamic>? selectedPattern;
    for (final pattern in _patterns) {
      if ((pattern['code'] ?? '').toString() == (_selectedPattern ?? '')) {
        selectedPattern = pattern;
        break;
      }
    }
    final imageUrl = _patternImageUrl(selectedPattern);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('SEÇİLİ DESEN ÖNİZLEME',
                  style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textHint,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5)),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() {
                  _selectedPattern = null;
                  _selectedPatternName = null;
                }),
                child: Text('Kaldır',
                    style: AppTypography.bodySmall.copyWith(
                        color: AppColors.primary, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _buildPatternImage(imageUrl),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_selectedPattern ?? '',
                        style: AppTypography.titleMedium
                            .copyWith(fontWeight: FontWeight.w700)),
                    if (_selectedPatternName != null)
                      Text('Varyant: $_selectedPatternName',
                          style: AppTypography.bodySmall
                              .copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 52,
            child: OutlinedButton(
              onPressed: _clearForm,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('Temizle',
                  style: AppTypography.button.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed:
                  (_isSubmitting || _isWorkerOutOfShift) ? null : _handleSubmit,
              icon: const Icon(Icons.save, color: Colors.white, size: 20),
              label: Text('Kaydet',
                  style: AppTypography.button.copyWith(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShiftEndedBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: AppColors.error.withValues(alpha: 0.08),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_clock, size: 16, color: AppColors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _workerShiftRestrictionMessage,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: AppColors.warningLight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off, size: 16, color: AppColors.warningDark),
          const SizedBox(width: 8),
          Text('Çevrimdışı — veriler yerel olarak kaydediliyor',
              style: AppTypography.bodySmall.copyWith(
                  color: AppColors.warningDark, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
