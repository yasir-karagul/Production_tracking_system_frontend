import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/network_info.dart';
import '../../../core/utils/excel_export_storage.dart';
import '../../../data/models/production_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/entry_providers.dart';
import '../../providers/production_provider.dart';
import '../../providers/service_providers.dart';
import '../../widgets/account_panel.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/premium_dropdown.dart';
import 'package:flutter/services.dart';

class DailyReportScreen extends ConsumerStatefulWidget {
  const DailyReportScreen({super.key});

  @override
  ConsumerState<DailyReportScreen> createState() => _DailyReportScreenState();
}

enum _DateTimeFilterMode {
  dateOnly,
  exactTime,
  timeRange,
}

class _DateTimeFilterConfig {
  final DateTime date;
  final _DateTimeFilterMode mode;
  final TimeOfDay? exactTime;
  final DateTime? rangeStartDate;
  final DateTime? rangeEndDate;
  final TimeOfDay? rangeStartTime;
  final TimeOfDay? rangeEndTime;

  const _DateTimeFilterConfig({
    required this.date,
    required this.mode,
    this.exactTime,
    this.rangeStartDate,
    this.rangeEndDate,
    this.rangeStartTime,
    this.rangeEndTime,
  });
}

class _MergedReportRow {
  final DateTime? createdAt;
  final String shift;
  final String machine;
  final String productCode;
  final String productName;
  final String designCode;
  final String quality;
  final int quantity;

  const _MergedReportRow({
    required this.createdAt,
    required this.shift,
    required this.machine,
    required this.productCode,
    required this.productName,
    required this.designCode,
    required this.quality,
    required this.quantity,
  });
}

class _GroupedSummaryRow {
  final String productName;
  final String designCode;
  final String quality;
  final int quantity;

  const _GroupedSummaryRow({
    required this.productName,
    required this.designCode,
    required this.quality,
    required this.quantity,
  });
}

class _DailyReportScreenState extends ConsumerState<DailyReportScreen> {
  static const int _businessDayStartHour = 1;
  static const String _allFilterOption = 'Tümü';
  static const List<String> _qualityFilterOrder = [
    '1.kalite',
    '2.kalite',
    '3.kalite',
    'Endüstriyel',
  ];

  bool _isOnline = true;
  bool _isExporting = false;
  bool _isGroupedExporting = false;
  bool _isMachineSummaryExporting = false;
  int _tablePage = 1;
  int _groupTablePage = 1;
  int _machineTablePage = 1;
  static const int _tablePageSize = 7;
  static const int _groupTablePageSize = 7;
  static const int _machineTablePageSize = 7;
  static const double _reportTableMinWidth = 1060;
  static const double _reportColDateWidth = 120;
  static const double _reportColShiftWidth = 90;
  static const double _reportColMachineWidth = 150;
  static const double _reportColProductCodeWidth = 120;
  static const double _reportColProductNameWidth = 230;
  static const double _reportColDesignCodeWidth = 120;
  static const double _reportColQualityWidth = 100;
  static const double _reportColQtyWidth = 110;
  static const double _machineSummaryColMachineWidth = 180;
  static const double _machineSummaryColProductWidth = 130;
  static const double _machineSummaryColTotalWidth = 130;
  static const double _groupColProductWidth = 160;
  static const double _groupColDesignWidth = 110;
  static const double _groupColQualityWidth = 100;
  static const double _groupColQtyWidth = 110;
  int _lastRefreshToken = -1;
  DateTime _selectedDate = DateTime.now();
  _DateTimeFilterMode _dateTimeFilterMode = _DateTimeFilterMode.dateOnly;
  TimeOfDay? _selectedExactTime;
  DateTime? _rangeStartDate;
  DateTime? _rangeEndDate;
  TimeOfDay? _rangeStartTime;
  TimeOfDay? _rangeEndTime;
  String _stageFilter = _allFilterOption;
  String _machineFilter = _allFilterOption;
  String _shiftFilter = _allFilterOption;
  String _productFilter = _allFilterOption;
  String _designCodeFilter = _allFilterOption;
  String _qualityFilter = _allFilterOption;

  @override
  void initState() {
    super.initState();
    _selectedDate = _businessDateOf(DateTime.now());
    _checkConnectivity();
  }

  DateTime _businessDateOf(DateTime dateTime) {
    final day = DateTime(dateTime.year, dateTime.month, dateTime.day);
    if (dateTime.hour < _businessDayStartHour) {
      return day.subtract(const Duration(days: 1));
    }
    return day;
  }

  Future<void> _checkConnectivity() async {
    final networkInfo = NetworkInfo();
    final online = await networkInfo.isConnected;
    if (mounted) setState(() => _isOnline = online);
  }

  Future<void> _loadData() async {
    final selectedRange = _selectedDateTimeRange;
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedRange.start);
    final startAt = selectedRange.start.toUtc().toIso8601String();
    final endAt = selectedRange.end.toUtc().toIso8601String();
    final shift = _shiftFilter == _allFilterOption ? null : _shiftFilter;
    await Future.wait([
      ref.read(dashboardProvider.notifier).loadDashboard(
            date: dateStr,
            shift: shift,
            startAt: startAt,
            endAt: endAt,
          ),
      ref.read(productionProvider.notifier).loadProductions(
            shift: shift,
            date: dateStr,
            startAt: startAt,
            endAt: endAt,
            limit: 200,
          ),
    ]);
  }

  Future<void> _refreshPageData() async {
    await _checkConnectivity();
    await _loadData();
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
        ref.watch(pageRefreshTokenProvider(AppPageIds.dailyReport));
    _consumeRefreshToken(refreshToken);

    final dashState = ref.watch(dashboardProvider);
    final productionState = ref.watch(productionProvider);
    final syncState = ref.watch(syncProvider);
    final user = ref.watch(authProvider).user;
    final showGroupedSummaryTable =
        user?.role == 'admin' || user?.role == 'supervisor';

    // Extract data
    final byStage = dashState.data?.byStage ?? [];
    final byShift = dashState.data?.byShift ?? [];
    final allProductions = productionState.productions;
    final reportDate = _dateTimeFilterLabel;
    final totalQuantity = _resolveStageTotalQuantity(byStage);
    final totalRecords = _resolveStageTotalRecords(byStage, allProductions);
    final stageOptions = [
      _allFilterOption,
      ...{
        ...AppConstants.stages,
        for (final item in allProductions)
          if (item.stage.trim().isNotEmpty) item.stage.trim(),
      }
    ];
    final machineOptions = _buildMachineOptions(allProductions);
    final effectiveMachineFilter = machineOptions.contains(_machineFilter)
        ? _machineFilter
        : _allFilterOption;
    if (_machineFilter != effectiveMachineFilter) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _machineFilter = effectiveMachineFilter;
          _tablePage = 1;
          _groupTablePage = 1;
          _machineTablePage = 1;
        });
      });
    }

    final shiftOptions = [
      _allFilterOption,
      ...{
        ...AppConstants.shifts,
        for (final item in allProductions)
          if (item.shift.trim().isNotEmpty) item.shift.trim(),
      }
    ];

    final productOptions = [
      _allFilterOption,
      ...{
        for (final item in allProductions)
          if (item.productName.trim().isNotEmpty) item.productName.trim(),
      }
    ];

    final designCodeOptions = [
      _allFilterOption,
      ...{
        for (final item in allProductions)
          if (item.designCode.trim().isNotEmpty) item.designCode.trim(),
      }
    ];

    final qualityOptions = [
      _allFilterOption,
      ..._qualityFilterOrder.where((quality) => allProductions.any(
            (item) => _extractQualityLabel(item) == quality,
          )),
      ...{
        for (final item in allProductions)
          if (_extractQualityLabel(item) != '-' &&
              !_qualityFilterOrder.contains(_extractQualityLabel(item)))
            _extractQualityLabel(item),
      }
    ];

    final filteredProductions = allProductions.where((item) {
      final stageOk =
          _stageFilter == _allFilterOption || item.stage == _stageFilter;
      final machineOk = effectiveMachineFilter == _allFilterOption ||
          (item.machine?.trim() ?? '') == effectiveMachineFilter;
      final shiftOk =
          _shiftFilter == _allFilterOption || item.shift == _shiftFilter;
      final productOk = _productFilter == _allFilterOption ||
          item.productName == _productFilter;
      final designOk = _designCodeFilter == _allFilterOption ||
          item.designCode.trim() == _designCodeFilter;
      final qualityOk = _qualityFilter == _allFilterOption ||
          _extractQualityLabel(item) == _qualityFilter;
      return stageOk &&
          machineOk &&
          shiftOk &&
          productOk &&
          designOk &&
          qualityOk;
    }).toList()
      ..sort((a, b) {
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
    final groupedSummaryRows = _buildGroupedSummaryRows(filteredProductions);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(syncState),
            Expanded(
              child: dashState.isLoading || productionState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 12),
                            _buildFilterRow(
                              stageOptions: stageOptions,
                              machineOptions: machineOptions,
                              shiftOptions: shiftOptions,
                              productOptions: productOptions,
                              designCodeOptions: designCodeOptions,
                              qualityOptions: qualityOptions,
                            ),
                            const SizedBox(height: 16),
                            _buildStatsCards(totalQuantity, totalRecords),
                            const SizedBox(height: 16),
                            _buildDailyEfficiency(byShift, reportDate),
                            const SizedBox(height: 20),
                            _buildProductionTable(filteredProductions),
                            const SizedBox(height: 16),
                            _buildMachineLineSummaryTable(filteredProductions),
                            if (showGroupedSummaryTable) ...[
                              const SizedBox(height: 16),
                              _buildGroupedSummaryTableSection(
                                groupedRows: groupedSummaryRows,
                              ),
                            ],
                            const SizedBox(height: 16),
                          ],
                        ),
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
      title: 'Raporlar',
      isSyncing: syncState.isSyncing,
      isOnline: _isOnline,
      pendingCount: syncState.pendingCount,
      failedCount: syncState.failedCount,
      onProfileTap: () => showAccountPanel(context, ref),
    );
  }

  Widget _buildFilterRow({
    required List<String> stageOptions,
    required List<String> machineOptions,
    required List<String> shiftOptions,
    required List<String> productOptions,
    required List<String> designCodeOptions,
    required List<String> qualityOptions,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columnCount = width >= 1200 ? 4 : (width >= 900 ? 3 : 2);
        const spacing = 8.0;
        final chipWidth = (width - (spacing * (columnCount - 1))) / columnCount;

        Widget item(Widget child) => SizedBox(width: chipWidth, child: child);

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            item(
              _buildActionFilterChip(
                'Tarih/Saat',
                _dateTimeFilterLabel,
                _showDateTimeFilterDialog,
              ),
            ),
            item(
              _buildSelectionFilterChip(
                'Aşama',
                _stageFilter,
                stageOptions,
                (v) {
                  setState(() {
                    _stageFilter = v;
                    _machineFilter = _allFilterOption;
                    _tablePage = 1;
                    _groupTablePage = 1;
                    _machineTablePage = 1;
                  });
                },
              ),
            ),
            item(
              _buildSelectionFilterChip(
                'Makine/Hat',
                _machineFilter,
                machineOptions,
                _stageFilter == _allFilterOption
                    ? null
                    : (v) {
                        setState(() {
                          _machineFilter = v;
                          _tablePage = 1;
                          _groupTablePage = 1;
                          _machineTablePage = 1;
                        });
                      },
              ),
            ),
            item(
              _buildSelectionFilterChip(
                'Vardiya',
                _shiftFilter,
                shiftOptions,
                (v) {
                  setState(() {
                    _shiftFilter = v;
                    _tablePage = 1;
                    _groupTablePage = 1;
                    _machineTablePage = 1;
                  });
                  _loadData();
                },
              ),
            ),
            item(
              _buildSelectionFilterChip(
                'Ürün',
                _productFilter,
                productOptions,
                (v) {
                  setState(() {
                    _productFilter = v;
                    _tablePage = 1;
                    _groupTablePage = 1;
                    _machineTablePage = 1;
                  });
                },
              ),
            ),
            item(
              _buildSelectionFilterChip(
                'Desen Kodu',
                _designCodeFilter,
                designCodeOptions,
                (v) {
                  setState(() {
                    _designCodeFilter = v;
                    _tablePage = 1;
                    _groupTablePage = 1;
                    _machineTablePage = 1;
                  });
                },
              ),
            ),
            item(
              _buildSelectionFilterChip(
                'Kalite',
                _qualityFilter,
                qualityOptions,
                (v) {
                  setState(() {
                    _qualityFilter = v;
                    _tablePage = 1;
                    _groupTablePage = 1;
                    _machineTablePage = 1;
                  });
                },
              ),
            ),
          ],
        );
      },
    );
  }

  DateTime get _selectedDayStart => DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _businessDayStartHour,
      );

  DateTime get _selectedDayEnd =>
      _selectedDayStart.add(const Duration(days: 1)).subtract(
            const Duration(microseconds: 1),
          );

  DateTime _combineDateAndTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  DateTimeRange get _selectedDateTimeRange {
    switch (_dateTimeFilterMode) {
      case _DateTimeFilterMode.dateOnly:
        return DateTimeRange(start: _selectedDayStart, end: _selectedDayEnd);
      case _DateTimeFilterMode.exactTime:
        final exactTime = _selectedExactTime;
        if (exactTime == null) {
          return DateTimeRange(start: _selectedDayStart, end: _selectedDayEnd);
        }
        // "Belirli Saat" filtresi seçilen dakikayı değil, seçilen saatin
        // tamamını (HH:00 - HH:59:59.999999) kapsamalıdır.
        final start = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          exactTime.hour,
        );
        final end = start
            .add(const Duration(hours: 1))
            .subtract(const Duration(microseconds: 1));
        return DateTimeRange(start: start, end: end);
      case _DateTimeFilterMode.timeRange:
        final rangeStartDate = _rangeStartDate;
        final rangeEndDate = _rangeEndDate;
        final rangeStartTime = _rangeStartTime;
        final rangeEndTime = _rangeEndTime;
        if (rangeStartDate == null ||
            rangeEndDate == null ||
            rangeStartTime == null ||
            rangeEndTime == null) {
          return DateTimeRange(start: _selectedDayStart, end: _selectedDayEnd);
        }
        final start = _combineDateAndTime(rangeStartDate, rangeStartTime);
        final end = _combineDateAndTime(rangeEndDate, rangeEndTime)
            .add(const Duration(minutes: 1))
            .subtract(const Duration(microseconds: 1));
        if (end.isBefore(start)) {
          return DateTimeRange(start: start, end: start);
        }
        return DateTimeRange(start: start, end: end);
    }
  }

  List<String> _excelStartEndDates(DateTimeRange range) {
    if (_dateTimeFilterMode == _DateTimeFilterMode.dateOnly) {
      final businessDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
      return [businessDate, businessDate];
    }
    return [
      DateFormat('yyyy-MM-dd').format(range.start),
      DateFormat('yyyy-MM-dd').format(range.end),
    ];
  }

  String _formatTimeOfDay(TimeOfDay? time) {
    if (time == null) return '--:--';
    final dt = DateTime(2000, 1, 1, time.hour, time.minute);
    return DateFormat('HH:mm').format(dt);
  }

  String get _dateTimeFilterLabel {
    final dateLabel = DateFormat('dd.MM.yyyy').format(_selectedDate);
    switch (_dateTimeFilterMode) {
      case _DateTimeFilterMode.dateOnly:
        return dateLabel;
      case _DateTimeFilterMode.exactTime:
        return '$dateLabel ${_formatTimeOfDay(_selectedExactTime)}';
      case _DateTimeFilterMode.timeRange:
        final rangeStartDate = _rangeStartDate;
        final rangeEndDate = _rangeEndDate;
        if (rangeStartDate == null || rangeEndDate == null) {
          return '$dateLabel ${_formatTimeOfDay(_rangeStartTime)} - ${_formatTimeOfDay(_rangeEndTime)}';
        }
        final startDateLabel = DateFormat('dd.MM.yyyy').format(rangeStartDate);
        final endDateLabel = DateFormat('dd.MM.yyyy').format(rangeEndDate);
        return '$startDateLabel ${_formatTimeOfDay(_rangeStartTime)} - $endDateLabel ${_formatTimeOfDay(_rangeEndTime)}';
    }
  }

  List<String> _buildMachineOptions(List<ProductionModel> allProductions) {
    if (_stageFilter == _allFilterOption) {
      return const [_allFilterOption];
    }

    final stageMachines = <String>{
      ...?AppConstants.machinesPerStage[_stageFilter],
      for (final item in allProductions)
        if (item.stage == _stageFilter &&
            item.machine != null &&
            item.machine!.trim().isNotEmpty)
          item.machine!.trim(),
    }.toList()
      ..sort();

    return [_allFilterOption, ...stageMachines];
  }

  String get _totalQuantityTitle => _stageFilter == _allFilterOption
      ? 'Toplam Üretim'
      : 'Toplam $_stageFilter';

  Widget _buildSelectionFilterChip(
    String label,
    String value,
    List<String> options,
    ValueChanged<String>? onChanged,
  ) {
    if (onChanged == null) {
      return _buildActionFilterChip(
        label,
        value,
        () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Önce aşama seçin'),
            ),
          );
        },
      );
    }
    return _buildActionFilterChip(
      label,
      value,
      () => _showSelectionDialog(
        label: label,
        value: value,
        options: options,
        onChanged: onChanged,
      ),
    );
  }

  Future<TimeOfDay?> _showCustom24HourPicker({
    required BuildContext context,
    required TimeOfDay initialTime,
  }) async {
    return showDialog<TimeOfDay>(
      context: context,
      builder: (dialogContext) {
        final hourController = TextEditingController(
          text: initialTime.hour.toString().padLeft(2, '0'),
        );
        final minuteController = TextEditingController(
          text: initialTime.minute.toString().padLeft(2, '0'),
        );

        String? errorText;

        int safeHour() => int.tryParse(hourController.text) ?? initialTime.hour;
        int safeMinute() =>
            int.tryParse(minuteController.text) ?? initialTime.minute;

        String twoDigits(int value) => value.toString().padLeft(2, '0');

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            void setHour(int value) {
              final normalized = (value % 24 + 24) % 24;
              hourController.text = twoDigits(normalized);
              hourController.selection = TextSelection.fromPosition(
                TextPosition(offset: hourController.text.length),
              );
              errorText = null;
              setStateDialog(() {});
            }

            void setMinute(int value) {
              final normalized = (value % 60 + 60) % 60;
              minuteController.text = twoDigits(normalized);
              minuteController.selection = TextSelection.fromPosition(
                TextPosition(offset: minuteController.text.length),
              );
              errorText = null;
              setStateDialog(() {});
            }

            void increaseHour() => setHour(safeHour() + 1);
            void decreaseHour() => setHour(safeHour() - 1);
            void increaseMinute() => setMinute(safeMinute() + 1);
            void decreaseMinute() => setMinute(safeMinute() - 1);

            void validateAndSubmit() {
              final hour = int.tryParse(hourController.text.trim());
              final minute = int.tryParse(minuteController.text.trim());

              final validHour = hour != null && hour >= 0 && hour <= 23;
              final validMinute = minute != null && minute >= 0 && minute <= 59;

              if (!validHour || !validMinute) {
                setStateDialog(() {
                  errorText = 'Saat 00-23 ve dakika 00-59 arasında olmalıdır';
                });
                return;
              }

              Navigator.of(dialogContext).pop(
                TimeOfDay(hour: hour, minute: minute),
              );
            }

            Widget timeColumn({
              required String label,
              required TextEditingController controller,
              required VoidCallback onPlus,
              required VoidCallback onMinus,
            }) {
              return Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: onPlus,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(
                          Icons.add,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 2,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(2),
                      ],
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: AppColors.primary.withValues(alpha: 0.08),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: AppColors.primary.withValues(alpha: 0.25),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: AppColors.primary.withValues(alpha: 0.25),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 1.2,
                          ),
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 14),
                      ),
                      style: AppTypography.headlineMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                      onChanged: (_) {
                        setStateDialog(() {
                          errorText = null;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: onMinus,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(
                          Icons.remove,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: Text(
                'Saat seçin',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      timeColumn(
                        label: 'Saat',
                        controller: hourController,
                        onPlus: increaseHour,
                        onMinus: decreaseHour,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          ':',
                          style: AppTypography.headlineLarge.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      timeColumn(
                        label: 'Dakika',
                        controller: minuteController,
                        onPlus: increaseMinute,
                        onMinus: decreaseMinute,
                      ),
                    ],
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      errorText!,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('İptal'),
                ),
                FilledButton(
                  onPressed: validateAndSubmit,
                  child: const Text('Tamam'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildActionFilterChip(
    String label,
    String value,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: AppTypography.labelSmall
                          .copyWith(color: AppColors.textHint, fontSize: 10)),
                  Text(value,
                      style: AppTypography.bodySmall
                          .copyWith(fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const Icon(Icons.expand_more,
                size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Future<void> _showSelectionDialog({
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String> onChanged,
  }) async {
    final selected = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            label,
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: ListView(
                shrinkWrap: true,
                children: options
                    .map(
                      (o) => ListTile(
                        title: Text(o, style: AppTypography.bodyMedium),
                        trailing: o == value
                            ? const Icon(Icons.check, color: AppColors.primary)
                            : null,
                        onTap: () => Navigator.of(dialogContext).pop(o),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Kapat'),
            ),
          ],
        );
      },
    );

    if (selected == null || selected == value) return;
    onChanged(selected);
  }

  Future<void> _showDateTimeFilterDialog() async {
    final config = await showDialog<_DateTimeFilterConfig>(
      context: context,
      builder: (dialogContext) {
        DateTime localDate = _selectedDate;
        _DateTimeFilterMode localMode = _dateTimeFilterMode;
        TimeOfDay? localExactTime = _selectedExactTime;
        DateTime localRangeStartDate = _rangeStartDate ?? _selectedDate;
        DateTime localRangeEndDate = _rangeEndDate ?? _selectedDate;
        TimeOfDay? localRangeStartTime = _rangeStartTime;
        TimeOfDay? localRangeEndTime = _rangeEndTime;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickDate() async {
              final picked = await showDatePicker(
                context: dialogContext,
                initialDate: localDate,
                firstDate: DateTime(2024),
                lastDate: _businessDateOf(DateTime.now()),
                locale: const Locale('tr', 'TR'),
              );
              if (picked != null) {
                setDialogState(() => localDate = picked);
              }
            }

            Future<void> pickRangeStartDate() async {
              final picked = await showDatePicker(
                context: dialogContext,
                initialDate: localRangeStartDate,
                firstDate: DateTime(2024),
                lastDate: _businessDateOf(DateTime.now()),
                locale: const Locale('tr', 'TR'),
              );
              if (picked != null) {
                setDialogState(() => localRangeStartDate = picked);
              }
            }

            Future<void> pickRangeEndDate() async {
              final picked = await showDatePicker(
                context: dialogContext,
                initialDate: localRangeEndDate,
                firstDate: DateTime(2024),
                lastDate: _businessDateOf(DateTime.now()),
                locale: const Locale('tr', 'TR'),
              );
              if (picked != null) {
                setDialogState(() => localRangeEndDate = picked);
              }
            }

            Future<void> pickExactTime() async {
              final picked = await _showCustom24HourPicker(
                context: dialogContext,
                initialTime: localExactTime ?? TimeOfDay.now(),
              );
              if (picked != null) {
                setDialogState(() => localExactTime = picked);
              }
            }

            Future<void> pickRangeStartTime() async {
              final picked = await _showCustom24HourPicker(
                context: dialogContext,
                initialTime: localRangeStartTime ?? TimeOfDay.now(),
              );
              if (picked != null) {
                setDialogState(() => localRangeStartTime = picked);
              }
            }

            Future<void> pickRangeEndTime() async {
              final picked = await _showCustom24HourPicker(
                context: dialogContext,
                initialTime: localRangeEndTime ?? TimeOfDay.now(),
              );
              if (picked != null) {
                setDialogState(() => localRangeEndTime = picked);
              }
            }

            return AlertDialog(
              title: Text(
                'Tarih/Saat Filtresi',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (localMode != _DateTimeFilterMode.timeRange) ...[
                        _buildDateTimePickerField(
                          label: 'Tarih',
                          value: DateFormat('dd.MM.yyyy').format(localDate),
                          icon: Icons.calendar_today_outlined,
                          onTap: pickDate,
                        ),
                        const SizedBox(height: 12),
                      ],
                      PremiumDropdown<_DateTimeFilterMode>(
                        labelText: null,
                        placeholderText: 'Filtre tipi seçin',
                        searchHintText: 'Filtre tipi ara...',
                        emptyText: 'Sonuç bulunamadı',
                        value: localMode,
                        options: const [
                          PremiumDropdownOption<_DateTimeFilterMode>(
                            value: _DateTimeFilterMode.dateOnly,
                            title: 'Belirli Tarih',
                            subtitle: 'Sadece seçilen gün',
                          ),
                          PremiumDropdownOption<_DateTimeFilterMode>(
                            value: _DateTimeFilterMode.exactTime,
                            title: 'Belirli Saat',
                            subtitle: 'Seçilen gün + tek saat',
                          ),
                          PremiumDropdownOption<_DateTimeFilterMode>(
                            value: _DateTimeFilterMode.timeRange,
                            title: 'Tarih Aralığı',
                            subtitle: 'Başlangıç/bitiş tarih ve saat',
                          ),
                        ],
                        onChanged: (selected) {
                          setDialogState(() => localMode = selected);
                        },
                      ),
                      if (localMode == _DateTimeFilterMode.exactTime) ...[
                        const SizedBox(height: 12),
                        _buildDateTimePickerField(
                          label: 'Saat',
                          value: _formatTimeOfDay(localExactTime),
                          icon: Icons.access_time,
                          onTap: pickExactTime,
                        ),
                      ],
                      if (localMode == _DateTimeFilterMode.timeRange) ...[
                        const SizedBox(height: 12),
                        _buildDateTimePickerField(
                          label: 'Başlangıç Tarihi',
                          value: DateFormat('dd.MM.yyyy')
                              .format(localRangeStartDate),
                          icon: Icons.calendar_today_outlined,
                          onTap: pickRangeStartDate,
                        ),
                        const SizedBox(height: 10),
                        _buildDateTimePickerField(
                          label: 'Bitiş Tarihi',
                          value: DateFormat('dd.MM.yyyy')
                              .format(localRangeEndDate),
                          icon: Icons.event_outlined,
                          onTap: pickRangeEndDate,
                        ),
                        const SizedBox(height: 10),
                        _buildDateTimePickerField(
                          label: 'Başlangıç Saati',
                          value: _formatTimeOfDay(localRangeStartTime),
                          icon: Icons.schedule,
                          onTap: pickRangeStartTime,
                        ),
                        const SizedBox(height: 10),
                        _buildDateTimePickerField(
                          label: 'Bitiş Saati',
                          value: _formatTimeOfDay(localRangeEndTime),
                          icon: Icons.schedule_send,
                          onTap: pickRangeEndTime,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('İptal'),
                ),
                FilledButton(
                  onPressed: () {
                    if (localMode == _DateTimeFilterMode.exactTime &&
                        localExactTime == null) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(content: Text('Lütfen saat seçin')),
                      );
                      return;
                    }
                    if (localMode == _DateTimeFilterMode.timeRange) {
                      final effectiveRangeStartTime = localRangeStartTime ??
                          const TimeOfDay(hour: 0, minute: 0);
                      final effectiveRangeEndTime = localRangeEndTime ??
                          const TimeOfDay(hour: 23, minute: 59);
                      final start = _combineDateAndTime(
                        localRangeStartDate,
                        effectiveRangeStartTime,
                      );
                      final end = _combineDateAndTime(
                        localRangeEndDate,
                        effectiveRangeEndTime,
                      );
                      if (end.isBefore(start)) {
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Bitiş tarih/saati başlangıç tarih/saatinden önce olamaz',
                            ),
                          ),
                        );
                        return;
                      }
                    }

                    Navigator.of(dialogContext).pop(
                      _DateTimeFilterConfig(
                        date: localDate,
                        mode: localMode,
                        exactTime: localExactTime,
                        rangeStartDate: localRangeStartDate,
                        rangeEndDate: localRangeEndDate,
                        rangeStartTime:
                            localMode == _DateTimeFilterMode.timeRange
                                ? (localRangeStartTime ??
                                    const TimeOfDay(hour: 0, minute: 0))
                                : localRangeStartTime,
                        rangeEndTime: localMode == _DateTimeFilterMode.timeRange
                            ? (localRangeEndTime ??
                                const TimeOfDay(hour: 23, minute: 59))
                            : localRangeEndTime,
                      ),
                    );
                  },
                  child: const Text('Uygula'),
                ),
              ],
            );
          },
        );
      },
    );

    if (config == null || !mounted) return;
    setState(() {
      _selectedDate = config.mode == _DateTimeFilterMode.timeRange
          ? (config.rangeStartDate ?? config.date)
          : config.date;
      _dateTimeFilterMode = config.mode;
      _selectedExactTime = config.exactTime;
      _rangeStartDate = config.rangeStartDate;
      _rangeEndDate = config.rangeEndDate;
      _rangeStartTime = config.rangeStartTime;
      _rangeEndTime = config.rangeEndTime;
      _tablePage = 1;
      _groupTablePage = 1;
      _machineTablePage = 1;
    });
    await _loadData();
  }

  Widget _buildDateTimePickerField({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
          suffixIcon: Icon(icon, size: 18),
        ),
        child: Text(value, style: AppTypography.bodyMedium),
      ),
    );
  }

  Widget _buildInlineExportButton() {
    return GestureDetector(
      onTap: _isExporting ? null : _handleExcelExport,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isExporting)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              )
            else
              const Icon(
                Icons.file_download_outlined,
                size: 16,
                color: AppColors.primary,
              ),
            const SizedBox(width: 6),
            Text(
              _isExporting ? 'Hazırlanıyor...' : 'Excel',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleExcelExport() async {
    setState(() => _isExporting = true);
    try {
      final now = DateTime.now();
      final selectedRange = _selectedDateTimeRange;
      final startAt = selectedRange.start.toUtc().toIso8601String();
      final endAt = selectedRange.end.toUtc().toIso8601String();
      final dateLabels = _excelStartEndDates(selectedRange);
      final startDate = dateLabels[0];
      final endDate = dateLabels[1];
      final isAllStage = _stageFilter == _allFilterOption;
      final isAllProduct = _productFilter == _allFilterOption;
      final isAllMachine = _machineFilter == _allFilterOption;
      final isAllShift = _shiftFilter == _allFilterOption;
      final isAllDesign = _designCodeFilter == _allFilterOption;
      final isAllQuality = _qualityFilter == _allFilterOption;
      final stage = isAllStage ? null : _stageFilter;
      final machine = isAllMachine ? null : _machineFilter;
      final shift = isAllShift ? null : _shiftFilter;
      final productName = isAllProduct ? null : _productFilter;
      final designCode = isAllDesign ? null : _designCodeFilter;
      final quality = isAllQuality ? null : _qualityFilter;

      final repo = ref.read(reportRepositoryProvider);
      final result = await repo.exportExcel(
        startDate: startDate,
        endDate: endDate,
        startAt: startAt,
        endAt: endAt,
        stage: stage,
        machine: machine,
        shift: shift,
        productName: productName,
        designCode: designCode,
        quality: quality,
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
            final fileName = 'rapor_${DateFormat('yyyyMMdd').format(now)}.xlsx';
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
                    label: 'Aç',
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

  Widget _buildStatsCards(int totalQty, int totalRecords) {
    return Column(
      children: [
        // Verimlilik card
        // Container(
        //   width: double.infinity,
        //   padding: const EdgeInsets.all(16),
        //   decoration: BoxDecoration(
        //     color: AppColors.surface,
        //     borderRadius: BorderRadius.circular(12),
        //     border: Border.all(color: AppColors.border),
        //   ),
        //   child: Row(
        //     children: [
        //       Expanded(
        //         child: Column(
        //           crossAxisAlignment: CrossAxisAlignment.start,
        //           children: [
        //             Text('Verimlilik',
        //                 style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
        //             const SizedBox(height: 4),
        //             Text('94.2%',
        //                 style: AppTypography.headlineMedium
        //                     .copyWith(fontWeight: FontWeight.w700, fontSize: 32)),
        //             const SizedBox(height: 2),

        //           ],
        //         ),
        //       ),

        //     ],
        //   ),
        // ),
        const SizedBox(height: 10),
        // Toplam Üretim + Toplam Kayıt
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_totalQuantityTitle,
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Text(_formatNumber(totalQty),
                        style: AppTypography.headlineMedium
                            .copyWith(fontWeight: FontWeight.w700)),
                    Text('Adet',
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Toplam Kayıt',
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Text('$totalRecords',
                        style: AppTypography.headlineMedium
                            .copyWith(fontWeight: FontWeight.w700)),
                    Text('Kayıt',
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProductionTable(List<ProductionModel> records) {
    final mergedRows = _mergeSimilarRows(records);
    final totalRows = mergedRows.length;
    final totalPages =
        totalRows == 0 ? 1 : ((totalRows - 1) ~/ _tablePageSize) + 1;
    final currentPage = _tablePage > totalPages
        ? totalPages
        : (_tablePage < 1 ? 1 : _tablePage);
    final startIndex = totalRows == 0 ? 0 : (currentPage - 1) * _tablePageSize;
    final endIndex =
        totalRows == 0 ? 0 : (startIndex + _tablePageSize).clamp(0, totalRows);
    final pageRows = totalRows == 0
        ? const <_MergedReportRow>[]
        : mergedRows.sublist(startIndex, endIndex);
    final showPagination = totalRows > _tablePageSize;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Günlük Üretim',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _buildInlineExportButton(),
              ],
            ),
          ),
          const Divider(height: 1),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: _reportTableMinWidth),
              child: Column(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    color: AppColors.surfaceVariant,
                    child: Row(
                      children: [
                        _buildReportHeaderCell(
                          'TARİH / SAAT',
                          _reportColDateWidth,
                        ),
                        _buildReportHeaderCell(
                          'VARDİYA',
                          _reportColShiftWidth,
                          textAlign: TextAlign.center,
                        ),
                        _buildReportHeaderCell(
                          'MAKİNE/HAT',
                          _reportColMachineWidth,
                          textAlign: TextAlign.center,
                        ),
                        _buildReportHeaderCell(
                          'ÜRÜN KODU',
                          _reportColProductCodeWidth,
                          textAlign: TextAlign.center,
                        ),
                        _buildReportHeaderCell(
                          'ÜRÜN ADI',
                          _reportColProductNameWidth,
                          textAlign: TextAlign.center,
                        ),
                        _buildReportHeaderCell(
                          'DESEN KODU',
                          _reportColDesignCodeWidth,
                          textAlign: TextAlign.center,
                        ),
                        _buildReportHeaderCell(
                          'KALİTE',
                          _reportColQualityWidth,
                          textAlign: TextAlign.center,
                        ),
                        _buildReportHeaderCell(
                          'MİKTAR',
                          _reportColQtyWidth,
                          textAlign: TextAlign.end,
                        ),
                      ],
                    ),
                  ),
                  if (records.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: SizedBox(
                        width: _reportTableMinWidth - 16,
                        child: Text(
                          'Henüz veri yok',
                          style: AppTypography.bodyMedium
                              .copyWith(color: AppColors.textHint),
                        ),
                      ),
                    )
                  else
                    ...pageRows.asMap().entries.map((entry) {
                      final index = entry.key;
                      final row = entry.value;
                      final createdAt = row.createdAt;
                      final dateText = createdAt == null
                          ? '-'
                          : DateFormat('dd.MM.yyyy HH:mm', 'tr_TR')
                              .format(createdAt);
                      final shiftText =
                          row.shift.trim().isEmpty ? '-' : row.shift;
                      final machineText =
                          row.machine.trim().isEmpty ? '-' : row.machine;
                      final productCodeText = row.productCode.trim().isEmpty
                          ? '-'
                          : row.productCode;
                      final productNameText = row.productName.trim().isEmpty
                          ? '-'
                          : row.productName;
                      final designCodeText =
                          row.designCode.trim().isEmpty ? '-' : row.designCode;
                      final qualityText =
                          row.quality.trim().isEmpty ? '-' : row.quality;

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: index == pageRows.length - 1
                                  ? Colors.transparent
                                  : AppColors.border.withValues(alpha: 0.5),
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            _buildReportValueCell(
                              dateText,
                              _reportColDateWidth,
                            ),
                            _buildReportValueCell(
                              shiftText,
                              _reportColShiftWidth,
                              textAlign: TextAlign.center,
                            ),
                            _buildReportValueCell(
                              machineText,
                              _reportColMachineWidth,
                              textAlign: TextAlign.center,
                            ),
                            _buildReportValueCell(
                              productCodeText,
                              _reportColProductCodeWidth,
                              textAlign: TextAlign.center,
                            ),
                            _buildReportValueCell(
                              productNameText,
                              _reportColProductNameWidth,
                              textAlign: TextAlign.center,
                            ),
                            _buildReportValueCell(
                              designCodeText,
                              _reportColDesignCodeWidth,
                              textAlign: TextAlign.center,
                            ),
                            _buildReportValueCell(
                              qualityText,
                              _reportColQualityWidth,
                              textAlign: TextAlign.center,
                            ),
                            _buildReportValueCell(
                              _formatNumber(row.quantity),
                              _reportColQtyWidth,
                              textAlign: TextAlign.end,
                              color: AppColors.primary,
                              bold: true,
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
          if (showPagination) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Row(
                children: [
                  Text(
                    '${startIndex + 1}–$endIndex / $totalRows',
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textHint),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildTablePageButton(
                              label: 'Önceki',
                              onPressed: currentPage > 1
                                  ? () => setState(
                                        () => _tablePage = currentPage - 1,
                                      )
                                  : null,
                            ),
                            for (int page = 1; page <= totalPages; page++)
                              _buildTablePageButton(
                                label: '$page',
                                isActive: currentPage == page,
                                onPressed: currentPage == page
                                    ? null
                                    : () => setState(() => _tablePage = page),
                              ),
                            _buildTablePageButton(
                              label: 'Sonraki',
                              onPressed: currentPage < totalPages
                                  ? () => setState(
                                        () => _tablePage = currentPage + 1,
                                      )
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMachineLineSummaryTable(List<ProductionModel> records) {
    final machineProductTotals = <String, Map<String, int>>{};
    final productTotals = <String, int>{};
    final machineTotals = <String, int>{};
    var grandTotal = 0;

    for (final record in records) {
      final machine = record.machine?.trim().isNotEmpty == true
          ? record.machine!.trim()
          : '-';
      final productName = record.productName.trim();
      final productCode = record.productCode.trim();
      final product = productName.isNotEmpty
          ? productName
          : (productCode.isNotEmpty ? productCode : '-');
      final quantity = record.quantity;

      final machineMap =
          machineProductTotals.putIfAbsent(machine, () => <String, int>{});
      machineMap[product] = (machineMap[product] ?? 0) + quantity;
      machineTotals[machine] = (machineTotals[machine] ?? 0) + quantity;
      productTotals[product] = (productTotals[product] ?? 0) + quantity;
      grandTotal += quantity;
    }

    final products = productTotals.keys.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    final machines = machineProductTotals.keys.toList()
      ..sort((a, b) {
        final qtyCompare =
            (machineTotals[b] ?? 0).compareTo(machineTotals[a] ?? 0);
        if (qtyCompare != 0) return qtyCompare;
        return a.toLowerCase().compareTo(b.toLowerCase());
      });
    final totalRows = machines.length;
    final totalPages =
        totalRows == 0 ? 1 : ((totalRows - 1) ~/ _machineTablePageSize) + 1;
    final currentPage = _machineTablePage > totalPages
        ? totalPages
        : (_machineTablePage < 1 ? 1 : _machineTablePage);
    final startIndex =
        totalRows == 0 ? 0 : (currentPage - 1) * _machineTablePageSize;
    final endIndex = totalRows == 0
        ? 0
        : (startIndex + _machineTablePageSize).clamp(0, totalRows);
    final pageMachines = totalRows == 0
        ? const <String>[]
        : machines.sublist(startIndex, endIndex);
    final showPagination = totalRows > _machineTablePageSize;

    final tableMinWidth = _machineSummaryColMachineWidth +
        (products.length * _machineSummaryColProductWidth) +
        _machineSummaryColTotalWidth;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Makine/Hat Bazlı Üretim',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _buildMachineSummaryExportButton(),
              ],
            ),
          ),
          const Divider(height: 1),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: tableMinWidth),
              child: Column(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    color: AppColors.surfaceVariant,
                    child: Row(
                      children: [
                        _buildReportHeaderCell(
                          'MAKİNE/HAT',
                          _machineSummaryColMachineWidth,
                        ),
                        for (final product in products)
                          _buildReportHeaderCell(
                            product,
                            _machineSummaryColProductWidth,
                            textAlign: TextAlign.center,
                          ),
                        _buildReportHeaderCell(
                          'TOPLAM',
                          _machineSummaryColTotalWidth,
                          textAlign: TextAlign.end,
                        ),
                      ],
                    ),
                  ),
                  if (records.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: SizedBox(
                        width: tableMinWidth - 16,
                        child: Text(
                          'Henüz veri yok',
                          style: AppTypography.bodyMedium
                              .copyWith(color: AppColors.textHint),
                        ),
                      ),
                    )
                  else ...[
                    ...pageMachines.asMap().entries.map((entry) {
                      final index = entry.key;
                      final machine = entry.value;
                      final rowProductTotals = machineProductTotals[machine]!;
                      final rowTotal = machineTotals[machine] ?? 0;

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: index == pageMachines.length - 1
                                  ? Colors.transparent
                                  : AppColors.border.withValues(alpha: 0.5),
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            _buildReportValueCell(
                              machine,
                              _machineSummaryColMachineWidth,
                              bold: true,
                            ),
                            for (final product in products)
                              _buildReportValueCell(
                                (rowProductTotals[product] ?? 0) == 0
                                    ? '-'
                                    : _formatNumber(rowProductTotals[product]!),
                                _machineSummaryColProductWidth,
                                textAlign: TextAlign.center,
                              ),
                            _buildReportValueCell(
                              _formatNumber(rowTotal),
                              _machineSummaryColTotalWidth,
                              textAlign: TextAlign.end,
                              color: AppColors.primary,
                              bold: true,
                            ),
                          ],
                        ),
                      );
                    }),
                    const Divider(height: 1),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 12,
                      ),
                      color: AppColors.surfaceVariant.withValues(alpha: 0.6),
                      child: Row(
                        children: [
                          _buildReportValueCell(
                            'TOPLAM',
                            _machineSummaryColMachineWidth,
                            bold: true,
                          ),
                          for (final product in products)
                            _buildReportValueCell(
                              _formatNumber(productTotals[product] ?? 0),
                              _machineSummaryColProductWidth,
                              textAlign: TextAlign.center,
                              bold: true,
                            ),
                          _buildReportValueCell(
                            _formatNumber(grandTotal),
                            _machineSummaryColTotalWidth,
                            textAlign: TextAlign.end,
                            color: AppColors.primary,
                            bold: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (showPagination) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Row(
                children: [
                  Text(
                    '${startIndex + 1}–$endIndex / $totalRows',
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textHint),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildTablePageButton(
                              label: 'Önceki',
                              onPressed: currentPage > 1
                                  ? () => setState(
                                        () =>
                                            _machineTablePage = currentPage - 1,
                                      )
                                  : null,
                            ),
                            for (int page = 1; page <= totalPages; page++)
                              _buildTablePageButton(
                                label: '$page',
                                isActive: currentPage == page,
                                onPressed: currentPage == page
                                    ? null
                                    : () => setState(
                                          () => _machineTablePage = page,
                                        ),
                              ),
                            _buildTablePageButton(
                              label: 'Sonraki',
                              onPressed: currentPage < totalPages
                                  ? () => setState(
                                        () =>
                                            _machineTablePage = currentPage + 1,
                                      )
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMachineSummaryExportButton() {
    return GestureDetector(
      onTap:
          _isMachineSummaryExporting ? null : _handleMachineSummaryExcelExport,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isMachineSummaryExporting)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              )
            else
              const Icon(
                Icons.file_download_outlined,
                size: 16,
                color: AppColors.primary,
              ),
            const SizedBox(width: 6),
            Text(
              _isMachineSummaryExporting ? 'Hazırlanıyor...' : 'Excel',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleMachineSummaryExcelExport() async {
    setState(() => _isMachineSummaryExporting = true);
    try {
      final now = DateTime.now();
      final selectedRange = _selectedDateTimeRange;
      final startAt = selectedRange.start.toUtc().toIso8601String();
      final endAt = selectedRange.end.toUtc().toIso8601String();
      final dateLabels = _excelStartEndDates(selectedRange);
      final startDate = dateLabels[0];
      final endDate = dateLabels[1];
      final isAllStage = _stageFilter == _allFilterOption;
      final isAllProduct = _productFilter == _allFilterOption;
      final isAllMachine = _machineFilter == _allFilterOption;
      final isAllShift = _shiftFilter == _allFilterOption;
      final isAllDesign = _designCodeFilter == _allFilterOption;
      final isAllQuality = _qualityFilter == _allFilterOption;
      final stage = isAllStage ? null : _stageFilter;
      final machine = isAllMachine ? null : _machineFilter;
      final shift = isAllShift ? null : _shiftFilter;
      final productName = isAllProduct ? null : _productFilter;
      final designCode = isAllDesign ? null : _designCodeFilter;
      final quality = isAllQuality ? null : _qualityFilter;

      final repo = ref.read(reportRepositoryProvider);
      final result = await repo.exportExcel(
        reportMode: 'machine_summary',
        startDate: startDate,
        endDate: endDate,
        startAt: startAt,
        endAt: endAt,
        stage: stage,
        machine: machine,
        shift: shift,
        productName: productName,
        designCode: designCode,
        quality: quality,
      );

      result.fold(
        (failure) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Makine/Hat Excel dışa aktarma başarısız: ${failure.message}',
                ),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        (bytes) async {
          final fileName =
              'makine_hat_rapor_${DateFormat('yyyyMMdd_HHmm').format(now)}.xlsx';
          final exportedFile = await ExcelExportStorage.saveToDownloads(
            bytes: bytes,
            fileName: fileName,
          );
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Makine/Hat Excel dosyası kaydedildi'),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Aç',
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
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Makine/Hat Excel dışa aktarma sırasında hata oluştu: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isMachineSummaryExporting = false);
    }
  }

  List<_GroupedSummaryRow> _buildGroupedSummaryRows(
    List<ProductionModel> records,
  ) {
    final grouped = <String, _GroupedSummaryRow>{};

    for (final row in records) {
      final productName =
          row.productName.trim().isEmpty ? '-' : row.productName.trim();
      final designCode =
          row.designCode.trim().isEmpty ? '-' : row.designCode.trim();
      final quality = _extractQualityLabel(row);
      final key = '$productName|$designCode|$quality';

      final existing = grouped[key];
      if (existing == null) {
        grouped[key] = _GroupedSummaryRow(
          productName: productName,
          designCode: designCode,
          quality: quality,
          quantity: row.quantity,
        );
      } else {
        grouped[key] = _GroupedSummaryRow(
          productName: existing.productName,
          designCode: existing.designCode,
          quality: existing.quality,
          quantity: existing.quantity + row.quantity,
        );
      }
    }

    final rows = grouped.values.toList()
      ..sort((a, b) {
        final quantityCompare = b.quantity.compareTo(a.quantity);
        if (quantityCompare != 0) return quantityCompare;
        return a.productName.compareTo(b.productName);
      });
    return rows;
  }

  int _totalGroupedQuantity(List<_GroupedSummaryRow> rows) {
    return rows.fold<int>(0, (sum, row) => sum + row.quantity);
  }

  Widget _buildGroupedSummaryTableSection({
    required List<_GroupedSummaryRow> groupedRows,
  }) {
    final totalRows = groupedRows.length;
    final totalPages =
        totalRows == 0 ? 1 : ((totalRows - 1) ~/ _groupTablePageSize) + 1;
    final currentPage = _groupTablePage > totalPages
        ? totalPages
        : (_groupTablePage < 1 ? 1 : _groupTablePage);
    final startIndex =
        totalRows == 0 ? 0 : (currentPage - 1) * _groupTablePageSize;
    final endIndex = totalRows == 0
        ? 0
        : (startIndex + _groupTablePageSize).clamp(0, totalRows);
    final pageRows = totalRows == 0
        ? const <_GroupedSummaryRow>[]
        : groupedRows.sublist(startIndex, endIndex);
    final showPagination = totalRows > _groupTablePageSize;
    final totalQuantity = _totalGroupedQuantity(groupedRows);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const rowHorizontalPadding = 12.0;
          const baseContentWidth = _groupColProductWidth +
              _groupColDesignWidth +
              _groupColQualityWidth +
              _groupColQtyWidth;
          final rawContentWidth = constraints.maxWidth - rowHorizontalPadding;
          final contentWidth = rawContentWidth > 0 ? rawContentWidth : 0.0;
          final scale = contentWidth < baseContentWidth
              ? contentWidth / baseContentWidth
              : 1.0;
          final productColWidth = _groupColProductWidth * scale;
          final designColWidth = _groupColDesignWidth * scale;
          final qualityColWidth = _groupColQualityWidth * scale;
          final qtyColWidth = _groupColQtyWidth * scale;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Çalışan Raporu',
                        style: AppTypography.titleMedium
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    _buildGroupedSummaryExportButton(
                        totalQuantity: totalQuantity),
                  ],
                ),
              ),
              const Divider(height: 1),
              Column(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
                    color: AppColors.surfaceVariant,
                    child: Row(
                      children: [
                        _buildReportHeaderCell(
                          'ÜRÜN ADI',
                          productColWidth,
                        ),
                        _buildReportHeaderCell(
                          'DESEN KODU',
                          designColWidth,
                          textAlign: TextAlign.center,
                        ),
                        _buildReportHeaderCell(
                          'KALİTE',
                          qualityColWidth,
                          textAlign: TextAlign.center,
                        ),
                        _buildReportHeaderCell(
                          'MİKTAR',
                          qtyColWidth,
                          textAlign: TextAlign.end,
                        ),
                      ],
                    ),
                  ),
                  if (groupedRows.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: SizedBox(
                        width: double.infinity,
                        child: Text(
                          'Henüz veri yok',
                          style: AppTypography.bodyMedium
                              .copyWith(color: AppColors.textHint),
                        ),
                      ),
                    )
                  else
                    ...pageRows.asMap().entries.map((entry) {
                      final index = entry.key;
                      final row = entry.value;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: index == pageRows.length - 1
                                  ? Colors.transparent
                                  : AppColors.border.withValues(alpha: 0.5),
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            _buildReportValueCell(
                              row.productName,
                              productColWidth,
                              bold: true,
                            ),
                            _buildReportValueCell(
                              row.designCode,
                              designColWidth,
                              textAlign: TextAlign.center,
                            ),
                            _buildReportValueCell(
                              row.quality,
                              qualityColWidth,
                              textAlign: TextAlign.center,
                            ),
                            _buildReportValueCell(
                              '${_formatNumber(row.quantity)} adet',
                              qtyColWidth,
                              textAlign: TextAlign.end,
                              color: AppColors.primary,
                              bold: true,
                            ),
                          ],
                        ),
                      );
                    }),
                  if (groupedRows.isNotEmpty) ...[
                    const Divider(height: 1),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 7,
                      ),
                      color: AppColors.surfaceVariant.withValues(alpha: 0.6),
                      child: Row(
                        children: [
                          _buildReportValueCell(
                            'TOPLAM',
                            productColWidth + designColWidth,
                            bold: true,
                          ),
                          _buildReportValueCell(
                            '',
                            qualityColWidth,
                            textAlign: TextAlign.center,
                          ),
                          _buildReportValueCell(
                            '${_formatNumber(totalQuantity)} adet',
                            qtyColWidth,
                            textAlign: TextAlign.end,
                            color: AppColors.primary,
                            bold: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              if (showPagination) ...[
                const Divider(height: 1),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    children: [
                      Text(
                        '${startIndex + 1}–$endIndex / $totalRows',
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textHint),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildTablePageButton(
                                  label: 'Önceki',
                                  onPressed: currentPage > 1
                                      ? () => setState(
                                            () => _groupTablePage =
                                                currentPage - 1,
                                          )
                                      : null,
                                ),
                                for (int page = 1; page <= totalPages; page++)
                                  _buildTablePageButton(
                                    label: '$page',
                                    isActive: currentPage == page,
                                    onPressed: currentPage == page
                                        ? null
                                        : () => setState(
                                            () => _groupTablePage = page),
                                  ),
                                _buildTablePageButton(
                                  label: 'Sonraki',
                                  onPressed: currentPage < totalPages
                                      ? () => setState(
                                            () => _groupTablePage =
                                                currentPage + 1,
                                          )
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildGroupedSummaryExportButton({required int totalQuantity}) {
    return GestureDetector(
      onTap: _isGroupedExporting
          ? null
          : () => _handleGroupedExcelExport(totalQuantity: totalQuantity),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _isGroupedExporting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : const Icon(Icons.file_download_outlined,
                    size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              _isGroupedExporting ? 'Hazırlanıyor...' : 'Excel',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleGroupedExcelExport({required int totalQuantity}) async {
    setState(() => _isGroupedExporting = true);
    try {
      final now = DateTime.now();
      final selectedRange = _selectedDateTimeRange;
      final startAt = selectedRange.start.toUtc().toIso8601String();
      final endAt = selectedRange.end.toUtc().toIso8601String();
      final dateLabels = _excelStartEndDates(selectedRange);
      final startDate = dateLabels[0];
      final endDate = dateLabels[1];
      final isAllStage = _stageFilter == _allFilterOption;
      final isAllProduct = _productFilter == _allFilterOption;
      final isAllMachine = _machineFilter == _allFilterOption;
      final isAllShift = _shiftFilter == _allFilterOption;
      final isAllDesign = _designCodeFilter == _allFilterOption;
      final isAllQuality = _qualityFilter == _allFilterOption;
      final stage = isAllStage ? null : _stageFilter;
      final machine = isAllMachine ? null : _machineFilter;
      final shift = isAllShift ? null : _shiftFilter;
      final productName = isAllProduct ? null : _productFilter;
      final designCode = isAllDesign ? null : _designCodeFilter;
      final quality = isAllQuality ? null : _qualityFilter;

      final repo = ref.read(reportRepositoryProvider);
      final result = await repo.exportExcel(
        reportMode: 'grouped_summary',
        startDate: startDate,
        endDate: endDate,
        startAt: startAt,
        endAt: endAt,
        stage: stage,
        machine: machine,
        shift: shift,
        productName: productName,
        designCode: designCode,
        quality: quality,
      );

      result.fold(
        (failure) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Çalışan Excel dışa aktarma başarısız: ${failure.message}'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        (bytes) async {
          final fileName =
              'ozet_rapor_${DateFormat('yyyyMMdd_HHmm').format(now)}_$totalQuantity.xlsx';
          final exportedFile = await ExcelExportStorage.saveToDownloads(
            bytes: bytes,
            fileName: fileName,
          );
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Çalışan Excel dosyası kaydedildi'),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Aç',
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
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Çalışan Excel dışa aktarma sırasında hata oluştu: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGroupedExporting = false);
    }
  }

  List<_MergedReportRow> _mergeSimilarRows(List<ProductionModel> records) {
    final grouped = <String, _MergedReportRow>{};

    for (final row in records) {
      final date = row.createdAt;
      final dateKey =
          date == null ? '-' : DateFormat('yyyy-MM-dd', 'tr_TR').format(date);
      final shift = row.shift.trim().isEmpty ? '-' : row.shift.trim();
      final machine =
          row.machine?.trim().isNotEmpty == true ? row.machine!.trim() : '-';
      final productCode =
          row.productCode.trim().isEmpty ? '-' : row.productCode.trim();
      final productName =
          row.productName.trim().isEmpty ? '-' : row.productName.trim();
      final designCode =
          row.designCode.trim().isEmpty ? '-' : row.designCode.trim();
      final quality = _extractQualityLabel(row);

      final key =
          '$dateKey|$shift|$machine|$productCode|$productName|$designCode|$quality';
      final existing = grouped[key];
      if (existing == null) {
        grouped[key] = _MergedReportRow(
          createdAt: date,
          shift: shift,
          machine: machine,
          productCode: productCode,
          productName: productName,
          designCode: designCode,
          quality: quality,
          quantity: row.quantity,
        );
        continue;
      }

      grouped[key] = _MergedReportRow(
        createdAt: existing.createdAt,
        shift: existing.shift,
        machine: existing.machine,
        productCode: existing.productCode,
        productName: existing.productName,
        designCode: existing.designCode,
        quality: existing.quality,
        quantity: existing.quantity + row.quantity,
      );
    }

    final merged = grouped.values.toList()
      ..sort((a, b) {
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final dateCompare = bDate.compareTo(aDate);
        if (dateCompare != 0) return dateCompare;
        return b.quantity.compareTo(a.quantity);
      });

    return merged;
  }

  String _extractQualityLabel(ProductionModel record) {
    final fromField = _qualityLabelFromLevel(record.quality);
    if (fromField != null) return fromField;
    return _extractQualityLabelFromNotes(record.notes);
  }

  String? _qualityLabelFromLevel(int? level) {
    switch (level) {
      case 1:
        return '1.kalite';
      case 2:
        return '2.kalite';
      case 3:
        return '3.kalite';
      case 4:
        return 'Endüstriyel';
      default:
        return null;
    }
  }

  String _extractQualityLabelFromNotes(String? notes) {
    final raw = notes?.trim();
    if (raw == null || raw.isEmpty) return '-';

    final normalized = raw.toLowerCase();
    if (normalized.contains('1.kalite') ||
        normalized.contains('1. kalite') ||
        normalized.contains('birinci kalite')) {
      return '1.kalite';
    }
    if (normalized.contains('2.kalite') ||
        normalized.contains('2. kalite') ||
        normalized.contains('ikinci kalite')) {
      return '2.kalite';
    }
    if (normalized.contains('3.kalite') ||
        normalized.contains('3. kalite') ||
        normalized.contains('üçüncü kalite') ||
        normalized.contains('ucuncu kalite')) {
      return '3.kalite';
    }
    if (normalized.contains('endüstriyel') ||
        normalized.contains('endustriyel')) {
      return 'Endüstriyel';
    }

    final match = RegExp(r'\b([123])\s*[.]?\s*kalite\b').firstMatch(normalized);
    if (match != null) {
      return '${match.group(1)}.kalite';
    }

    return '-';
  }

  Widget _buildReportHeaderCell(
    String label,
    double width, {
    TextAlign textAlign = TextAlign.start,
  }) {
    return SizedBox(
      width: width,
      child: Text(label, style: _tableHeaderStyle, textAlign: textAlign),
    );
  }

  Widget _buildReportValueCell(
    String value,
    double width, {
    TextAlign textAlign = TextAlign.start,
    Color? color,
    bool bold = false,
  }) {
    return SizedBox(
      width: width,
      child: Text(
        value,
        style: AppTypography.bodySmall.copyWith(
          fontWeight: bold ? FontWeight.w600 : FontWeight.w500,
          color: color ?? AppColors.textPrimary,
        ),
        textAlign: textAlign,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildTablePageButton({
    required String label,
    required VoidCallback? onPressed,
    bool isActive = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          minimumSize: const Size(34, 30),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          foregroundColor:
              isActive ? AppColors.surface : AppColors.textSecondary,
          backgroundColor: isActive ? AppColors.primary : AppColors.surface,
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildDailyEfficiency(
      List<Map<String, dynamic>> byShift, String reportDate) {
    final totalQty = byShift.fold<int>(
      0,
      (sum, row) =>
          sum + _toIntMetric(row, const ['total_quantity', 'totalQuantity']),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Vardiya Özeti',
              style: AppTypography.titleMedium
                  .copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Tarih: $reportDate',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              )),
          const SizedBox(height: 14),
          if (byShift.isEmpty)
            Text('Seçili filtre için vardiya özeti verisi yok.',
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.textHint))
          else
            Column(
              children: byShift.map((row) {
                final shift = (row['_id'] ?? '-').toString();
                final qty = _toIntMetric(
                    row, const ['total_quantity', 'totalQuantity']);
                final count = _toIntMetric(row, const ['count']);
                final ratio = totalQty > 0 ? qty / totalQty : 0.0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              shift,
                              style: AppTypography.bodyMedium
                                  .copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          Text(
                            '${_formatNumber(qty)} adet • $count kayıt',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          minHeight: 9,
                          value: ratio,
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.12),
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Map<String, dynamic>? _findSelectedStageStat(
      List<Map<String, dynamic>> byStage) {
    if (_stageFilter == _allFilterOption) return null;
    for (final row in byStage) {
      if ((row['_id'] ?? '').toString() == _stageFilter) {
        return row;
      }
    }
    return null;
  }

  int _resolveStageTotalQuantity(List<Map<String, dynamic>> byStage) {
    final selected = _findSelectedStageStat(byStage);
    if (selected != null) {
      return _toIntMetric(
        selected,
        const ['total_quantity', 'totalQuantity'],
      );
    }
    return byStage.fold<int>(
      0,
      (sum, row) =>
          sum + _toIntMetric(row, const ['total_quantity', 'totalQuantity']),
    );
  }

  int _resolveStageTotalRecords(
    List<Map<String, dynamic>> byStage,
    List<ProductionModel> allProductions,
  ) {
    final selected = _findSelectedStageStat(byStage);
    if (selected != null) {
      return _toIntMetric(selected, const ['count']);
    }
    if (_stageFilter == _allFilterOption) {
      return byStage.fold<int>(
        0,
        (sum, row) => sum + _toIntMetric(row, const ['count']),
      );
    }
    return allProductions.where((item) => item.stage == _stageFilter).length;
  }

  TextStyle get _tableHeaderStyle => AppTypography.labelSmall.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w600,
      );

  String _formatNumber(int number) {
    if (number >= 1000) {
      return NumberFormat('#,###').format(number);
    }
    return '$number';
  }

  int _toIntMetric(Map<String, dynamic> item, List<String> keys) {
    for (final key in keys) {
      final value = item[key];
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
    }
    return 0;
  }
}
