import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/network/network_info.dart';
import '../../../core/utils/excel_export_storage.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/entry_providers.dart';
import '../../providers/service_providers.dart';
import '../../widgets/account_panel.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/premium_dropdown.dart';

class PastReportsScreen extends ConsumerStatefulWidget {
  const PastReportsScreen({super.key});

  @override
  ConsumerState<PastReportsScreen> createState() => _PastReportsScreenState();
}

class _PastReportsScreenState extends ConsumerState<PastReportsScreen> {
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  String? _selectedSection;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _hasFiltered = false;
  bool _isExporting = false;
  bool _isOnline = true;

  final List<String> _sections = [
    'Tüm Bölümler',
    'Şekillendirme',
    'Kurutma',
    'Sırlama',
    'Fırın (Bisküvi)',
    'Fırın (Glaze)',
    'Kalite Kontrol',
  ];

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

  @override
  void dispose() {
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.accent),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          _startDateController.text = DateFormat('MM/dd/yyyy').format(picked);
        } else {
          _endDate = picked;
          _endDateController.text = DateFormat('MM/dd/yyyy').format(picked);
        }
      });
    }
  }

  void _handleFilter() {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen tarih aralığı seçin'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final startStr = DateFormat('yyyy-MM-dd').format(_startDate!);
    final endStr = DateFormat('yyyy-MM-dd').format(_endDate!);
    final shift = _selectedSection == 'Tüm Bölümler' || _selectedSection == null
        ? null
        : _selectedSection;

    ref.read(reportProvider.notifier).loadStageSummary(
          startDate: startStr,
          endDate: endStr,
          shift: shift,
        );

    setState(() => _hasFiltered = true);
  }

  Future<void> _handleExcelExport() async {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen tarih aralığı seçin'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isExporting = true);

    try {
      final startStr = DateFormat('yyyy-MM-dd').format(_startDate!);
      final endStr = DateFormat('yyyy-MM-dd').format(_endDate!);
      final shift =
          _selectedSection == 'Tüm Bölümler' || _selectedSection == null
              ? null
              : _selectedSection;

      final repo = ref.read(reportRepositoryProvider);
      final result = await repo.exportExcel(
        startDate: startStr,
        endDate: endStr,
        shift: shift,
      );

      result.fold(
        (failure) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text('Excel dışa aktarma başarısız: ${failure.message}'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        (bytes) async {
          try {
            final fileName =
                'uretim_raporu_${DateFormat('yyyyMMdd').format(_startDate!)}_${DateFormat('yyyyMMdd').format(_endDate!)}.xlsx';
            final exportedFile = await ExcelExportStorage.saveToDownloads(
              bytes: bytes,
              fileName: fileName,
            );

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Excel dosyası kaydedildi'),
                  backgroundColor: AppColors.success,
                  duration: const Duration(seconds: 5),
                  action: SnackBarAction(
                    label: 'AÇ',
                    textColor: Colors.white,
                    onPressed: () async {
                      final errorMessage =
                          await ExcelExportStorage.open(exportedFile);
                      if (errorMessage != null && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Dosya açılamadı: $errorMessage'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    },
                  ),
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Dosya kaydedilemedi: $e'),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          }
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bir hata oluştu: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportState = ref.watch(reportProvider);
    final syncState = ref.watch(syncProvider);

    // Build results from report data
    final results = <Map<String, dynamic>>[];
    if (_hasFiltered && reportState.data != null) {
      final items = reportState.data!['data'] as List<dynamic>? ?? [];
      for (var item in items) {
        results.add(item as Map<String, dynamic>);
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // AppBar
            _buildTopBar(syncState),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // Filter section
                    _buildFilterSection(),
                    const SizedBox(height: 20),

                    // Results
                    if (_hasFiltered) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Sonuçlar (${results.length})',
                            style: AppTypography.titleMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.sort,
                                  size: 16, color: AppColors.accent),
                              const SizedBox(width: 4),
                              Text(
                                'Sırala',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (reportState.isLoading)
                        const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (results.isEmpty)
                        _buildEmptyResults()
                      else
                        ...results.asMap().entries.map(
                              (entry) =>
                                  _buildReportCard(entry.key, entry.value),
                            ),
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

  Widget _buildTopBar(SyncState syncState) {
    return UnifiedTopBar(
      title: 'Geçmiş Raporlar',
      isSyncing: syncState.isSyncing,
      isOnline: _isOnline,
      pendingCount: syncState.pendingCount,
      failedCount: syncState.failedCount,
      onProfileTap: () => showAccountPanel(context, ref),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter header
          Row(
            children: [
              const Icon(Icons.filter_list,
                  size: 18, color: AppColors.textPrimary),
              const SizedBox(width: 8),
              Text(
                'FİLTRELE',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Date range row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Başlangıç',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () => _selectDate(true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.headerDark,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _startDateController.text.isEmpty
                              ? 'MM/DD/YYYY'
                              : _startDateController.text,
                          style: AppTypography.bodyMedium.copyWith(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bitiş',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () => _selectDate(false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.headerDark,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _endDateController.text.isEmpty
                              ? 'MM/DD/YYYY'
                              : _endDateController.text,
                          style: AppTypography.bodyMedium.copyWith(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Section dropdown
          Text(
            'Section',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          PremiumDropdown<String>(
            labelText: 'Bölüm',
            placeholderText: 'Tüm Bölümler',
            searchHintText: 'Bölüm ara...',
            emptyText: 'Sonuç bulunamadı',
            value: _selectedSection,
            options: _sections
                .map(
                  (section) => PremiumDropdownOption<String>(
                    value: section,
                    title: section,
                  ),
                )
                .toList(),
            onChanged: (selected) =>
                setState(() => _selectedSection = selected),
          ),
          const SizedBox(height: 16),

          // Filter button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _handleFilter,
              icon: const Icon(Icons.search, color: Colors.white, size: 20),
              label: Text(
                'FİLTRELE',
                style: AppTypography.button.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Excel export button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _isExporting ? null : _handleExcelExport,
              icon: _isExporting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.success),
                    )
                  : const Icon(Icons.download,
                      color: AppColors.success, size: 20),
              label: Text(
                _isExporting ? 'HAZIRLANIYOR...' : 'EXCEL OLARAK İNDİR',
                style: AppTypography.button.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.success, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyResults() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.inbox, size: 48, color: AppColors.textHint),
            const SizedBox(height: 12),
            Text(
              'Sonuç bulunamadı',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(int index, Map<String, dynamic> item) {
    final stageInfo = item['_id'] as Map<String, dynamic>? ?? {};
    final stageName = stageInfo['stage'] as String? ?? 'Section ${index + 1}';
    final qty = (item['totalQuantity'] as num?)?.toInt() ?? 0;
    final count = (item['count'] as num?)?.toInt() ?? 0;
    final day = (index + 5).toString().padLeft(2, '0');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date badge
          Container(
            width: 44,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  day,
                  style: AppTypography.titleLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'SUB',
                  style: AppTypography.labelSmall.copyWith(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stageName,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Rapor ID: #${8700 + index}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textHint,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.inventory_2_outlined,
                        size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      'MİKTAR',
                      style: AppTypography.labelSmall.copyWith(
                        fontSize: 10,
                        color: AppColors.textHint,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.local_shipping_outlined,
                        size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      'KAYIT',
                      style: AppTypography.labelSmall.copyWith(
                        fontSize: 10,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '$qty parça',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 24),
                    Text(
                      '$count kayıt',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textHint, size: 24),
        ],
      ),
    );
  }
}
