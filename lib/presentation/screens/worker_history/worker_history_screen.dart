import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/network/network_info.dart';
import '../../../core/utils/pattern_image_utils.dart';
import '../../../core/utils/shift_utils.dart';
import '../../../data/database/app_database.dart';
import '../../../data/models/production_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/production_provider.dart';
import '../../providers/entry_providers.dart';
import '../../providers/service_providers.dart';
import '../../widgets/account_panel.dart';
import '../../widgets/common_widgets.dart';

class WorkerHistoryScreen extends ConsumerStatefulWidget {
  const WorkerHistoryScreen({super.key});

  @override
  ConsumerState<WorkerHistoryScreen> createState() =>
      _WorkerHistoryScreenState();
}

class _WorkerHistoryScreenState extends ConsumerState<WorkerHistoryScreen> {
  bool _isLoading = false;
  bool _isOnline = true;
  String? _error;
  List<ProductionModel> _records = [];
  List<ProductionModel> _remoteRecords = [];
  int _currentPage = 1;
  int _totalPages = 1;
  int _workerSummaryTablePage = 1;
  StreamSubscription<List<ProductionEntry>>? _localEntriesSub;
  Timer? _dayBoundaryTimer;
  int _lastRefreshToken = -1;
  final ScrollController _historyScrollController = ScrollController();
  bool _isSummaryCardVisible = true;

  static const int _workerSummaryRowsPerPage = 4;
  static const double _workerTableMinWidth = 640;
  static const double _workerColProductWidth = 250;
  static const double _workerColDesignWidth = 150;
  static const double _workerColQualityWidth = 130;
  static const double _workerColQtyWidth = 110;

  @override
  void initState() {
    super.initState();
    _historyScrollController.addListener(_onHistoryScroll);
    _checkConnectivity();
    _listenLocalEntries();
    _scheduleDayBoundaryRefresh();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_ensureCatalogLoaded());
    });
  }

  @override
  void dispose() {
    _localEntriesSub?.cancel();
    _dayBoundaryTimer?.cancel();
    _historyScrollController.removeListener(_onHistoryScroll);
    _historyScrollController.dispose();
    super.dispose();
  }

  void _onHistoryScroll() {
    if (!_historyScrollController.hasClients) return;

    final position = _historyScrollController.position;
    final atTop = position.pixels <= 8;
    if (atTop) {
      if (!_isSummaryCardVisible && mounted) {
        setState(() => _isSummaryCardVisible = true);
      }
      return;
    }

    final direction = position.userScrollDirection;
    if (direction == ScrollDirection.reverse &&
        _isSummaryCardVisible &&
        mounted) {
      setState(() => _isSummaryCardVisible = false);
      return;
    }
    if (direction == ScrollDirection.forward &&
        !_isSummaryCardVisible &&
        mounted) {
      setState(() => _isSummaryCardVisible = true);
    }
  }

  Future<void> _checkConnectivity() async {
    final networkInfo = NetworkInfo();
    final online = await networkInfo.isConnected;
    if (mounted) setState(() => _isOnline = online);
  }

  void _scheduleDayBoundaryRefresh() {
    _dayBoundaryTimer?.cancel();
    final user = ref.read(authProvider).user;
    if (user?.role != 'worker') return;

    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day)
        .add(const Duration(days: 1, hours: 1, minutes: 0, seconds: 0));
    final delay = nextMidnight.difference(now);
    _dayBoundaryTimer = Timer(delay, _handleDayBoundaryReached);
  }

  void _handleDayBoundaryReached() {
    if (!mounted) return;
    setState(() {
      _workerSummaryTablePage = 1;
    });
    unawaited(
      _refreshPageData().whenComplete(() {
        if (mounted) _scheduleDayBoundaryRefresh();
      }),
    );
  }

  Future<void> _ensureCatalogLoaded() async {
    final catalog = ref.read(catalogProvider);
    if (kDebugMode) {
      debugPrint(
        '[WORKER_HISTORY] ensureCatalogLoaded -> isLoading=${catalog.isLoading}, patterns=${catalog.patterns.length}',
      );
    }
    if (catalog.isLoading || catalog.patterns.isNotEmpty) return;
    try {
      await ref.read(catalogProvider.notifier).loadAll();
    } catch (error, stack) {
      if (kDebugMode) {
        debugPrint('[WORKER_HISTORY] catalog loadAll error: $error');
        debugPrint('[WORKER_HISTORY] catalog loadAll stack: $stack');
      }
    }
  }

  Future<void> _loadHistory({int page = 1}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = ref.read(authProvider).user;
      final isWorker = user?.role == 'worker';
      final canViewAll = _canViewAllHistory(user);
      final db = ref.read(databaseProvider);
      final online = await ref.read(networkInfoProvider).isConnected;

      if (mounted) {
        setState(() => _isOnline = online);
      }

      if (!online) {
        final localRows = await db.getProductionEntries(
          userId: canViewAll ? null : user?.id,
        );
        final localRecords = localRows
            .map((row) => _fromLocalEntry(row, user))
            .toList()
          ..sort(_sortByCreatedAtDesc);
        final visibleLocalRecords = _applyWorkerDailyFilter(localRecords, user);

        if (mounted) {
          setState(() {
            _isLoading = false;
            _remoteRecords = [];
            _records = visibleLocalRecords;
            _currentPage = 1;
            _totalPages = 1;
            _workerSummaryTablePage = 1;
          });
        }
        return;
      }

      final repo = ref.read(productionRepositoryProvider);
      final pageSize = canViewAll ? 30 : 200;
      final result = await () async {
        if (isWorker) {
          final todayRangeUtc = _workerTodayUtcRange();
          return repo.getProductions(
            page: page,
            limit: pageSize,
            startAt: todayRangeUtc.start.toIso8601String(),
            endAt: todayRangeUtc.end.toIso8601String(),
          );
        }
        if (canViewAll) {
          return repo.getProductions(page: page, limit: pageSize);
        }
        return repo.getMyHistory(page: page, limit: pageSize);
      }();

      await result.fold<Future<void>>(
        (failure) async {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _error = failure.message;
            });
          }
        },
        (response) async {
          final localRows = await db.getProductionEntries(
            userId: canViewAll ? null : user?.id,
          );
          final localOverrides = localRows
              .map((row) => _fromLocalEntry(row, user))
              .where(_isLocalPendingOverride)
              .toList();

          final mergedRecords = _mergeRemoteWithLocalPending(
            response.data,
            localOverrides,
          );
          final visibleMergedRecords = _applyWorkerDailyFilter(
            mergedRecords,
            user,
          );
          final visibleRemoteRecords = _applyWorkerDailyFilter(
            response.data,
            user,
          );

          if (mounted) {
            setState(() {
              _isLoading = false;
              _remoteRecords = visibleRemoteRecords;
              _records = visibleMergedRecords;
              _currentPage = response.page;
              _totalPages = response.pages;
              _workerSummaryTablePage = 1;
            });
          }
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _refreshPageData() async {
    await _checkConnectivity();
    await _loadHistory(page: _currentPage);
  }

  void _consumeRefreshToken(int token) {
    if (token == _lastRefreshToken) return;
    _lastRefreshToken = token;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _refreshPageData();
    });
  }

  void _listenLocalEntries() {
    final user = ref.read(authProvider).user;
    final canViewAll = _canViewAllHistory(user);
    final db = ref.read(databaseProvider);

    _localEntriesSub?.cancel();
    _localEntriesSub = db
        .watchProductionEntries(userId: canViewAll ? null : user?.id)
        .listen((rows) {
      if (!mounted) return;

      final localRecords = rows
          .map((row) => _fromLocalEntry(row, user))
          .toList()
        ..sort(_sortByCreatedAtDesc);
      final visibleLocalRecords = _applyWorkerDailyFilter(localRecords, user);
      final localOverrides =
          visibleLocalRecords.where(_isLocalPendingOverride).toList();

      setState(() {
        if (!_isOnline) {
          _records = visibleLocalRecords;
          _currentPage = 1;
          _totalPages = 1;
          _workerSummaryTablePage = 1;
          return;
        }
        final merged =
            _mergeRemoteWithLocalPending(_remoteRecords, localOverrides);
        _records = _applyWorkerDailyFilter(merged, user);
        _workerSummaryTablePage = 1;
      });
    });
  }

  ProductionModel _fromLocalEntry(ProductionEntry entry, dynamic currentUser) {
    final fallbackPersonnelNo =
        currentUser != null && currentUser.id == entry.userId
            ? currentUser.personnelNo
            : null;

    return ProductionModel(
      id: entry.serverId,
      operationId: entry.operationId,
      productName: entry.productName,
      productCode: entry.productCode,
      designCode: entry.patternCode ?? '',
      stage: entry.stage,
      machine: entry.machine,
      quantity: entry.quantity,
      shift: entry.shift,
      userId: entry.userId,
      userName: entry.userName,
      personnelNo: fallbackPersonnelNo,
      quality: entry.quality,
      notes: entry.notes,
      status: 'active',
      localSyncStatus: entry.syncStatus,
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
    );
  }

  String _recordIdentityKey(ProductionModel item) {
    final id = item.id?.trim();
    if (id != null && id.isNotEmpty) return 'id:$id';

    final operationId = item.operationId?.trim();
    if (operationId != null && operationId.isNotEmpty) {
      return 'op:$operationId';
    }

    return 'fallback:${item.userId}|${item.productCode}|${item.stage}|'
        '${item.createdAt?.millisecondsSinceEpoch ?? 0}|${item.quantity}';
  }

  ProductionModel _overlayLocalEditsOnRemote(
    ProductionModel local,
    ProductionModel remote,
  ) {
    final localDesign = local.designCode.trim();

    return ProductionModel(
      id: local.id ?? remote.id,
      operationId: local.operationId ?? remote.operationId,
      productName: remote.productName,
      productCode: remote.productCode,
      designCode: localDesign.isNotEmpty ? localDesign : remote.designCode,
      stage: remote.stage,
      machine: local.machine ?? remote.machine,
      quantity: local.quantity,
      shift: remote.shift,
      userId: remote.userId,
      userName: remote.userName ?? local.userName,
      personnelNo: remote.personnelNo ?? local.personnelNo,
      quality: local.quality ?? remote.quality,
      notes: local.notes ?? remote.notes,
      status: remote.status,
      localSyncStatus: local.localSyncStatus ?? remote.localSyncStatus,
      createdAt: remote.createdAt ?? local.createdAt,
      updatedAt: local.updatedAt ?? remote.updatedAt,
    );
  }

  List<ProductionModel> _mergeRemoteWithLocalPending(
    List<ProductionModel> remote,
    List<ProductionModel> localPending,
  ) {
    final merged = <ProductionModel>[];
    final seen = <String>{};
    final remoteById = <String, ProductionModel>{};
    final remoteByOperationId = <String, ProductionModel>{};

    for (final item in remote) {
      final id = item.id?.trim();
      if (id != null && id.isNotEmpty) {
        remoteById[id] = item;
      }
      final operationId = item.operationId?.trim();
      if (operationId != null && operationId.isNotEmpty) {
        remoteByOperationId[operationId] = item;
      }
    }

    void addIfNew(ProductionModel item) {
      final key = _recordIdentityKey(item);
      if (seen.add(key)) {
        merged.add(item);
      }
    }

    for (final item in localPending) {
      final id = item.id?.trim();
      final operationId = item.operationId?.trim();
      final remoteMatch =
          (id != null && id.isNotEmpty ? remoteById[id] : null) ??
              (operationId != null && operationId.isNotEmpty
                  ? remoteByOperationId[operationId]
                  : null);
      final mergedItem = remoteMatch == null
          ? item
          : _overlayLocalEditsOnRemote(item, remoteMatch);
      addIfNew(mergedItem);
    }
    for (final item in remote) {
      addIfNew(item);
    }

    merged.sort(_sortByCreatedAtDesc);
    return merged;
  }

  int _sortByCreatedAtDesc(ProductionModel a, ProductionModel b) {
    final aTime =
        _recordDisplayTime(a) ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bTime =
        _recordDisplayTime(b) ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bTime.compareTo(aTime);
  }

  bool _isRecordEdited(ProductionModel record) {
    final createdAt = record.createdAt;
    final updatedAt = record.updatedAt;
    if (createdAt == null || updatedAt == null) return false;
    return updatedAt.isAfter(createdAt.add(const Duration(seconds: 1)));
  }

  bool _isLocalPendingOverride(ProductionModel record) {
    final syncState = _syncStateForRecord(record);
    return syncState != 'synced';
  }

  DateTime? _recordDisplayTime(ProductionModel record) {
    if (_isRecordEdited(record)) return record.updatedAt;
    return record.createdAt ?? record.updatedAt;
  }

  bool _canViewAllHistory(dynamic user) {
    final role = user?.role;
    return role == 'admin' || role == 'supervisor';
  }

  DateTimeRange _todayLocalRange({DateTime? now}) {
    final reference = now ?? DateTime.now();
    final start = DateTime(reference.year, reference.month, reference.day);
    final end = start.add(const Duration(days: 1));
    return DateTimeRange(start: start, end: end);
  }

  DateTimeRange _workerTodayUtcRange({DateTime? now}) {
    final local = _todayLocalRange(now: now);
    final endInclusive = local.end.subtract(const Duration(microseconds: 1));
    return DateTimeRange(
      start: local.start.toUtc(),
      end: endInclusive.toUtc(),
    );
  }

  bool _isCreatedToday(ProductionModel record, {DateTime? now}) {
    final createdAt = record.createdAt;
    if (createdAt == null) return false;
    final localCreatedAt = createdAt.toLocal();
    final today = _todayLocalRange(now: now);
    return !localCreatedAt.isBefore(today.start) &&
        localCreatedAt.isBefore(today.end);
  }

  List<ProductionModel> _applyWorkerDailyFilter(
    List<ProductionModel> records,
    dynamic user,
  ) {
    if (user?.role != 'worker') return records;
    final filtered = records.where(_isCreatedToday).toList()
      ..sort(_sortByCreatedAtDesc);
    return filtered;
  }

  bool _isSupervisorWithin24Hours(ProductionModel record) {
    final createdAt = record.createdAt;
    if (createdAt == null) return false;

    final now = DateTime.now();
    if (createdAt.isAfter(now)) return true;
    return now.difference(createdAt) <= const Duration(hours: 24);
  }

  bool _canEditRecord(ProductionModel record, dynamic user) {
    final role = user?.role;
    if (role == 'admin') return true;
    if (role == 'supervisor') return _isSupervisorWithin24Hours(record);
    if (role == 'worker') {
      return user?.id == record.userId && _isWorkerInAssignedShift(user);
    }
    return false;
  }

  bool _canCancelRecord(ProductionModel record, dynamic user) {
    final role = user?.role;
    if (role == 'admin') return true;
    if (role == 'supervisor') return _isSupervisorWithin24Hours(record);
    return false;
  }

  DateTimeRange? _shiftWindowFor(String shift, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    final today = DateTime(reference.year, reference.month, reference.day);

    switch (shift) {
      case 'Shift 1':
        var start = DateTime(today.year, today.month, today.day, 1);
        var end = DateTime(today.year, today.month, today.day, 9);
        if (reference.isBefore(start)) {
          start = start.subtract(const Duration(days: 1));
          end = end.subtract(const Duration(days: 1));
        }
        return DateTimeRange(start: start, end: end);
      case 'Shift 2':
        var start = DateTime(today.year, today.month, today.day, 9);
        var end = DateTime(today.year, today.month, today.day, 17);
        if (reference.isBefore(start)) {
          start = start.subtract(const Duration(days: 1));
          end = end.subtract(const Duration(days: 1));
        }
        return DateTimeRange(start: start, end: end);
      case 'Shift 3':
        if (reference.hour < 1) {
          final end = DateTime(today.year, today.month, today.day, 1);
          final start = end.subtract(const Duration(hours: 8));
          return DateTimeRange(start: start, end: end);
        }
        if (reference.hour >= 17) {
          final start = DateTime(today.year, today.month, today.day, 17);
          final end = start.add(const Duration(hours: 8));
          return DateTimeRange(start: start, end: end);
        }
        final end = DateTime(today.year, today.month, today.day, 1);
        final start = end.subtract(const Duration(hours: 8));
        return DateTimeRange(start: start, end: end);
      default:
        return null;
    }
  }

  int _shiftTotalQuantity(List<ProductionModel> records, dynamic user) {
    final userId = user?.id?.toString();
    final shift = user?.assignedShift?.toString();
    if (userId == null || shift == null || shift.isEmpty) return 0;

    final window = _shiftWindowFor(shift);
    if (window == null) return 0;

    var total = 0;
    for (final record in records) {
      if (record.userId != userId) continue;
      final createdAt = record.createdAt;
      if (createdAt == null) continue;
      if (createdAt.isBefore(window.start) || !createdAt.isBefore(window.end)) {
        continue;
      }
      total += record.quantity;
    }
    return total;
  }

  int _shiftRecordCount(List<ProductionModel> records, dynamic user) {
    final userId = user?.id?.toString();
    final shift = user?.assignedShift?.toString();
    if (userId == null || shift == null || shift.isEmpty) return 0;

    final window = _shiftWindowFor(shift);
    if (window == null) return 0;

    var count = 0;
    for (final record in records) {
      if (record.userId != userId) continue;
      final createdAt = record.createdAt;
      if (createdAt == null) continue;
      if (createdAt.isBefore(window.start) || !createdAt.isBefore(window.end)) {
        continue;
      }
      count++;
    }
    return count;
  }

  int _summaryTotalQuantity(List<ProductionModel> records, dynamic user) {
    final role = user?.role;
    if (role == 'supervisor' || role == 'admin') {
      return records.fold<int>(0, (sum, record) => sum + record.quantity);
    }
    return _shiftTotalQuantity(records, user);
  }

  int _summaryRecordCount(List<ProductionModel> records, dynamic user) {
    final role = user?.role;
    if (role == 'supervisor' || role == 'admin') {
      final uniqueKeys = records.map(_recordIdentityKey).toSet();
      return uniqueKeys.length;
    }
    return _shiftRecordCount(records, user);
  }

  bool _isWorkerInAssignedShift(dynamic user) {
    if (user?.role != 'worker') return true;
    final assignedShift = user?.assignedShift?.toString().trim() ?? '';
    if (assignedShift.isEmpty) return false;
    return isUserInShift(assignedShift);
  }

  Map<String, String> _patternImageByCode(List<Map<String, dynamic>> patterns) {
    final map = <String, String>{};
    for (final pattern in patterns) {
      final code = (pattern['code'] ?? pattern['pattern_code'] ?? '')
          .toString()
          .trim()
          .toUpperCase();
      if (code.isEmpty) continue;

      final imageRef = PatternImageUtils.resolvePatternImageRef(pattern);
      if (imageRef == null || imageRef.isEmpty) continue;
      map[code] = imageRef;
    }
    return map;
  }

  String _recordDesignCode(ProductionModel record) {
    return record.designCode.trim().toUpperCase();
  }

  String? _recordPatternImage(
    ProductionModel record,
    Map<String, String> patternImageByCode,
  ) {
    final designCode = _recordDesignCode(record);
    if (designCode.isEmpty) return null;
    return patternImageByCode[designCode];
  }

  List<ProductionModel> get _filteredRecords =>
      _applyWorkerDailyFilter(_records, ref.read(authProvider).user);

  Future<void> _handleSync() async {
    await ref.read(syncProvider.notifier).triggerSync();
    _checkConnectivity();
    _loadHistory(page: _currentPage);
  }

  IconData _stageIcon(String stage) {
    final lower = stage.toLowerCase();
    if (lower.contains('pres') || lower.contains('sekil')) {
      return Icons.factory;
    }
    if (lower.contains('firin') || lower.contains('pisir')) {
      return Icons.settings_suggest;
    }
    if (lower.contains('sir') || lower.contains('boya')) {
      return Icons.palette;
    }
    if (lower.contains('ambalaj') || lower.contains('paket')) {
      return Icons.inventory_2;
    }
    if (lower.contains('sevk')) {
      return Icons.local_shipping;
    }
    return Icons.precision_manufacturing;
  }

  String _syncStateForRecord(ProductionModel record) {
    return (record.localSyncStatus == null || record.localSyncStatus!.isEmpty)
        ? 'synced'
        : record.localSyncStatus!;
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'synced':
        return AppColors.success;
      case 'syncing':
        return AppColors.accent;
      case 'pending':
        return AppColors.warning;
      case 'failed':
      case 'error':
      case 'dead':
        return AppColors.error;
      default:
        return AppColors.success;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'synced':
        return Icons.check_circle;
      case 'syncing':
        return Icons.sync;
      case 'pending':
        return Icons.save;
      case 'failed':
      case 'error':
      case 'dead':
        return Icons.sync_problem;
      default:
        return Icons.check_circle;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'synced':
        return 'ESITLENDI';
      case 'syncing':
        return 'SENKRONIZE';
      case 'pending':
        return 'YEREL KAYIT';
      case 'failed':
      case 'error':
        return 'SENKRON HATASI';
      case 'dead':
        return 'HATA OLUSTU';
      default:
        return 'ESITLENDI';
    }
  }

  int? _recordQualityLevelFromField(ProductionModel record) {
    final rawQuality = record.quality;
    if (rawQuality == null) return null;
    if (rawQuality >= 1 && rawQuality <= 4) return rawQuality;
    return null;
  }

  int? _parseQualityLevelFromText(String? rawText) {
    final raw = rawText?.trim();
    if (raw == null || raw.isEmpty) return null;

    final normalized = raw.toLowerCase();
    if (normalized.contains('birinci kalite')) return 1;
    if (normalized.contains('ikinci kalite')) return 2;
    if (normalized.contains('\u00fc\u00e7\u00fcnc\u00fc kalite') ||
        normalized.contains('ucuncu kalite') ||
        normalized.contains('ÃƒÂ¼ÃƒÂ§ÃƒÂ¼ncÃƒÂ¼ kalite')) {
      return 3;
    }
    if (normalized.contains('end\u00fcstriyel') ||
        normalized.contains('endustriyel') ||
        normalized.contains('industrial') ||
        normalized.contains('endÃƒÂ¼striyel')) {
      return 4;
    }

    final leadingMatch =
        RegExp(r'(^|\|)\s*([123])\s*\.?\s*kalite\b').firstMatch(normalized);
    if (leadingMatch != null) {
      return int.tryParse(leadingMatch.group(2)!);
    }

    final inlineMatch =
        RegExp(r'\b([123])\s*\.?\s*kalite\b').firstMatch(normalized);
    if (inlineMatch != null) {
      return int.tryParse(inlineMatch.group(1)!);
    }

    return null;
  }

  String _cleanNotesForDisplay(ProductionModel record) {
    final rawNotes = record.notes?.trim();
    if (rawNotes == null || rawNotes.isEmpty) return '';

    var cleaned = rawNotes;
    final leadingQualityPattern = RegExp(
      '^\\s*(?:'
      '[123]\\s*\\.?\\s*kalite'
      '|birinci\\s+kalite'
      '|ikinci\\s+kalite'
      '|(?:\\u00fc\\u00e7\\u00fcnc\\u00fc|ucuncu)\\s+kalite'
      '|(?:end\\u00fcstriyel|endustriyel|industrial)'
      ')\\s*(?:\\|\\s*)?',
      caseSensitive: false,
    );

    while (true) {
      final updated =
          cleaned.replaceFirst(leadingQualityPattern, '').trimLeft();
      if (updated == cleaned) break;
      cleaned = updated;
    }

    return cleaned.trim();
  }

  int? _recordQualityLevel(ProductionModel record) {
    final qualityFromField = _recordQualityLevelFromField(record);
    if (qualityFromField != null) return qualityFromField;
    return _parseQualityLevelFromText(record.notes);
  }

  String? _qualityLabel(int? qualityLevel) {
    switch (qualityLevel) {
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

  Color _qualityColor(int qualityLevel) {
    switch (qualityLevel) {
      case 1:
        return AppColors.success;
      case 2:
        return AppColors.accent;
      case 3:
        return AppColors.warning;
      case 4:
        return AppColors.info;
      default:
        return AppColors.textHint;
    }
  }

  @override
  Widget build(BuildContext context) {
    final refreshToken =
        ref.watch(pageRefreshTokenProvider(AppPageIds.workerHistory));
    _consumeRefreshToken(refreshToken);

    final syncState = ref.watch(syncProvider);
    final user = ref.watch(authProvider).user;
    final catalogState = ref.watch(catalogProvider);
    final patternImageByCode = _patternImageByCode(catalogState.patterns);
    final filtered = _filteredRecords;
    final showSummaryCard = user?.role == 'worker' ||
        user?.role == 'supervisor' ||
        user?.role == 'admin';
    final showWorkerSummaryTable = user?.role == 'worker';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(syncState, user),
            if (showSummaryCard)
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) => SizeTransition(
                  sizeFactor: animation,
                  axisAlignment: -1,
                  child: child,
                ),
                child: _isSummaryCardVisible
                    ? Column(
                        key: const ValueKey('history-summary-cards'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildShiftSummaryCard(filtered, user),
                          if (showWorkerSummaryTable)
                            _buildWorkerSummaryTableCard(filtered),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_error != null)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppColors.error,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _loadHistory,
                        child: const Text('Tekrar Dene'),
                      ),
                    ],
                  ),
                ),
              )
            else if (filtered.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.history,
                        color: AppColors.textHint,
                        size: 56,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Kayıt bulunamadı',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => _loadHistory(page: _currentPage),
                  child: ListView.builder(
                    controller: _historyScrollController,
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                    itemCount: filtered.length + (_totalPages > 1 ? 1 : 0),
                    itemBuilder: (ctx, i) {
                      if (i == filtered.length) return _buildPagination();
                      return _buildRecordCard(
                        filtered[i],
                        user,
                        patternImageByCode,
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(SyncState syncState, dynamic user) {
    final canViewAll = _canViewAllHistory(user);

    return UnifiedTopBar(
      title: canViewAll ? 'Geçmiş' : 'Geçmiş',
      isSyncing: syncState.isSyncing,
      isOnline: _isOnline,
      pendingCount: syncState.pendingCount,
      failedCount: syncState.failedCount,
      onProfileTap: () => showAccountPanel(context, ref),
    );
  }

  Widget _buildShiftSummaryCard(List<ProductionModel> records, dynamic user) {
    final totalQuantity = _summaryTotalQuantity(records, user);
    final totalRecords = _summaryRecordCount(records, user);
    final isTablet = MediaQuery.of(context).size.width >= 600;

    final quantityMetric = _buildShiftSummaryMetric(
      title: 'TOPLAM ADET',
      value: totalQuantity,
      suffix: 'adet',
      icon: Icons.inventory_2_outlined,
      iconColor: AppColors.info,
    );

    final recordsMetric = _buildShiftSummaryMetric(
      title: 'TOPLAM KAYIT',
      value: totalRecords,
      suffix: 'kayıt',
      icon: Icons.description_outlined,
      iconColor: AppColors.success,
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.divider.withValues(alpha: 0.9),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: isTablet
          //  Tablet
          ? IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(child: quantityMetric),
                  const VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: AppColors.divider,
                  ),
                  Expanded(child: recordsMetric),
                ],
              ),
            )
          //  Phone
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                quantityMetric,
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.divider,
                ),
                recordsMetric,
              ],
            ),
    );
  }

  Widget _buildShiftSummaryMetric({
    required String title,
    required int value,
    required String suffix,
    required IconData icon,
    required Color iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 17, color: iconColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '$value',
                              style: AppTypography.headlineMedium.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w800,
                                height: 1,
                              ),
                            ),
                            TextSpan(
                              text: ' $suffix',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkerSummaryTableCard(List<ProductionModel> records) {
    final sortedRecords = List<ProductionModel>.from(records)
      ..sort((a, b) => b.quantity.compareTo(a.quantity));
    final totalRows = sortedRecords.length;
    final totalPages = (totalRows / _workerSummaryRowsPerPage).ceil();
    final currentPage = totalPages == 0
        ? 1
        : _workerSummaryTablePage.clamp(1, totalPages).toInt();
    final startIndex = (currentPage - 1) * _workerSummaryRowsPerPage;
    final endIndex =
        (startIndex + _workerSummaryRowsPerPage).clamp(0, totalRows).toInt();
    final currentRows = sortedRecords.sublist(startIndex, endIndex);
    final showPagination = totalRows > _workerSummaryRowsPerPage;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.9)),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: _workerTableMinWidth),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(18)),
                    ),
                    child: Row(
                      children: [
                        _buildWorkerTableHeaderCell(
                          'ÜRÜN ADI',
                          _workerColProductWidth,
                        ),
                        _buildWorkerTableHeaderCell(
                          'DESEN KODU',
                          _workerColDesignWidth,
                        ),
                        _buildWorkerTableHeaderCell(
                          'KALİTE',
                          _workerColQualityWidth,
                        ),
                        _buildWorkerTableHeaderCell(
                          'MİKTAR',
                          _workerColQtyWidth,
                          alignRight: true,
                        ),
                      ],
                    ),
                  ),
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.divider,
                  ),
                  if (currentRows.isEmpty)
                    const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '-',
                          style: TextStyle(color: AppColors.textHint),
                        ),
                      ),
                    )
                  else
                    for (int i = 0; i < currentRows.length; i++) ...[
                      _buildWorkerTableRow(currentRows[i]),
                      if (i != currentRows.length - 1)
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: AppColors.divider,
                        ),
                    ],
                ],
              ),
            ),
          ),
          if (showPagination) ...[
            const Divider(height: 1, thickness: 1, color: AppColors.divider),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Row(
                children: [
                  Text(
                    '${startIndex + 1} - $endIndex / $totalRows',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildWorkerTablePageButton(
                              label: 'Önceki',
                              onPressed: currentPage > 1
                                  ? () {
                                      setState(
                                        () => _workerSummaryTablePage =
                                            currentPage - 1,
                                      );
                                    }
                                  : null,
                            ),
                            for (int page = 1; page <= totalPages; page++)
                              _buildWorkerTablePageButton(
                                label: '$page',
                                isActive: page == currentPage,
                                onPressed: page == currentPage
                                    ? null
                                    : () {
                                        setState(
                                          () => _workerSummaryTablePage = page,
                                        );
                                      },
                              ),
                            _buildWorkerTablePageButton(
                              label: 'Sonraki',
                              onPressed: currentPage < totalPages
                                  ? () {
                                      setState(
                                        () => _workerSummaryTablePage =
                                            currentPage + 1,
                                      );
                                    }
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

  Widget _buildWorkerTableHeaderCell(
    String label,
    double width, {
    bool alignRight = false,
  }) {
    return SizedBox(
      width: width,
      child: Align(
        alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  Widget _buildWorkerTableRow(ProductionModel record) {
    final designCode = _recordDesignCode(record);
    final qualityLevel = _recordQualityLevel(record);
    final qualityText = _qualityLabel(qualityLevel);
    final qualityColor =
        qualityLevel != null ? _qualityColor(qualityLevel) : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: _workerColProductWidth,
            child: Text(
              record.productName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(
            width: _workerColDesignWidth,
            child: Text(
              designCode.isNotEmpty ? designCode : '-',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
          SizedBox(
            width: _workerColQualityWidth,
            child: qualityText != null && qualityColor != null
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: qualityColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        qualityText,
                        style: AppTypography.labelSmall.copyWith(
                          color: qualityColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  )
                : Text(
                    '-',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textHint,
                    ),
                  ),
          ),
          SizedBox(
            width: _workerColQtyWidth,
            child: Align(
              alignment: Alignment.centerRight,
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${record.quantity}',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    TextSpan(
                      text: ' adet',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkerTablePageButton({
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
          side: BorderSide(color: AppColors.divider.withValues(alpha: 0.9)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
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

  Widget _buildRecordCard(
    ProductionModel record,
    dynamic user,
    Map<String, String> patternImageByCode,
  ) {
    final displayTime = _recordDisplayTime(record);
    final dateStr = displayTime != null
        ? DateFormat('dd MMM yyyy HH:mm', 'tr').format(displayTime)
        : '-';
    final isEdited = _isRecordEdited(record);
    final syncState = _syncStateForRecord(record);
    final statusColor = _statusColor(syncState);
    final statusIconData = _statusIcon(syncState);
    final statusText = _statusLabel(syncState);
    final isError = syncState == 'failed' || syncState == 'dead';
    final canEdit = _canEditRecord(record, user);
    final canCancel = _canCancelRecord(record, user);
    final qualityLevel = _recordQualityLevel(record);
    final qualityText = _qualityLabel(qualityLevel);
    final qualityColor =
        qualityLevel != null ? _qualityColor(qualityLevel) : null;
    final cleanedNotes = _cleanNotesForDisplay(record);
    final designCode = _recordDesignCode(record);
    final patternImageRef = _recordPatternImage(record, patternImageByCode);
    final machineText = record.machine?.trim() ?? '';
    final stageWithMachine = machineText.isNotEmpty
        ? '${record.stage} / $machineText'
        : record.stage;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _stageIcon(record.stage),
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.productName,
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      stageWithMachine,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIconData, size: 13, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: AppTypography.labelSmall.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (qualityText != null && qualityColor != null) ...[
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: qualityColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        qualityText,
                        style: AppTypography.labelSmall.copyWith(
                          color: qualityColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildRecordMetaMetric(
                    title: 'PERSONEL',
                    value: record.userName?.trim().isNotEmpty == true
                        ? record.userName!
                        : '-',
                  ),
                ),
                _buildRecordMetaDivider(),
                Expanded(
                  child: _buildRecordMetaMetric(
                    title: 'NO',
                    value: record.personnelNo?.trim().isNotEmpty == true
                        ? record.personnelNo!
                        : '-',
                  ),
                ),
                _buildRecordMetaDivider(),
                Expanded(
                  child: _buildRecordMetaMetric(
                    title: 'SHIFT',
                    value: record.shift.trim().isNotEmpty ? record.shift : '-',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildRecordMetaMetric(
                    title: 'ADET',
                    value: '${record.quantity} adet',
                  ),
                ),
                _buildRecordMetaDivider(),
                Expanded(
                  child: _buildRecordMetaMetric(
                    title: 'URUN KODU',
                    value: record.productCode.trim().isNotEmpty
                        ? record.productCode
                        : '-',
                  ),
                ),
                _buildRecordMetaDivider(),
                Expanded(
                  child: _buildRecordMetaMetric(
                    title: 'DESEN',
                    value: designCode.isNotEmpty ? designCode : '-',
                    imageRef: patternImageRef,
                  ),
                ),
              ],
            ),
          ),
          if (cleanedNotes.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NOT',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textHint,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    cleanedNotes,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.schedule,
                      size: 14, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Text(
                    dateStr,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              if (isEdited)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.edit,
                      size: 11,
                      color: AppColors.textHint.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      'duzenlendi',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textHint,
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (isError)
            GestureDetector(
              onTap: _handleSync,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.refresh, size: 16, color: AppColors.error),
                  const SizedBox(width: 6),
                  Text(
                    'Tekrar Dene',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          else if (!canEdit && !canCancel)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                user?.role == 'supervisor'
                    ? 'Yalnızca 24 saat içinde düzenleme/iptal yapabilir.'
                    : (!_isWorkerInAssignedShift(user)
                        ? 'Vardiya süresi sona erdi. Çalışanlar vardiya saatleri dışında kayıtları düzenleyemezler.'
                        : 'Bu kaydı düzenleme izniniz yok.'),
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textHint,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            Row(
              children: [
                if (canEdit)
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.edit_outlined,
                      label: 'Düzenle',
                      iconColor: AppColors.textSecondary,
                      textColor: AppColors.textPrimary,
                      onTap: () => _showEditDialog(record),
                    ),
                  ),
                if (canEdit && canCancel) const SizedBox(width: 10),
                if (canCancel)
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.cancel_outlined,
                      label: 'İptal et',
                      iconColor: AppColors.error,
                      textColor: AppColors.error,
                      onTap: () => _confirmCancel(record),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildRecordMetaDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        width: 1,
        height: 34,
        color: AppColors.border.withValues(alpha: 0.8),
      ),
    );
  }

  Widget _buildRecordMetaMetric({
    required String title,
    required String value,
    String? imageRef,
  }) {
    final hasImage = imageRef != null && imageRef.isNotEmpty;

    if (hasImage) {
      return Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(6),
            ),
            clipBehavior: Clip.antiAlias,
            child: _buildPatternImage(imageRef),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textHint,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Resim yoksa normal metin gösterimi
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textHint,
            fontWeight: FontWeight.w600,
            fontSize: 10,
            letterSpacing: 0.5,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildPatternImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return _buildPatternPlaceholder();
    }

    final localFile = _localPatternImageFile(imageUrl);
    if (localFile != null) {
      return Image.file(
        localFile,
        fit: BoxFit.cover, //
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => _buildPatternPlaceholder(),
      );
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover, //
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, __, ___) => _buildPatternPlaceholder(),
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

  Widget _buildPatternPlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      alignment: Alignment.center,
      child: const Icon(
        Icons.grid_view_rounded,
        color: AppColors.textHint,
        size: 14,
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color iconColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(ProductionModel record) {
    final editQtyController = TextEditingController(text: '${record.quantity}');
    final editNotesController =
        TextEditingController(text: _cleanNotesForDisplay(record));
    int? selectedQuality = _recordQualityLevel(record);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: [
              const Icon(Icons.edit, color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              Text('Kaydı Düzenle', style: AppTypography.headlineSmall),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Adet',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                TextFormField(
                  controller: editQtyController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Kalite',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                DropdownButtonFormField<int>(
                  initialValue: selectedQuality,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('1.kalite')),
                    DropdownMenuItem(value: 2, child: Text('2.kalite')),
                    DropdownMenuItem(value: 3, child: Text('3.kalite')),
                    DropdownMenuItem(value: 4, child: Text('Endüstriyel')),
                  ],
                  onChanged: (value) {
                    setDialogState(() => selectedQuality = value);
                  },
                ),
                const SizedBox(height: 10),
                Text(
                  'Not',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                TextFormField(
                  controller: editNotesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newQty =
                    int.tryParse(editQtyController.text) ?? record.quantity;
                final newNotes = editNotesController.text.trim();
                final newQuality = selectedQuality;

                final currentNotes = _cleanNotesForDisplay(record).trim();
                final currentQuality = _recordQualityLevel(record);
                final hasChanges = newQty != record.quantity ||
                    newQuality != currentQuality ||
                    newNotes != currentNotes;

                if (!hasChanges) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Değişiklik yok'),
                        backgroundColor: AppColors.textHint,
                      ),
                    );
                  }
                  return;
                }

                Navigator.pop(ctx);

                final currentUser = ref.read(authProvider).user;
                final role = currentUser?.role;
                if (role == 'worker' &&
                    !_isWorkerInAssignedShift(currentUser)) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Vardiya süresi sona erdi. Şu anda kayıt güncelleyemezsiniz.',
                        ),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                  return;
                }

                final isOnlineNow =
                    await ref.read(networkInfoProvider).isConnected;
                if (mounted) {
                  setState(() => _isOnline = isOnlineNow);
                }

                var success = false;
                if ((role == 'admin' || role == 'supervisor') &&
                    isOnlineNow &&
                    record.id != null) {
                  success = await ref
                      .read(productionProvider.notifier)
                      .updateProduction(
                    record.id!,
                    {
                      'quantity': newQty,
                      'quality': newQuality,
                      'notes': newNotes,
                    },
                  );
                } else {
                  final operationId = record.operationId ?? record.id;
                  if (operationId != null) {
                    success = await ref
                        .read(productionEntryProvider.notifier)
                        .updateEntry(
                          operationId: operationId,
                          quantity: newQty,
                          quality: newQuality,
                          notes: newNotes,
                        );
                  }
                }

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success ? 'Kayıt güncellendi' : 'Güncelleme başarısız',
                      ),
                      backgroundColor:
                          success ? AppColors.success : AppColors.error,
                    ),
                  );
                  _loadHistory(page: _currentPage);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child:
                  const Text('Kaydet', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmCancel(ProductionModel record) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            const Icon(Icons.cancel_outlined, color: AppColors.error, size: 22),
            const SizedBox(width: 8),
            Text('Kaydı iptal et', style: AppTypography.headlineSmall),
          ],
        ),
        content: Text(
          'Bu üretim kaydını iptal etmek istediğinize emin misiniz?',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                if (record.id != null) {
                  final success = await ref
                      .read(productionProvider.notifier)
                      .cancelProduction(record.id!);

                  if (success) {
                    final db = ref.read(databaseProvider);
                    final operationId = record.operationId;
                    if (operationId != null && operationId.isNotEmpty) {
                      await db.deleteProductionEntryByOperationId(operationId);
                      await db.removeSyncItemsByOperationId(
                        operationId,
                        entryType: 'production',
                      );
                    }
                    await db.deleteProductionEntryByServerId(record.id!);
                  }

                  messenger?.showSnackBar(
                    SnackBar(
                      content: Text(
                        success ? 'Kayıt iptal edildi' : 'İptal etme başarısız',
                      ),
                      backgroundColor:
                          success ? AppColors.success : AppColors.error,
                    ),
                  );

                  if (mounted) {
                    await _loadHistory(page: _currentPage);
                  }
                  return;
                }

                messenger?.showSnackBar(
                  const SnackBar(
                    content: Text('Bu kayıt henüz senkronize edilmedi'),
                    backgroundColor: AppColors.error,
                  ),
                );
              } catch (_) {
                messenger?.showSnackBar(
                  const SnackBar(
                    content: Text('İptal etme başarısız'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child:
                const Text('İptal et', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _currentPage > 1
                ? () => _loadHistory(page: _currentPage - 1)
                : null,
            icon: const Icon(Icons.chevron_left),
            color: AppColors.primary,
          ),
          Text(
            '$_currentPage / $_totalPages',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            onPressed: _currentPage < _totalPages
                ? () => _loadHistory(page: _currentPage + 1)
                : null,
            icon: const Icon(Icons.chevron_right),
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
