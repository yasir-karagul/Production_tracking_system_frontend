import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/shift_utils.dart';
import '../../providers/auth_provider.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/entry_providers.dart';
import '../../widgets/account_panel.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/premium_dropdown.dart';

class ShipmentEntryScreen extends ConsumerStatefulWidget {
  const ShipmentEntryScreen({super.key});

  @override
  ConsumerState<ShipmentEntryScreen> createState() =>
      _ShipmentEntryScreenState();
}

class _ShipmentEntryScreenState extends ConsumerState<ShipmentEntryScreen> {
  final _quantityController = TextEditingController(text: '0');
  final _destinationController = TextEditingController();
  bool _isSubmitting = false;

  String? _selectedProductType;
  String? _selectedProductShape;
  String? _selectedPatternCode;

  final _productTypes = const ['Tabak', 'Kase', 'Kupa', 'Fincan', 'Vazo'];
  final _productShapes = const [
    'Yuvarlak 20cm',
    'Yuvarlak 25cm',
    'Kare 15cm',
    'Kare 20cm',
    'Silindir'
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(catalogProvider.notifier).loadAll());
  }

  int get _quantity => int.tryParse(_quantityController.text) ?? 0;

  void _incrementQuantity() {
    if (_quantity < 9999) {
      _quantityController.text = '${_quantity + 1}';
      setState(() {});
    }
  }

  void _decrementQuantity() {
    if (_quantity > 0) {
      _quantityController.text = '${_quantity - 1}';
      setState(() {});
    }
  }

  Future<void> _handleSubmit() async {
    if (_selectedProductType == null || _selectedProductShape == null) {
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
    if (_destinationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Lütfen hedef adresi girin'),
            backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final user = ref.read(authProvider).user;
    try {
      final success =
          await ref.read(shipmentEntryProvider.notifier).createEntry(
                productCode: _selectedProductShape!,
                productName: _selectedProductType!,
                patternCode: _selectedPatternCode,
                quantity: _quantity,
                destination: _destinationController.text.trim(),
                userId: user?.id ?? '',
                userName: user?.name,
              );

      if (mounted) {
        setState(() => _isSubmitting = false);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Sevkiyat kaydı oluşturuldu'),
                backgroundColor: AppColors.success),
          );
          _clearForm();
        } else {
          final err =
              ref.read(shipmentEntryProvider).errorMessage ?? 'Bir hata oluştu';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(err), backgroundColor: AppColors.error),
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
    _destinationController.clear();
    setState(() {
      _selectedProductType = null;
      _selectedProductShape = null;
      _selectedPatternCode = null;
    });
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentShift = getCurrentShift();
    final shipmentState = ref.watch(shipmentEntryProvider);
    final catalogState = ref.watch(catalogProvider);
    final patternOptions = catalogState.patterns
        .where((item) => (item['is_active'] as bool?) != false)
        .map(
          (item) => {
            'code': (item['code'] ?? '').toString().trim(),
            'name': (item['name'] ?? '').toString().trim(),
          },
        )
        .where((item) => (item['code'] ?? '').toString().isNotEmpty)
        .toList()
      ..sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));
    final syncState = ref.watch(syncProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: LoadingOverlay(
        isLoading: _isSubmitting,
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(syncState),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.schedule,
                                color: AppColors.accent, size: 18),
                            const SizedBox(width: 8),
                            Text(
                                '$currentShift (${getShiftTimeRange(currentShift)})',
                                style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.w600)),
                            const Spacer(),
                            Text(
                                DateFormat('dd/MM HH:mm')
                                    .format(DateTime.now()),
                                style: AppTypography.bodySmall
                                    .copyWith(color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      _buildDropdown(
                          'Ürün Türü',
                          _selectedProductType,
                          _productTypes,
                          (v) => setState(() => _selectedProductType = v)),
                      const SizedBox(height: 12),

                      _buildDropdown(
                          'Ürün Şekli',
                          _selectedProductShape,
                          _productShapes,
                          (v) => setState(() => _selectedProductShape = v)),
                      const SizedBox(height: 12),
                      _buildPatternDropdown(patternOptions),
                      const SizedBox(height: 12),

                      // Destination
                      Text('Hedef / Müşteri',
                          style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary, fontSize: 13)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _destinationController,
                        decoration: InputDecoration(
                          hintText: 'Sevkiyat hedefi girin...',
                          hintStyle: AppTypography.bodyMedium
                              .copyWith(color: AppColors.textHint),
                          prefixIcon: const Icon(Icons.place_outlined,
                              color: AppColors.textHint, size: 20),
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: AppColors.border)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: AppColors.border)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: AppColors.accent, width: 1.5)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 12),

                      _buildQuantitySection(),
                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _isSubmitting ? null : _handleSubmit,
                          icon: const Icon(Icons.save_outlined,
                              color: Colors.white, size: 20),
                          label: Text('KAYDET',
                              style: AppTypography.button.copyWith(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.0)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      _buildTodayRecords(shipmentState),
                      const SizedBox(height: 20),
                    ],
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
      title: 'Sevkiyat',
      isSyncing: syncState.isSyncing,
      isOnline: true,
      pendingCount: syncState.pendingCount,
      failedCount: syncState.failedCount,
      onProfileTap: () => showAccountPanel(context, ref),
    );
  }

  Widget _buildDropdown(String label, String? value, List<String> items,
      ValueChanged<String?> onChanged) {
    final hasItems = items.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 6),
        PremiumDropdown<String>(
          labelText: label,
          placeholderText: 'Seçiniz',
          searchHintText: '$label ara...',
          emptyText: 'Sonuç bulunamadı',
          value: value,
          enabled: hasItems,
          leadingIcon: Icons.keyboard_arrow_down_rounded,
          options: items
              .map((item) => PremiumDropdownOption<String>(
                    value: item,
                    title: item,
                  ))
              .toList(),
          onChanged: hasItems ? (selected) => onChanged(selected) : null,
        ),
      ],
    );
  }

  Widget _buildPatternDropdown(List<Map<String, String>> options) {
    final hasItems = options.isNotEmpty;
    final selected = _selectedPatternCode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Desen',
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 6),
        PremiumDropdown<String>(
          labelText: 'Desen (İsteğe Bağlı)',
          placeholderText: hasItems ? 'Desen seçiniz' : 'Desen bulunamadı',
          searchHintText: 'Desen ara...',
          emptyText: 'Sonuç bulunamadı',
          value: selected,
          enabled: hasItems,
          leadingIcon: Icons.grid_view_rounded,
          showSearch: true,
          options: options
              .map(
                (item) => PremiumDropdownOption<String>(
                  value: item['code'] ?? '',
                  title: (item['name'] ?? '').isNotEmpty
                      ? '${item['name']} (${item['code']})'
                      : (item['code'] ?? ''),
                ),
              )
              .where((opt) => opt.value.isNotEmpty)
              .toList(),
          onChanged: hasItems
              ? (value) => setState(() => _selectedPatternCode = value)
              : null,
        ),
      ],
    );
  }

  Widget _buildQuantitySection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text('SEVKİYAT ADEDİ',
              style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  letterSpacing: 1.0)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _decrementQuantity,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border)),
                  child: const Icon(Icons.remove,
                      color: AppColors.textPrimary, size: 22),
                ),
              ),
              const SizedBox(width: 20),
              SizedBox(
                width: 100,
                child: TextFormField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.center,
                  style: AppTypography.headlineLarge.copyWith(
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 20),
              GestureDetector(
                onTap: _incrementQuantity,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                      color: AppColors.accent, shape: BoxShape.circle),
                  child: const Icon(Icons.add, color: Colors.white, size: 22),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTodayRecords(ShipmentEntryListState state) {
    if (state.entries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12)),
        child: Center(
            child: Text('Bugün henüz sevkiyat kaydı yok',
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.textHint))),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Bugünkü Sevkiyat Kayıtları (${state.entries.length})',
            style: AppTypography.titleMedium
                .copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        ...state.entries.take(10).map((e) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_shipping,
                      color: AppColors.accent, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${e.productName} — ${e.productCode}',
                            style: AppTypography.bodyMedium
                                .copyWith(fontWeight: FontWeight.w600)),
                        Text('${e.destination} • Adet: ${e.quantity}',
                            style: AppTypography.bodySmall
                                .copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  Text(DateFormat('HH:mm').format(e.createdAt),
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textSecondary)),
                ],
              ),
            )),
      ],
    );
  }
}
