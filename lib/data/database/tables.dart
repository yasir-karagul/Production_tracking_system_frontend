import 'package:drift/drift.dart';

class Users extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get username => text()();
  TextColumn get role => text()(); // worker, supervisor, admin
  TextColumn get assignedShift =>
      text().withDefault(const Constant('Shift 1'))();
  TextColumn get assignedStage => text().nullable()();
  DateTimeColumn get cachedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class Products extends Table {
  TextColumn get id => text()();
  TextColumn get productCode => text()();
  TextColumn get productName => text()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get cachedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class Patterns extends Table {
  TextColumn get id => text()();
  TextColumn get patternCode => text()();
  TextColumn get patternName => text()();
  TextColumn get thumbnailUrl => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get cachedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class Machines extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get stage => text()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get cachedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class ProductionEntries extends Table {
  TextColumn get operationId => text()();
  TextColumn get productCode => text()();
  TextColumn get productName => text()();
  TextColumn get patternCode => text().nullable()();
  TextColumn get machine => text().nullable()();
  IntColumn get quantity => integer()();
  TextColumn get stage => text()();
  TextColumn get shift => text()();
  TextColumn get userId => text()();
  TextColumn get userName => text().nullable()();
  IntColumn get quality => integer().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  TextColumn get serverId => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {operationId};
}

class QualityEntries extends Table {
  TextColumn get operationId => text()();
  TextColumn get productCode => text()();
  TextColumn get productName => text()();
  TextColumn get patternCode => text().nullable()();
  TextColumn get machine => text().nullable()();
  IntColumn get quantity => integer()();
  TextColumn get qualityGrade => text().withDefault(const Constant('A'))();
  TextColumn get defectNotes => text().nullable()();
  TextColumn get shift => text()();
  TextColumn get userId => text()();
  TextColumn get userName => text().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  TextColumn get serverId => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {operationId};
}

class PackagingEntries extends Table {
  TextColumn get operationId => text()();
  TextColumn get productCode => text()();
  TextColumn get productName => text()();
  TextColumn get patternCode => text().nullable()();
  TextColumn get machine => text().nullable()();
  IntColumn get quantity => integer()();
  TextColumn get packagingType => text().withDefault(const Constant(''))();
  TextColumn get shift => text()();
  TextColumn get userId => text()();
  TextColumn get userName => text().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  TextColumn get serverId => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {operationId};
}

class ShipmentEntries extends Table {
  TextColumn get operationId => text()();
  TextColumn get productCode => text()();
  TextColumn get productName => text()();
  TextColumn get patternCode => text().nullable()();
  IntColumn get quantity => integer()();
  TextColumn get destination => text().withDefault(const Constant(''))();
  TextColumn get shift => text()();
  TextColumn get userId => text()();
  TextColumn get userName => text().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  TextColumn get serverId => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {operationId};
}

class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get operationId => text().unique()();
  TextColumn get entryType =>
      text()(); // production, quality, packaging, shipment, product, pattern, *excel_import
  TextColumn get action => text()(); // create, update, delete
  TextColumn get payload => text()(); // JSON
  TextColumn get status => text().withDefault(const Constant('pending'))();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get errorMessage => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastAttempt => dateTime().nullable()();
  DateTimeColumn get nextRetryAt => dateTime().nullable()();
}
