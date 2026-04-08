import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  Users,
  Products,
  Patterns,
  Machines,
  ProductionEntries,
  QualityEntries,
  PackagingEntries,
  ShipmentEntries,
  SyncQueue,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase._() : super(_openConnection());

  static AppDatabase? _instance;
  static AppDatabase get instance => _instance ??= AppDatabase._();

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (migrator, from, to) async {
          if (from < 2) {
            await migrator.addColumn(syncQueue, syncQueue.nextRetryAt);
            // operationId unique constraint is handled at insert level
          }
          if (from < 3) {
            await customStatement(
                'ALTER TABLE production_entries DROP COLUMN cart_number');
          }
          if (from < 4) {
            await migrator.addColumn(
                productionEntries, productionEntries.quality);
          }
        },
      );

  // ── Users ──

  Future<void> upsertUser(UsersCompanion user) =>
      into(users).insertOnConflictUpdate(user);

  Future<User?> getUserById(String id) =>
      (select(users)..where((t) => t.id.equals(id))).getSingleOrNull();

  // ── Products ──

  Future<void> upsertProduct(ProductsCompanion product) =>
      into(products).insertOnConflictUpdate(product);

  Future<List<Product>> getAllProducts() =>
      (select(products)..where((t) => t.isActive.equals(true))).get();

  Future<Product?> getProductById(String id) =>
      (select(products)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<Product?> getProductByCode(String code) =>
      (select(products)..where((t) => t.productCode.equals(code)))
          .getSingleOrNull();

  Future<void> deleteProductById(String id) =>
      (delete(products)..where((t) => t.id.equals(id))).go();

  Future<void> markProductInactiveById(String id) =>
      (update(products)..where((t) => t.id.equals(id))).write(
        const ProductsCompanion(isActive: Value(false)),
      );

  // ── Patterns ──

  Future<void> upsertPattern(PatternsCompanion pattern) =>
      into(patterns).insertOnConflictUpdate(pattern);

  Future<List<Pattern>> getAllPatterns() =>
      (select(patterns)..where((t) => t.isActive.equals(true))).get();

  Future<Pattern?> getPatternById(String id) =>
      (select(patterns)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<Pattern?> getPatternByCode(String code) =>
      (select(patterns)..where((t) => t.patternCode.equals(code)))
          .getSingleOrNull();

  Future<void> deletePatternById(String id) =>
      (delete(patterns)..where((t) => t.id.equals(id))).go();

  Future<void> markPatternInactiveById(String id) =>
      (update(patterns)..where((t) => t.id.equals(id))).write(
        const PatternsCompanion(isActive: Value(false)),
      );

  Future<List<Pattern>> searchPatterns(String query) {
    final q = '%$query%';
    return (select(patterns)
          ..where((t) => t.patternCode.like(q) | t.patternName.like(q))
          ..where((t) => t.isActive.equals(true)))
        .get();
  }

  // ── Machines ──

  Future<void> upsertMachine(MachinesCompanion machine) =>
      into(machines).insertOnConflictUpdate(machine);

  Future<List<Machine>> getMachinesByStage(String stage) => (select(machines)
        ..where((t) => t.stage.equals(stage))
        ..where((t) => t.isActive.equals(true)))
      .get();

  Future<List<Machine>> getAllMachines() =>
      (select(machines)..where((t) => t.isActive.equals(true))).get();

  // ── Production Entries ──

  Future<void> insertProductionEntry(ProductionEntriesCompanion entry) =>
      into(productionEntries).insert(entry);

  Future<void> updateProductionEntry(
          String opId, ProductionEntriesCompanion entry) =>
      (update(productionEntries)..where((t) => t.operationId.equals(opId)))
          .write(entry);

  Future<ProductionEntry?> getProductionEntry(String opId) =>
      (select(productionEntries)..where((t) => t.operationId.equals(opId)))
          .getSingleOrNull();

  Future<void> deleteProductionEntryByOperationId(String opId) =>
      (delete(productionEntries)..where((t) => t.operationId.equals(opId)))
          .go();

  Future<void> deleteProductionEntryByServerId(String serverId) =>
      (delete(productionEntries)..where((t) => t.serverId.equals(serverId)))
          .go();

  Future<ProductionEntry?> findProductionEntryByServerId(
      String serverId) async {
    final rows = await (select(productionEntries)
          ..where((t) => t.serverId.equals(serverId))
          ..orderBy([
            (t) => OrderingTerm.desc(t.updatedAt),
            (t) => OrderingTerm.desc(t.createdAt),
          ]))
        .get();
    if (rows.isEmpty) return null;

    for (final row in rows) {
      if (row.operationId == serverId) return row;
    }
    for (final row in rows) {
      if (row.syncStatus != 'synced') return row;
    }
    return rows.first;
  }

  Future<List<ProductionEntry>> getProductionEntries({
    String? shift,
    String? stage,
    String? userId,
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    final q = select(productionEntries);
    if (shift != null) q.where((t) => t.shift.equals(shift));
    if (stage != null) q.where((t) => t.stage.equals(stage));
    if (userId != null) q.where((t) => t.userId.equals(userId));
    if (fromDate != null) {
      q.where((t) => t.createdAt.isBiggerOrEqualValue(fromDate));
    }
    if (toDate != null) {
      q.where((t) => t.createdAt.isSmallerOrEqualValue(toDate));
    }
    q.orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return q.get();
  }

  Stream<List<ProductionEntry>> watchProductionEntries({String? userId}) {
    final q = select(productionEntries);
    if (userId != null) q.where((t) => t.userId.equals(userId));
    q.orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return q.watch();
  }

  Future<void> markProductionSynced(String opId, String serverId) =>
      (update(productionEntries)..where((t) => t.operationId.equals(opId)))
          .write(ProductionEntriesCompanion(
        syncStatus: const Value('synced'),
        serverId: Value(serverId),
      ));

  /// Generic helper to mark any entry type as synced.
  Future<void> markEntrySynced(String entryType, String operationId,
      [String? serverId]) async {
    switch (entryType) {
      case 'production':
        if (serverId != null && serverId.isNotEmpty) {
          await markProductionSynced(operationId, serverId);
        } else {
          await (update(productionEntries)
                ..where((t) => t.operationId.equals(operationId)))
              .write(const ProductionEntriesCompanion(
                  syncStatus: Value('synced')));
        }
      case 'quality':
        await (update(qualityEntries)
              ..where((t) => t.operationId.equals(operationId)))
            .write(QualityEntriesCompanion(
          syncStatus: const Value('synced'),
          serverId: serverId != null ? Value(serverId) : const Value.absent(),
        ));
      case 'packaging':
        await (update(packagingEntries)
              ..where((t) => t.operationId.equals(operationId)))
            .write(PackagingEntriesCompanion(
          syncStatus: const Value('synced'),
          serverId: serverId != null ? Value(serverId) : const Value.absent(),
        ));
      case 'shipment':
        await (update(shipmentEntries)
              ..where((t) => t.operationId.equals(operationId)))
            .write(ShipmentEntriesCompanion(
          syncStatus: const Value('synced'),
          serverId: serverId != null ? Value(serverId) : const Value.absent(),
        ));
    }
  }

  /// Mark a local entry as failed.
  Future<void> markEntryFailed(String entryType, String operationId) async {
    switch (entryType) {
      case 'production':
        await (update(productionEntries)
              ..where((t) => t.operationId.equals(operationId)))
            .write(
                const ProductionEntriesCompanion(syncStatus: Value('failed')));
      case 'quality':
        await (update(qualityEntries)
              ..where((t) => t.operationId.equals(operationId)))
            .write(const QualityEntriesCompanion(syncStatus: Value('failed')));
      case 'packaging':
        await (update(packagingEntries)
              ..where((t) => t.operationId.equals(operationId)))
            .write(
                const PackagingEntriesCompanion(syncStatus: Value('failed')));
      case 'shipment':
        await (update(shipmentEntries)
              ..where((t) => t.operationId.equals(operationId)))
            .write(const ShipmentEntriesCompanion(syncStatus: Value('failed')));
    }
  }

  /// Batch-mark local entries as syncing.
  Future<void> markEntriesSyncing(List<SyncQueueData> items) async {
    await batch((b) {
      for (final item in items) {
        switch (item.entryType) {
          case 'production':
            b.replace(
                productionEntries,
                ProductionEntriesCompanion(
                  operationId: Value(item.operationId),
                  syncStatus: const Value('syncing'),
                ));
          default:
            break;
        }
      }
    });
  }

  // ── Quality Entries ──

  Future<void> insertQualityEntry(QualityEntriesCompanion entry) =>
      into(qualityEntries).insert(entry);

  Future<void> updateQualityEntry(String opId, QualityEntriesCompanion entry) =>
      (update(qualityEntries)..where((t) => t.operationId.equals(opId)))
          .write(entry);

  Future<QualityEntry?> getQualityEntry(String opId) =>
      (select(qualityEntries)..where((t) => t.operationId.equals(opId)))
          .getSingleOrNull();

  Future<List<QualityEntry>> getQualityEntries({
    String? userId,
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    final q = select(qualityEntries);
    if (userId != null) q.where((t) => t.userId.equals(userId));
    if (fromDate != null) {
      q.where((t) => t.createdAt.isBiggerOrEqualValue(fromDate));
    }
    if (toDate != null) {
      q.where((t) => t.createdAt.isSmallerOrEqualValue(toDate));
    }
    q.orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return q.get();
  }

  Stream<List<QualityEntry>> watchQualityEntries({String? userId}) {
    final q = select(qualityEntries);
    if (userId != null) q.where((t) => t.userId.equals(userId));
    q.orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return q.watch();
  }

  // ── Packaging Entries ──

  Future<void> insertPackagingEntry(PackagingEntriesCompanion entry) =>
      into(packagingEntries).insert(entry);

  Future<void> updatePackagingEntry(
          String opId, PackagingEntriesCompanion entry) =>
      (update(packagingEntries)..where((t) => t.operationId.equals(opId)))
          .write(entry);

  Future<PackagingEntry?> getPackagingEntry(String opId) =>
      (select(packagingEntries)..where((t) => t.operationId.equals(opId)))
          .getSingleOrNull();

  Future<List<PackagingEntry>> getPackagingEntries({
    String? userId,
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    final q = select(packagingEntries);
    if (userId != null) q.where((t) => t.userId.equals(userId));
    if (fromDate != null) {
      q.where((t) => t.createdAt.isBiggerOrEqualValue(fromDate));
    }
    if (toDate != null) {
      q.where((t) => t.createdAt.isSmallerOrEqualValue(toDate));
    }
    q.orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return q.get();
  }

  Stream<List<PackagingEntry>> watchPackagingEntries({String? userId}) {
    final q = select(packagingEntries);
    if (userId != null) q.where((t) => t.userId.equals(userId));
    q.orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return q.watch();
  }

  // ── Shipment Entries ──

  Future<void> insertShipmentEntry(ShipmentEntriesCompanion entry) =>
      into(shipmentEntries).insert(entry);

  Future<void> updateShipmentEntry(
          String opId, ShipmentEntriesCompanion entry) =>
      (update(shipmentEntries)..where((t) => t.operationId.equals(opId)))
          .write(entry);

  Future<ShipmentEntry?> getShipmentEntry(String opId) =>
      (select(shipmentEntries)..where((t) => t.operationId.equals(opId)))
          .getSingleOrNull();

  Future<List<ShipmentEntry>> getShipmentEntries({
    String? userId,
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    final q = select(shipmentEntries);
    if (userId != null) q.where((t) => t.userId.equals(userId));
    if (fromDate != null) {
      q.where((t) => t.createdAt.isBiggerOrEqualValue(fromDate));
    }
    if (toDate != null) {
      q.where((t) => t.createdAt.isSmallerOrEqualValue(toDate));
    }
    q.orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return q.get();
  }

  Stream<List<ShipmentEntry>> watchShipmentEntries({String? userId}) {
    final q = select(shipmentEntries);
    if (userId != null) q.where((t) => t.userId.equals(userId));
    q.orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return q.watch();
  }

  // ── Sync Queue ──

  String _mergeQueuePayload(String existingPayload, String incomingPayload) {
    final merged = <String, dynamic>{};
    try {
      merged
          .addAll((jsonDecode(existingPayload) as Map).cast<String, dynamic>());
    } catch (_) {
      // Keep going with incoming payload if existing payload is malformed.
    }
    try {
      merged
          .addAll((jsonDecode(incomingPayload) as Map).cast<String, dynamic>());
    } catch (_) {
      return incomingPayload;
    }
    return jsonEncode(merged);
  }

  /// Insert or merge into sync queue by operationId to avoid dropped offline edits.
  Future<void> addToSyncQueue(SyncQueueCompanion item) async {
    final opId = item.operationId.present ? item.operationId.value : null;
    if (opId == null || opId.isEmpty) return;

    final incomingAction = item.action.present ? item.action.value : 'create';
    final incomingPayload = item.payload.present ? item.payload.value : '{}';
    final now = DateTime.now();

    final existing = await (select(syncQueue)
          ..where((t) => t.operationId.equals(opId)))
        .getSingleOrNull();

    if (existing == null) {
      await into(syncQueue).insert(item);
      return;
    }

    // Merge logic by action precedence for the same operation_id.
    var nextAction = existing.action;
    var nextPayload = existing.payload;

    if (existing.action == 'create') {
      if (incomingAction == 'update' || incomingAction == 'create') {
        nextAction = 'create';
        nextPayload = _mergeQueuePayload(existing.payload, incomingPayload);
      } else if (incomingAction == 'delete') {
        // Created offline then deleted before sync: no-op on server.
        await removeSyncItem(existing.id);
        return;
      }
    } else if (existing.action == 'update') {
      if (incomingAction == 'update') {
        nextAction = 'update';
        nextPayload = _mergeQueuePayload(existing.payload, incomingPayload);
      } else if (incomingAction == 'delete') {
        nextAction = 'delete';
        nextPayload = incomingPayload;
      }
    } else if (existing.action == 'delete') {
      // Delete is terminal for this operation_id until synced.
      nextAction = 'delete';
      nextPayload = existing.payload;
    } else {
      nextAction = incomingAction;
      nextPayload = incomingPayload;
    }

    await updateSyncItem(
      existing.id,
      SyncQueueCompanion(
        action: Value(nextAction),
        payload: Value(nextPayload),
        status: const Value('pending'),
        retryCount: const Value(0),
        errorMessage: const Value(null),
        lastAttempt: Value(now),
        nextRetryAt: const Value(null),
      ),
    );
  }

  /// Fetch items ready for sync: pending or failed with retryCount < 5
  /// and nextRetryAt in the past (exponential backoff).
  Future<List<SyncQueueData>> getPendingSyncItems() {
    final now = DateTime.now();
    return (select(syncQueue)
          ..where((t) =>
              (t.status.equals('pending') | t.status.equals('failed')) &
              t.retryCount.isSmallerThanValue(5) &
              (t.nextRetryAt.isNull() |
                  t.nextRetryAt.isSmallerOrEqualValue(now)))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  Future<void> updateSyncItem(int id, SyncQueueCompanion item) =>
      (update(syncQueue)..where((t) => t.id.equals(id))).write(item);

  Future<void> removeSyncItem(int id) =>
      (delete(syncQueue)..where((t) => t.id.equals(id))).go();

  Future<void> removeSyncItemsByOperationId(
    String operationId, {
    String? entryType,
  }) {
    if (entryType == null) {
      return (delete(syncQueue)
            ..where((t) => t.operationId.equals(operationId)))
          .go();
    }

    return (delete(syncQueue)
          ..where((t) =>
              t.operationId.equals(operationId) &
              t.entryType.equals(entryType)))
        .go();
  }

  Future<int> getPendingSyncCount() async {
    final count = countAll();
    final query = selectOnly(syncQueue)
      ..where(syncQueue.status.equals('pending') |
          syncQueue.status.equals('failed'))
      ..addColumns([count]);
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  Future<int> getFailedSyncCount() async {
    final count = countAll();
    final query = selectOnly(syncQueue)
      ..where(syncQueue.status.equals('failed'))
      ..addColumns([count]);
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  // ── Recent Records (all types combined) ──

  Future<List<Map<String, dynamic>>> getRecentRecords({
    String? userId,
    String? stage,
    String? syncStatus,
    int limit = 50,
  }) async {
    final results = <Map<String, dynamic>>[];

    // Production
    final prodQuery = select(productionEntries);
    if (userId != null) prodQuery.where((t) => t.userId.equals(userId));
    if (stage != null) prodQuery.where((t) => t.stage.equals(stage));
    if (syncStatus != null) {
      prodQuery.where((t) => t.syncStatus.equals(syncStatus));
    }
    prodQuery.orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    prodQuery.limit(limit);
    final prods = await prodQuery.get();
    for (final p in prods) {
      results.add({
        'type': 'production',
        'operationId': p.operationId,
        'productCode': p.productCode,
        'productName': p.productName,
        'patternCode': p.patternCode,
        'machine': p.machine,
        'quantity': p.quantity,
        'quality': p.quality,
        'shift': p.shift,
        'syncStatus': p.syncStatus,
        'createdAt': p.createdAt.toIso8601String(),
        'stage': p.stage,
      });
    }

    // Quality
    final qualQuery = select(qualityEntries);
    if (userId != null) qualQuery.where((t) => t.userId.equals(userId));
    if (syncStatus != null) {
      qualQuery.where((t) => t.syncStatus.equals(syncStatus));
    }
    qualQuery.orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    qualQuery.limit(limit);
    if (stage == null || stage == 'Kalite Kontrol') {
      final quals = await qualQuery.get();
      for (final q in quals) {
        results.add({
          'type': 'quality',
          'operationId': q.operationId,
          'productCode': q.productCode,
          'productName': q.productName,
          'patternCode': q.patternCode,
          'machine': q.machine,
          'quantity': q.quantity,
          'shift': q.shift,
          'syncStatus': q.syncStatus,
          'createdAt': q.createdAt.toIso8601String(),
          'stage': 'Kalite Kontrol',
        });
      }
    }

    // Packaging
    final packQuery = select(packagingEntries);
    if (userId != null) packQuery.where((t) => t.userId.equals(userId));
    if (syncStatus != null) {
      packQuery.where((t) => t.syncStatus.equals(syncStatus));
    }
    packQuery.orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    packQuery.limit(limit);
    if (stage == null || stage == 'Paketleme') {
      final packs = await packQuery.get();
      for (final pk in packs) {
        results.add({
          'type': 'packaging',
          'operationId': pk.operationId,
          'productCode': pk.productCode,
          'productName': pk.productName,
          'patternCode': pk.patternCode,
          'machine': pk.machine,
          'quantity': pk.quantity,
          'shift': pk.shift,
          'syncStatus': pk.syncStatus,
          'createdAt': pk.createdAt.toIso8601String(),
          'stage': 'Paketleme',
        });
      }
    }

    // Shipment
    final shipQuery = select(shipmentEntries);
    if (userId != null) shipQuery.where((t) => t.userId.equals(userId));
    if (syncStatus != null) {
      shipQuery.where((t) => t.syncStatus.equals(syncStatus));
    }
    shipQuery.orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    shipQuery.limit(limit);
    if (stage == null || stage == 'Sevkiyat') {
      final ships = await shipQuery.get();
      for (final s in ships) {
        results.add({
          'type': 'shipment',
          'operationId': s.operationId,
          'productCode': s.productCode,
          'productName': s.productName,
          'patternCode': s.patternCode,
          'quantity': s.quantity,
          'shift': s.shift,
          'syncStatus': s.syncStatus,
          'createdAt': s.createdAt.toIso8601String(),
          'stage': 'Sevkiyat',
        });
      }
    }

    results.sort((a, b) => DateTime.parse(b['createdAt'])
        .compareTo(DateTime.parse(a['createdAt'])));
    return results.take(limit).toList();
  }

  // ── Bulk cache ──

  Future<void> cacheProducts(List<Map<String, dynamic>> items) async {
    await batch((b) {
      for (final item in items) {
        b.insert(
          products,
          ProductsCompanion.insert(
            id: item['_id'] ?? item['id'] ?? '',
            productCode: item['product_code'] ??
                item['productCode'] ??
                item['code'] ??
                '',
            productName: item['product_name'] ??
                item['productName'] ??
                item['name'] ??
                '',
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<void> cachePatterns(List<Map<String, dynamic>> items) async {
    await batch((b) {
      for (final item in items) {
        b.insert(
          patterns,
          PatternsCompanion.insert(
            id: item['_id'] ?? item['id'] ?? '',
            patternCode: item['pattern_code'] ??
                item['patternCode'] ??
                item['code'] ??
                '',
            patternName: item['pattern_name'] ??
                item['patternName'] ??
                item['name'] ??
                '',
            thumbnailUrl: Value(item['local_image_path'] ??
                item['localImagePath'] ??
                item['thumbnail_url'] ??
                item['thumbnailUrl'] ??
                item['image_url'] ??
                item['imageUrl']),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<void> cacheMachines(List<Map<String, dynamic>> items) async {
    await batch((b) {
      for (final item in items) {
        b.insert(
          machines,
          MachinesCompanion.insert(
            id: item['_id'] ?? item['id'] ?? '',
            name: item['name'] ?? '',
            stage: item['stage'] ?? '',
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<void> reconcileCatalogCreate({
    required String entryType,
    required String operationId,
    String? serverId,
    required Map<String, dynamic> payload,
  }) async {
    final resolvedId =
        (serverId != null && serverId.isNotEmpty) ? serverId : operationId;

    if (entryType == 'product') {
      final code = (payload['code'] ?? '').toString().trim().toUpperCase();
      final name = (payload['name'] ?? '').toString().trim();
      if (code.isNotEmpty && name.isNotEmpty) {
        await into(products).insertOnConflictUpdate(
          ProductsCompanion.insert(
            id: resolvedId,
            productCode: code,
            productName: name,
            isActive: const Value(true),
            cachedAt: Value(DateTime.now()),
          ),
        );
      }
      if (resolvedId != operationId) {
        await (delete(products)..where((t) => t.id.equals(operationId))).go();
      }
      return;
    }

    if (entryType == 'pattern') {
      final code = (payload['code'] ?? '').toString().trim().toUpperCase();
      final name = (payload['name'] ?? '').toString().trim();
      final imageRef = (payload['image_url'] ??
              payload['thumbnail_url'] ??
              payload['local_image_path'])
          ?.toString();

      if (code.isNotEmpty && name.isNotEmpty) {
        await into(patterns).insertOnConflictUpdate(
          PatternsCompanion.insert(
            id: resolvedId,
            patternCode: code,
            patternName: name,
            thumbnailUrl: Value(
              imageRef != null && imageRef.isNotEmpty ? imageRef : null,
            ),
            isActive: const Value(true),
            cachedAt: Value(DateTime.now()),
          ),
        );
      }
      if (resolvedId != operationId) {
        await (delete(patterns)..where((t) => t.id.equals(operationId))).go();
      }
    }
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'maia_porselen.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
