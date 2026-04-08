import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/shift_utils.dart';
import '../../data/database/app_database.dart';
import 'auth_provider.dart';
import 'service_providers.dart';

// ── Sync Status ──

class SyncState {
  final bool isSyncing;
  final int pendingCount;
  final int failedCount;
  final String? lastError;

  const SyncState({
    this.isSyncing = false,
    this.pendingCount = 0,
    this.failedCount = 0,
    this.lastError,
  });

  SyncState copyWith({
    bool? isSyncing,
    int? pendingCount,
    int? failedCount,
    String? lastError,
  }) =>
      SyncState(
        isSyncing: isSyncing ?? this.isSyncing,
        pendingCount: pendingCount ?? this.pendingCount,
        failedCount: failedCount ?? this.failedCount,
        lastError: lastError,
      );
}

class AppPageIds {
  AppPageIds._();

  static const String entryForm = 'entry_form';
  static const String workerHistory = 'worker_history';
  static const String dailyReport = 'daily_report';
  static const String settings = 'settings';
}

class PageRefreshState {
  final Map<String, int> pageEnterEpoch;
  final int syncEpoch;

  const PageRefreshState({
    this.pageEnterEpoch = const {},
    this.syncEpoch = 0,
  });

  int tokenFor(String pageId) => (pageEnterEpoch[pageId] ?? 0) + syncEpoch;

  PageRefreshState copyWith({
    Map<String, int>? pageEnterEpoch,
    int? syncEpoch,
  }) {
    return PageRefreshState(
      pageEnterEpoch: pageEnterEpoch ?? this.pageEnterEpoch,
      syncEpoch: syncEpoch ?? this.syncEpoch,
    );
  }
}

class PageRefreshNotifier extends StateNotifier<PageRefreshState> {
  PageRefreshNotifier() : super(const PageRefreshState());

  void markPageEntered(String pageId) {
    final next = Map<String, int>.from(state.pageEnterEpoch);
    next[pageId] = (next[pageId] ?? 0) + 1;
    state = state.copyWith(pageEnterEpoch: next);
  }

  void markSyncCompleted() {
    state = state.copyWith(syncEpoch: state.syncEpoch + 1);
  }
}

final pageRefreshProvider =
    StateNotifierProvider<PageRefreshNotifier, PageRefreshState>(
  (ref) => PageRefreshNotifier(),
);

final pageRefreshTokenProvider = Provider.family<int, String>((ref, pageId) {
  final state = ref.watch(pageRefreshProvider);
  return state.tokenFor(pageId);
});

class SyncNotifier extends StateNotifier<SyncState> {
  final Ref _ref;
  StreamSubscription? _connectivitySub;

  SyncNotifier(this._ref) : super(const SyncState()) {
    _bootstrap();
    _listenConnectivity();
  }

  Future<void> _bootstrap() async {
    await refreshCounts();
    await triggerSyncIfPossible();
  }

  void _listenConnectivity() {
    _connectivitySub = _ref
        .read(networkInfoProvider)
        .onConnectionStatusChanged
        .listen((connected) async {
      await refreshCounts();
      if (connected) {
        await triggerSyncIfPossible();
      }
    });
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }

  Future<void> refreshCounts() async {
    final db = _ref.read(databaseProvider);
    final pending = await db.getPendingSyncCount();
    final failed = await db.getFailedSyncCount();
    state = state.copyWith(pendingCount: pending, failedCount: failed);
  }

  Future<void> triggerSyncIfPossible() async {
    if (state.isSyncing || state.pendingCount <= 0) return;
    final connected = await _ref.read(networkInfoProvider).isConnected;
    if (!connected) return;
    await triggerSync();
  }

  Future<void> triggerSync() async {
    if (state.isSyncing) return;
    state = state.copyWith(isSyncing: true);
    try {
      final result = await _ref.read(syncServiceProvider).syncAll();
      state = state.copyWith(
        isSyncing: false,
        lastError: result.hasFailures
            ? '${result.failed} kayıt senkronize edilemedi'
            : null,
      );
      await refreshCounts();
      _ref.read(pageRefreshProvider.notifier).markSyncCompleted();
    } catch (e) {
      state = state.copyWith(isSyncing: false, lastError: e.toString());
    }
  }
}

final syncProvider = StateNotifierProvider<SyncNotifier, SyncState>(
  SyncNotifier.new,
);

// ── Production Entries (local-first) ──

class ProductionEntryListState {
  final bool isLoading;
  final List<ProductionEntry> entries;
  final String? errorMessage;

  const ProductionEntryListState({
    this.isLoading = false,
    this.entries = const [],
    this.errorMessage,
  });

  ProductionEntryListState copyWith({
    bool? isLoading,
    List<ProductionEntry>? entries,
    String? errorMessage,
  }) =>
      ProductionEntryListState(
        isLoading: isLoading ?? this.isLoading,
        entries: entries ?? this.entries,
        errorMessage: errorMessage,
      );
}

class ProductionEntryNotifier extends StateNotifier<ProductionEntryListState> {
  final Ref _ref;

  ProductionEntryNotifier(this._ref) : super(const ProductionEntryListState());

  Future<void> loadEntries(
      {String? userId, String? shift, String? stage}) async {
    state = state.copyWith(isLoading: true);
    try {
      final entries = await _ref.read(databaseProvider).getProductionEntries(
            userId: userId,
            shift: shift,
            stage: stage,
          );
      state = state.copyWith(isLoading: false, entries: entries);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> createEntry({
    required String productCode,
    required String productName,
    String? patternCode,
    String? machine,
    required int quantity,
    required String stage,
    required String userId,
    String? userName,
    int? quality,
    String? notes,
  }) async {
    try {
      final shiftRestriction = _workerShiftRestrictionMessage(_ref);
      if (shiftRestriction != null) {
        state = state.copyWith(errorMessage: shiftRestriction);
        return false;
      }
      await _ref.read(entryServiceProvider).createProductionEntry(
            productCode: productCode,
            productName: productName,
            patternCode: patternCode,
            machine: machine,
            quantity: quantity,
            stage: stage,
            userId: userId,
            userName: userName,
            quality: quality,
            notes: notes,
          );
      final syncNotifier = _ref.read(syncProvider.notifier);
      await syncNotifier.refreshCounts();
      await syncNotifier.triggerSyncIfPossible();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> updateEntry({
    required String operationId,
    int? quantity,
    int? quality,
    String? notes,
    String? machine,
  }) async {
    try {
      final shiftRestriction = _workerShiftRestrictionMessage(_ref);
      if (shiftRestriction != null) {
        state = state.copyWith(errorMessage: shiftRestriction);
        return false;
      }
      await _ref.read(entryServiceProvider).updateProductionEntry(
            operationId: operationId,
            quantity: quantity,
            quality: quality,
            notes: notes,
            machine: machine,
          );
      final syncNotifier = _ref.read(syncProvider.notifier);
      await syncNotifier.refreshCounts();
      await syncNotifier.triggerSyncIfPossible();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }
}

final productionEntryProvider =
    StateNotifierProvider<ProductionEntryNotifier, ProductionEntryListState>(
  ProductionEntryNotifier.new,
);

// ── Production stream ──

final productionEntryStreamProvider =
    StreamProvider.family<List<ProductionEntry>, String?>(
  (ref, userId) =>
      ref.read(databaseProvider).watchProductionEntries(userId: userId),
);

// ── Quality Entries ──

class QualityEntryListState {
  final bool isLoading;
  final List<QualityEntry> entries;
  final String? errorMessage;

  const QualityEntryListState({
    this.isLoading = false,
    this.entries = const [],
    this.errorMessage,
  });

  QualityEntryListState copyWith({
    bool? isLoading,
    List<QualityEntry>? entries,
    String? errorMessage,
  }) =>
      QualityEntryListState(
        isLoading: isLoading ?? this.isLoading,
        entries: entries ?? this.entries,
        errorMessage: errorMessage,
      );
}

class QualityEntryNotifier extends StateNotifier<QualityEntryListState> {
  final Ref _ref;

  QualityEntryNotifier(this._ref) : super(const QualityEntryListState());

  Future<void> loadEntries({String? userId}) async {
    state = state.copyWith(isLoading: true);
    try {
      final entries =
          await _ref.read(databaseProvider).getQualityEntries(userId: userId);
      state = state.copyWith(isLoading: false, entries: entries);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> createEntry({
    required String productCode,
    required String productName,
    String? patternCode,
    String? machine,
    required int quantity,
    String qualityGrade = 'A',
    String? defectNotes,
    required String userId,
    String? userName,
  }) async {
    try {
      final shiftRestriction = _workerShiftRestrictionMessage(_ref);
      if (shiftRestriction != null) {
        state = state.copyWith(errorMessage: shiftRestriction);
        return false;
      }
      await _ref.read(entryServiceProvider).createQualityEntry(
            productCode: productCode,
            productName: productName,
            patternCode: patternCode,
            machine: machine,
            quantity: quantity,
            qualityGrade: qualityGrade,
            defectNotes: defectNotes,
            userId: userId,
            userName: userName,
          );
      final syncNotifier = _ref.read(syncProvider.notifier);
      await syncNotifier.refreshCounts();
      await syncNotifier.triggerSyncIfPossible();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }
}

final qualityEntryProvider =
    StateNotifierProvider<QualityEntryNotifier, QualityEntryListState>(
  QualityEntryNotifier.new,
);

// ── Packaging Entries ──

class PackagingEntryListState {
  final bool isLoading;
  final List<PackagingEntry> entries;
  final String? errorMessage;

  const PackagingEntryListState({
    this.isLoading = false,
    this.entries = const [],
    this.errorMessage,
  });

  PackagingEntryListState copyWith({
    bool? isLoading,
    List<PackagingEntry>? entries,
    String? errorMessage,
  }) =>
      PackagingEntryListState(
        isLoading: isLoading ?? this.isLoading,
        entries: entries ?? this.entries,
        errorMessage: errorMessage,
      );
}

class PackagingEntryNotifier extends StateNotifier<PackagingEntryListState> {
  final Ref _ref;

  PackagingEntryNotifier(this._ref) : super(const PackagingEntryListState());

  Future<void> loadEntries({String? userId}) async {
    state = state.copyWith(isLoading: true);
    try {
      final entries =
          await _ref.read(databaseProvider).getPackagingEntries(userId: userId);
      state = state.copyWith(isLoading: false, entries: entries);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> createEntry({
    required String productCode,
    required String productName,
    String? patternCode,
    String? machine,
    required int quantity,
    required String packagingType,
    required String userId,
    String? userName,
  }) async {
    try {
      final shiftRestriction = _workerShiftRestrictionMessage(_ref);
      if (shiftRestriction != null) {
        state = state.copyWith(errorMessage: shiftRestriction);
        return false;
      }
      await _ref.read(entryServiceProvider).createPackagingEntry(
            productCode: productCode,
            productName: productName,
            patternCode: patternCode,
            machine: machine,
            quantity: quantity,
            packagingType: packagingType,
            userId: userId,
            userName: userName,
          );
      final syncNotifier = _ref.read(syncProvider.notifier);
      await syncNotifier.refreshCounts();
      await syncNotifier.triggerSyncIfPossible();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }
}

final packagingEntryProvider =
    StateNotifierProvider<PackagingEntryNotifier, PackagingEntryListState>(
  PackagingEntryNotifier.new,
);

// ── Shipment Entries ──

class ShipmentEntryListState {
  final bool isLoading;
  final List<ShipmentEntry> entries;
  final String? errorMessage;

  const ShipmentEntryListState({
    this.isLoading = false,
    this.entries = const [],
    this.errorMessage,
  });

  ShipmentEntryListState copyWith({
    bool? isLoading,
    List<ShipmentEntry>? entries,
    String? errorMessage,
  }) =>
      ShipmentEntryListState(
        isLoading: isLoading ?? this.isLoading,
        entries: entries ?? this.entries,
        errorMessage: errorMessage,
      );
}

class ShipmentEntryNotifier extends StateNotifier<ShipmentEntryListState> {
  final Ref _ref;

  ShipmentEntryNotifier(this._ref) : super(const ShipmentEntryListState());

  Future<void> loadEntries({String? userId}) async {
    state = state.copyWith(isLoading: true);
    try {
      final entries =
          await _ref.read(databaseProvider).getShipmentEntries(userId: userId);
      state = state.copyWith(isLoading: false, entries: entries);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> createEntry({
    required String productCode,
    required String productName,
    String? patternCode,
    required int quantity,
    required String destination,
    required String userId,
    String? userName,
  }) async {
    try {
      final shiftRestriction = _workerShiftRestrictionMessage(_ref);
      if (shiftRestriction != null) {
        state = state.copyWith(errorMessage: shiftRestriction);
        return false;
      }
      await _ref.read(entryServiceProvider).createShipmentEntry(
            productCode: productCode,
            productName: productName,
            patternCode: patternCode,
            quantity: quantity,
            destination: destination,
            userId: userId,
            userName: userName,
          );
      final syncNotifier = _ref.read(syncProvider.notifier);
      await syncNotifier.refreshCounts();
      await syncNotifier.triggerSyncIfPossible();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }
}

final shipmentEntryProvider =
    StateNotifierProvider<ShipmentEntryNotifier, ShipmentEntryListState>(
  ShipmentEntryNotifier.new,
);

// ── Combined Recent Records ──

final recentRecordsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String?>((ref, userId) {
  return ref.read(databaseProvider).getRecentRecords(userId: userId, limit: 50);
});

// ── Products / Machines (cached reference data) ──

final cachedProductsProvider = FutureProvider<List<Product>>((ref) {
  return ref.read(databaseProvider).getAllProducts();
});

final cachedPatternsProvider = FutureProvider<List<Pattern>>((ref) {
  return ref.read(databaseProvider).getAllPatterns();
});

final machinesByStageProvider =
    FutureProvider.family<List<Machine>, String>((ref, stage) {
  return ref.read(databaseProvider).getMachinesByStage(stage);
});
String? _workerShiftRestrictionMessage(Ref ref) {
  final user = ref.read(authProvider).user;
  if (user == null || user.role != 'worker') return null;

  final assignedShift = user.assignedShift.trim();
  if (assignedShift.isEmpty) {
    return 'Bu çalışan için atanmış vardiya tanımlanmamış.';
  }

  if (!isUserInShift(assignedShift)) {
    return 'Vardiya süresi sona erdi. Şu anda kayıt oluşturamaz veya güncelleyemezsiniz.';
  }

  return null;
}
