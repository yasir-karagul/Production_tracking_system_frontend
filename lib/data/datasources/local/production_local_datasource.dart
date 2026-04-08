import 'dart:convert';
import '../../../data/database/app_database.dart';
import '../../models/production_model.dart';
import 'package:drift/drift.dart';

/// Local cache for offline production records and sync queue.
/// Now backed by Drift (SQLite) instead of Hive.
class ProductionLocalDataSource {
  final AppDatabase _db = AppDatabase.instance;

  Future<void> init() async {
    // No-op: Drift database is initialized as a singleton
  }

  // ---- Cached Productions ----

  Future<void> cacheProductions(List<ProductionModel> productions) async {
    // Store into Drift ProductionEntries table as synced records
    await _db.batch((batch) {
      for (final p in productions) {
        final operationId = p.operationId ??
            p.id ??
            DateTime.now().millisecondsSinceEpoch.toString();
        batch.insert(
          _db.productionEntries,
          ProductionEntriesCompanion.insert(
            operationId: operationId,
            productCode: p.productCode,
            productName: p.productName,
            patternCode: Value(p.designCode),
            machine: Value(p.machine),
            quantity: p.quantity,
            stage: p.stage,
            shift: p.shift,
            userId: p.userId,
            userName: Value(p.userName),
            quality: Value(p.quality),
            notes: Value(p.notes),
            syncStatus: const Value('synced'),
            serverId: Value(p.id),
            createdAt: Value(p.createdAt ?? DateTime.now()),
            updatedAt: Value(p.updatedAt),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<List<ProductionModel>> getCachedProductions() async {
    final entries = await _db.getProductionEntries();
    return entries
        .map((e) => ProductionModel(
              id: e.serverId,
              operationId: e.operationId,
              productName: e.productName,
              productCode: e.productCode,
              designCode: e.patternCode ?? '',
              stage: e.stage,
              machine: e.machine,
              quantity: e.quantity,
              shift: e.shift,
              userId: e.userId,
              userName: e.userName,
              quality: e.quality,
              notes: e.notes,
              localSyncStatus: e.syncStatus,
              createdAt: e.createdAt,
              updatedAt: e.updatedAt,
            ))
        .toList();
  }

  // ---- Sync Queue (Offline-created records) ----

  Future<void> addToSyncQueue(Map<String, dynamic> productionData) async {
    final key =
        (productionData['operation_id'] ?? productionData['operationId'])
                ?.toString() ??
            DateTime.now().millisecondsSinceEpoch.toString();
    productionData['_localId'] = key;
    await _db.addToSyncQueue(SyncQueueCompanion.insert(
      operationId: key,
      entryType: 'production',
      action: 'create',
      payload: jsonEncode(productionData),
      createdAt: Value(DateTime.now()),
    ));
  }

  Future<List<Map<String, dynamic>>> getPendingSyncItems() async {
    final items = await _db.getPendingSyncItems();
    return items.map((item) {
      final payload = jsonDecode(item.payload) as Map<String, dynamic>;
      payload['_localId'] = item.operationId;
      return payload;
    }).toList();
  }

  Future<void> removeSyncItem(String localId) async {
    final items = await _db.getPendingSyncItems();
    for (final item in items) {
      if (item.operationId == localId) {
        await _db.removeSyncItem(item.id);
        break;
      }
    }
  }

  Future<void> clearSyncQueue() async {
    final items = await _db.getPendingSyncItems();
    for (final item in items) {
      await _db.removeSyncItem(item.id);
    }
  }

  Future<int> get pendingSyncCount => _db.getPendingSyncCount();
}
