// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $UsersTable extends Users with TableInfo<$UsersTable, User> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _usernameMeta =
      const VerificationMeta('username');
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
      'username', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
      'role', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _assignedShiftMeta =
      const VerificationMeta('assignedShift');
  @override
  late final GeneratedColumn<String> assignedShift = GeneratedColumn<String>(
      'assigned_shift', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('Shift 1'));
  static const VerificationMeta _assignedStageMeta =
      const VerificationMeta('assignedStage');
  @override
  late final GeneratedColumn<String> assignedStage = GeneratedColumn<String>(
      'assigned_stage', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _cachedAtMeta =
      const VerificationMeta('cachedAt');
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
      'cached_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, username, role, assignedShift, assignedStage, cachedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'users';
  @override
  VerificationContext validateIntegrity(Insertable<User> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('username')) {
      context.handle(_usernameMeta,
          username.isAcceptableOrUnknown(data['username']!, _usernameMeta));
    } else if (isInserting) {
      context.missing(_usernameMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
          _roleMeta, role.isAcceptableOrUnknown(data['role']!, _roleMeta));
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('assigned_shift')) {
      context.handle(
          _assignedShiftMeta,
          assignedShift.isAcceptableOrUnknown(
              data['assigned_shift']!, _assignedShiftMeta));
    }
    if (data.containsKey('assigned_stage')) {
      context.handle(
          _assignedStageMeta,
          assignedStage.isAcceptableOrUnknown(
              data['assigned_stage']!, _assignedStageMeta));
    }
    if (data.containsKey('cached_at')) {
      context.handle(_cachedAtMeta,
          cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  User map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return User(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      username: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}username'])!,
      role: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}role'])!,
      assignedShift: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}assigned_shift'])!,
      assignedStage: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}assigned_stage']),
      cachedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}cached_at'])!,
    );
  }

  @override
  $UsersTable createAlias(String alias) {
    return $UsersTable(attachedDatabase, alias);
  }
}

class User extends DataClass implements Insertable<User> {
  final String id;
  final String name;
  final String username;
  final String role;
  final String assignedShift;
  final String? assignedStage;
  final DateTime cachedAt;
  const User(
      {required this.id,
      required this.name,
      required this.username,
      required this.role,
      required this.assignedShift,
      this.assignedStage,
      required this.cachedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['username'] = Variable<String>(username);
    map['role'] = Variable<String>(role);
    map['assigned_shift'] = Variable<String>(assignedShift);
    if (!nullToAbsent || assignedStage != null) {
      map['assigned_stage'] = Variable<String>(assignedStage);
    }
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  UsersCompanion toCompanion(bool nullToAbsent) {
    return UsersCompanion(
      id: Value(id),
      name: Value(name),
      username: Value(username),
      role: Value(role),
      assignedShift: Value(assignedShift),
      assignedStage: assignedStage == null && nullToAbsent
          ? const Value.absent()
          : Value(assignedStage),
      cachedAt: Value(cachedAt),
    );
  }

  factory User.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return User(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      username: serializer.fromJson<String>(json['username']),
      role: serializer.fromJson<String>(json['role']),
      assignedShift: serializer.fromJson<String>(json['assignedShift']),
      assignedStage: serializer.fromJson<String?>(json['assignedStage']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'username': serializer.toJson<String>(username),
      'role': serializer.toJson<String>(role),
      'assignedShift': serializer.toJson<String>(assignedShift),
      'assignedStage': serializer.toJson<String?>(assignedStage),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  User copyWith(
          {String? id,
          String? name,
          String? username,
          String? role,
          String? assignedShift,
          Value<String?> assignedStage = const Value.absent(),
          DateTime? cachedAt}) =>
      User(
        id: id ?? this.id,
        name: name ?? this.name,
        username: username ?? this.username,
        role: role ?? this.role,
        assignedShift: assignedShift ?? this.assignedShift,
        assignedStage:
            assignedStage.present ? assignedStage.value : this.assignedStage,
        cachedAt: cachedAt ?? this.cachedAt,
      );
  User copyWithCompanion(UsersCompanion data) {
    return User(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      username: data.username.present ? data.username.value : this.username,
      role: data.role.present ? data.role.value : this.role,
      assignedShift: data.assignedShift.present
          ? data.assignedShift.value
          : this.assignedShift,
      assignedStage: data.assignedStage.present
          ? data.assignedStage.value
          : this.assignedStage,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('User(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('username: $username, ')
          ..write('role: $role, ')
          ..write('assignedShift: $assignedShift, ')
          ..write('assignedStage: $assignedStage, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, name, username, role, assignedShift, assignedStage, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is User &&
          other.id == this.id &&
          other.name == this.name &&
          other.username == this.username &&
          other.role == this.role &&
          other.assignedShift == this.assignedShift &&
          other.assignedStage == this.assignedStage &&
          other.cachedAt == this.cachedAt);
}

class UsersCompanion extends UpdateCompanion<User> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> username;
  final Value<String> role;
  final Value<String> assignedShift;
  final Value<String?> assignedStage;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const UsersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.username = const Value.absent(),
    this.role = const Value.absent(),
    this.assignedShift = const Value.absent(),
    this.assignedStage = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UsersCompanion.insert({
    required String id,
    required String name,
    required String username,
    required String role,
    this.assignedShift = const Value.absent(),
    this.assignedStage = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        username = Value(username),
        role = Value(role);
  static Insertable<User> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? username,
    Expression<String>? role,
    Expression<String>? assignedShift,
    Expression<String>? assignedStage,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (username != null) 'username': username,
      if (role != null) 'role': role,
      if (assignedShift != null) 'assigned_shift': assignedShift,
      if (assignedStage != null) 'assigned_stage': assignedStage,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UsersCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? username,
      Value<String>? role,
      Value<String>? assignedShift,
      Value<String?>? assignedStage,
      Value<DateTime>? cachedAt,
      Value<int>? rowid}) {
    return UsersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      role: role ?? this.role,
      assignedShift: assignedShift ?? this.assignedShift,
      assignedStage: assignedStage ?? this.assignedStage,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (assignedShift.present) {
      map['assigned_shift'] = Variable<String>(assignedShift.value);
    }
    if (assignedStage.present) {
      map['assigned_stage'] = Variable<String>(assignedStage.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('username: $username, ')
          ..write('role: $role, ')
          ..write('assignedShift: $assignedShift, ')
          ..write('assignedStage: $assignedStage, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProductsTable extends Products with TableInfo<$ProductsTable, Product> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _productCodeMeta =
      const VerificationMeta('productCode');
  @override
  late final GeneratedColumn<String> productCode = GeneratedColumn<String>(
      'product_code', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _productNameMeta =
      const VerificationMeta('productName');
  @override
  late final GeneratedColumn<String> productName = GeneratedColumn<String>(
      'product_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _cachedAtMeta =
      const VerificationMeta('cachedAt');
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
      'cached_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, productCode, productName, isActive, cachedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'products';
  @override
  VerificationContext validateIntegrity(Insertable<Product> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('product_code')) {
      context.handle(
          _productCodeMeta,
          productCode.isAcceptableOrUnknown(
              data['product_code']!, _productCodeMeta));
    } else if (isInserting) {
      context.missing(_productCodeMeta);
    }
    if (data.containsKey('product_name')) {
      context.handle(
          _productNameMeta,
          productName.isAcceptableOrUnknown(
              data['product_name']!, _productNameMeta));
    } else if (isInserting) {
      context.missing(_productNameMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('cached_at')) {
      context.handle(_cachedAtMeta,
          cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Product map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Product(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      productCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}product_code'])!,
      productName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}product_name'])!,
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      cachedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}cached_at'])!,
    );
  }

  @override
  $ProductsTable createAlias(String alias) {
    return $ProductsTable(attachedDatabase, alias);
  }
}

class Product extends DataClass implements Insertable<Product> {
  final String id;
  final String productCode;
  final String productName;
  final bool isActive;
  final DateTime cachedAt;
  const Product(
      {required this.id,
      required this.productCode,
      required this.productName,
      required this.isActive,
      required this.cachedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['product_code'] = Variable<String>(productCode);
    map['product_name'] = Variable<String>(productName);
    map['is_active'] = Variable<bool>(isActive);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  ProductsCompanion toCompanion(bool nullToAbsent) {
    return ProductsCompanion(
      id: Value(id),
      productCode: Value(productCode),
      productName: Value(productName),
      isActive: Value(isActive),
      cachedAt: Value(cachedAt),
    );
  }

  factory Product.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Product(
      id: serializer.fromJson<String>(json['id']),
      productCode: serializer.fromJson<String>(json['productCode']),
      productName: serializer.fromJson<String>(json['productName']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'productCode': serializer.toJson<String>(productCode),
      'productName': serializer.toJson<String>(productName),
      'isActive': serializer.toJson<bool>(isActive),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  Product copyWith(
          {String? id,
          String? productCode,
          String? productName,
          bool? isActive,
          DateTime? cachedAt}) =>
      Product(
        id: id ?? this.id,
        productCode: productCode ?? this.productCode,
        productName: productName ?? this.productName,
        isActive: isActive ?? this.isActive,
        cachedAt: cachedAt ?? this.cachedAt,
      );
  Product copyWithCompanion(ProductsCompanion data) {
    return Product(
      id: data.id.present ? data.id.value : this.id,
      productCode:
          data.productCode.present ? data.productCode.value : this.productCode,
      productName:
          data.productName.present ? data.productName.value : this.productName,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Product(')
          ..write('id: $id, ')
          ..write('productCode: $productCode, ')
          ..write('productName: $productName, ')
          ..write('isActive: $isActive, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, productCode, productName, isActive, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Product &&
          other.id == this.id &&
          other.productCode == this.productCode &&
          other.productName == this.productName &&
          other.isActive == this.isActive &&
          other.cachedAt == this.cachedAt);
}

class ProductsCompanion extends UpdateCompanion<Product> {
  final Value<String> id;
  final Value<String> productCode;
  final Value<String> productName;
  final Value<bool> isActive;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const ProductsCompanion({
    this.id = const Value.absent(),
    this.productCode = const Value.absent(),
    this.productName = const Value.absent(),
    this.isActive = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductsCompanion.insert({
    required String id,
    required String productCode,
    required String productName,
    this.isActive = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        productCode = Value(productCode),
        productName = Value(productName);
  static Insertable<Product> custom({
    Expression<String>? id,
    Expression<String>? productCode,
    Expression<String>? productName,
    Expression<bool>? isActive,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (productCode != null) 'product_code': productCode,
      if (productName != null) 'product_name': productName,
      if (isActive != null) 'is_active': isActive,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductsCompanion copyWith(
      {Value<String>? id,
      Value<String>? productCode,
      Value<String>? productName,
      Value<bool>? isActive,
      Value<DateTime>? cachedAt,
      Value<int>? rowid}) {
    return ProductsCompanion(
      id: id ?? this.id,
      productCode: productCode ?? this.productCode,
      productName: productName ?? this.productName,
      isActive: isActive ?? this.isActive,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (productCode.present) {
      map['product_code'] = Variable<String>(productCode.value);
    }
    if (productName.present) {
      map['product_name'] = Variable<String>(productName.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductsCompanion(')
          ..write('id: $id, ')
          ..write('productCode: $productCode, ')
          ..write('productName: $productName, ')
          ..write('isActive: $isActive, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PatternsTable extends Patterns with TableInfo<$PatternsTable, Pattern> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PatternsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _patternCodeMeta =
      const VerificationMeta('patternCode');
  @override
  late final GeneratedColumn<String> patternCode = GeneratedColumn<String>(
      'pattern_code', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _patternNameMeta =
      const VerificationMeta('patternName');
  @override
  late final GeneratedColumn<String> patternName = GeneratedColumn<String>(
      'pattern_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _thumbnailUrlMeta =
      const VerificationMeta('thumbnailUrl');
  @override
  late final GeneratedColumn<String> thumbnailUrl = GeneratedColumn<String>(
      'thumbnail_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _cachedAtMeta =
      const VerificationMeta('cachedAt');
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
      'cached_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, patternCode, patternName, thumbnailUrl, isActive, cachedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'patterns';
  @override
  VerificationContext validateIntegrity(Insertable<Pattern> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('pattern_code')) {
      context.handle(
          _patternCodeMeta,
          patternCode.isAcceptableOrUnknown(
              data['pattern_code']!, _patternCodeMeta));
    } else if (isInserting) {
      context.missing(_patternCodeMeta);
    }
    if (data.containsKey('pattern_name')) {
      context.handle(
          _patternNameMeta,
          patternName.isAcceptableOrUnknown(
              data['pattern_name']!, _patternNameMeta));
    } else if (isInserting) {
      context.missing(_patternNameMeta);
    }
    if (data.containsKey('thumbnail_url')) {
      context.handle(
          _thumbnailUrlMeta,
          thumbnailUrl.isAcceptableOrUnknown(
              data['thumbnail_url']!, _thumbnailUrlMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('cached_at')) {
      context.handle(_cachedAtMeta,
          cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Pattern map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Pattern(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      patternCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}pattern_code'])!,
      patternName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}pattern_name'])!,
      thumbnailUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}thumbnail_url']),
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      cachedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}cached_at'])!,
    );
  }

  @override
  $PatternsTable createAlias(String alias) {
    return $PatternsTable(attachedDatabase, alias);
  }
}

class Pattern extends DataClass implements Insertable<Pattern> {
  final String id;
  final String patternCode;
  final String patternName;
  final String? thumbnailUrl;
  final bool isActive;
  final DateTime cachedAt;
  const Pattern(
      {required this.id,
      required this.patternCode,
      required this.patternName,
      this.thumbnailUrl,
      required this.isActive,
      required this.cachedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['pattern_code'] = Variable<String>(patternCode);
    map['pattern_name'] = Variable<String>(patternName);
    if (!nullToAbsent || thumbnailUrl != null) {
      map['thumbnail_url'] = Variable<String>(thumbnailUrl);
    }
    map['is_active'] = Variable<bool>(isActive);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  PatternsCompanion toCompanion(bool nullToAbsent) {
    return PatternsCompanion(
      id: Value(id),
      patternCode: Value(patternCode),
      patternName: Value(patternName),
      thumbnailUrl: thumbnailUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbnailUrl),
      isActive: Value(isActive),
      cachedAt: Value(cachedAt),
    );
  }

  factory Pattern.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Pattern(
      id: serializer.fromJson<String>(json['id']),
      patternCode: serializer.fromJson<String>(json['patternCode']),
      patternName: serializer.fromJson<String>(json['patternName']),
      thumbnailUrl: serializer.fromJson<String?>(json['thumbnailUrl']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'patternCode': serializer.toJson<String>(patternCode),
      'patternName': serializer.toJson<String>(patternName),
      'thumbnailUrl': serializer.toJson<String?>(thumbnailUrl),
      'isActive': serializer.toJson<bool>(isActive),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  Pattern copyWith(
          {String? id,
          String? patternCode,
          String? patternName,
          Value<String?> thumbnailUrl = const Value.absent(),
          bool? isActive,
          DateTime? cachedAt}) =>
      Pattern(
        id: id ?? this.id,
        patternCode: patternCode ?? this.patternCode,
        patternName: patternName ?? this.patternName,
        thumbnailUrl:
            thumbnailUrl.present ? thumbnailUrl.value : this.thumbnailUrl,
        isActive: isActive ?? this.isActive,
        cachedAt: cachedAt ?? this.cachedAt,
      );
  Pattern copyWithCompanion(PatternsCompanion data) {
    return Pattern(
      id: data.id.present ? data.id.value : this.id,
      patternCode:
          data.patternCode.present ? data.patternCode.value : this.patternCode,
      patternName:
          data.patternName.present ? data.patternName.value : this.patternName,
      thumbnailUrl: data.thumbnailUrl.present
          ? data.thumbnailUrl.value
          : this.thumbnailUrl,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Pattern(')
          ..write('id: $id, ')
          ..write('patternCode: $patternCode, ')
          ..write('patternName: $patternName, ')
          ..write('thumbnailUrl: $thumbnailUrl, ')
          ..write('isActive: $isActive, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, patternCode, patternName, thumbnailUrl, isActive, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Pattern &&
          other.id == this.id &&
          other.patternCode == this.patternCode &&
          other.patternName == this.patternName &&
          other.thumbnailUrl == this.thumbnailUrl &&
          other.isActive == this.isActive &&
          other.cachedAt == this.cachedAt);
}

class PatternsCompanion extends UpdateCompanion<Pattern> {
  final Value<String> id;
  final Value<String> patternCode;
  final Value<String> patternName;
  final Value<String?> thumbnailUrl;
  final Value<bool> isActive;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const PatternsCompanion({
    this.id = const Value.absent(),
    this.patternCode = const Value.absent(),
    this.patternName = const Value.absent(),
    this.thumbnailUrl = const Value.absent(),
    this.isActive = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PatternsCompanion.insert({
    required String id,
    required String patternCode,
    required String patternName,
    this.thumbnailUrl = const Value.absent(),
    this.isActive = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        patternCode = Value(patternCode),
        patternName = Value(patternName);
  static Insertable<Pattern> custom({
    Expression<String>? id,
    Expression<String>? patternCode,
    Expression<String>? patternName,
    Expression<String>? thumbnailUrl,
    Expression<bool>? isActive,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (patternCode != null) 'pattern_code': patternCode,
      if (patternName != null) 'pattern_name': patternName,
      if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
      if (isActive != null) 'is_active': isActive,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PatternsCompanion copyWith(
      {Value<String>? id,
      Value<String>? patternCode,
      Value<String>? patternName,
      Value<String?>? thumbnailUrl,
      Value<bool>? isActive,
      Value<DateTime>? cachedAt,
      Value<int>? rowid}) {
    return PatternsCompanion(
      id: id ?? this.id,
      patternCode: patternCode ?? this.patternCode,
      patternName: patternName ?? this.patternName,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      isActive: isActive ?? this.isActive,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (patternCode.present) {
      map['pattern_code'] = Variable<String>(patternCode.value);
    }
    if (patternName.present) {
      map['pattern_name'] = Variable<String>(patternName.value);
    }
    if (thumbnailUrl.present) {
      map['thumbnail_url'] = Variable<String>(thumbnailUrl.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PatternsCompanion(')
          ..write('id: $id, ')
          ..write('patternCode: $patternCode, ')
          ..write('patternName: $patternName, ')
          ..write('thumbnailUrl: $thumbnailUrl, ')
          ..write('isActive: $isActive, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MachinesTable extends Machines with TableInfo<$MachinesTable, Machine> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MachinesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _stageMeta = const VerificationMeta('stage');
  @override
  late final GeneratedColumn<String> stage = GeneratedColumn<String>(
      'stage', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _cachedAtMeta =
      const VerificationMeta('cachedAt');
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
      'cached_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [id, name, stage, isActive, cachedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'machines';
  @override
  VerificationContext validateIntegrity(Insertable<Machine> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('stage')) {
      context.handle(
          _stageMeta, stage.isAcceptableOrUnknown(data['stage']!, _stageMeta));
    } else if (isInserting) {
      context.missing(_stageMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('cached_at')) {
      context.handle(_cachedAtMeta,
          cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Machine map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Machine(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      stage: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}stage'])!,
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      cachedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}cached_at'])!,
    );
  }

  @override
  $MachinesTable createAlias(String alias) {
    return $MachinesTable(attachedDatabase, alias);
  }
}

class Machine extends DataClass implements Insertable<Machine> {
  final String id;
  final String name;
  final String stage;
  final bool isActive;
  final DateTime cachedAt;
  const Machine(
      {required this.id,
      required this.name,
      required this.stage,
      required this.isActive,
      required this.cachedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['stage'] = Variable<String>(stage);
    map['is_active'] = Variable<bool>(isActive);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  MachinesCompanion toCompanion(bool nullToAbsent) {
    return MachinesCompanion(
      id: Value(id),
      name: Value(name),
      stage: Value(stage),
      isActive: Value(isActive),
      cachedAt: Value(cachedAt),
    );
  }

  factory Machine.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Machine(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      stage: serializer.fromJson<String>(json['stage']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'stage': serializer.toJson<String>(stage),
      'isActive': serializer.toJson<bool>(isActive),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  Machine copyWith(
          {String? id,
          String? name,
          String? stage,
          bool? isActive,
          DateTime? cachedAt}) =>
      Machine(
        id: id ?? this.id,
        name: name ?? this.name,
        stage: stage ?? this.stage,
        isActive: isActive ?? this.isActive,
        cachedAt: cachedAt ?? this.cachedAt,
      );
  Machine copyWithCompanion(MachinesCompanion data) {
    return Machine(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      stage: data.stage.present ? data.stage.value : this.stage,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Machine(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('stage: $stage, ')
          ..write('isActive: $isActive, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, stage, isActive, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Machine &&
          other.id == this.id &&
          other.name == this.name &&
          other.stage == this.stage &&
          other.isActive == this.isActive &&
          other.cachedAt == this.cachedAt);
}

class MachinesCompanion extends UpdateCompanion<Machine> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> stage;
  final Value<bool> isActive;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const MachinesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.stage = const Value.absent(),
    this.isActive = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MachinesCompanion.insert({
    required String id,
    required String name,
    required String stage,
    this.isActive = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        stage = Value(stage);
  static Insertable<Machine> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? stage,
    Expression<bool>? isActive,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (stage != null) 'stage': stage,
      if (isActive != null) 'is_active': isActive,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MachinesCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? stage,
      Value<bool>? isActive,
      Value<DateTime>? cachedAt,
      Value<int>? rowid}) {
    return MachinesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      stage: stage ?? this.stage,
      isActive: isActive ?? this.isActive,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (stage.present) {
      map['stage'] = Variable<String>(stage.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MachinesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('stage: $stage, ')
          ..write('isActive: $isActive, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProductionEntriesTable extends ProductionEntries
    with TableInfo<$ProductionEntriesTable, ProductionEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductionEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _operationIdMeta =
      const VerificationMeta('operationId');
  @override
  late final GeneratedColumn<String> operationId = GeneratedColumn<String>(
      'operation_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _productCodeMeta =
      const VerificationMeta('productCode');
  @override
  late final GeneratedColumn<String> productCode = GeneratedColumn<String>(
      'product_code', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _productNameMeta =
      const VerificationMeta('productName');
  @override
  late final GeneratedColumn<String> productName = GeneratedColumn<String>(
      'product_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _patternCodeMeta =
      const VerificationMeta('patternCode');
  @override
  late final GeneratedColumn<String> patternCode = GeneratedColumn<String>(
      'pattern_code', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _machineMeta =
      const VerificationMeta('machine');
  @override
  late final GeneratedColumn<String> machine = GeneratedColumn<String>(
      'machine', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _quantityMeta =
      const VerificationMeta('quantity');
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
      'quantity', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _stageMeta = const VerificationMeta('stage');
  @override
  late final GeneratedColumn<String> stage = GeneratedColumn<String>(
      'stage', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _shiftMeta = const VerificationMeta('shift');
  @override
  late final GeneratedColumn<String> shift = GeneratedColumn<String>(
      'shift', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userNameMeta =
      const VerificationMeta('userName');
  @override
  late final GeneratedColumn<String> userName = GeneratedColumn<String>(
      'user_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _qualityMeta =
      const VerificationMeta('quality');
  @override
  late final GeneratedColumn<int> quality = GeneratedColumn<int>(
      'quality', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _syncStatusMeta =
      const VerificationMeta('syncStatus');
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
      'sync_status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('pending'));
  static const VerificationMeta _serverIdMeta =
      const VerificationMeta('serverId');
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
      'server_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        operationId,
        productCode,
        productName,
        patternCode,
        machine,
        quantity,
        stage,
        shift,
        userId,
        userName,
        quality,
        notes,
        syncStatus,
        serverId,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'production_entries';
  @override
  VerificationContext validateIntegrity(Insertable<ProductionEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('operation_id')) {
      context.handle(
          _operationIdMeta,
          operationId.isAcceptableOrUnknown(
              data['operation_id']!, _operationIdMeta));
    } else if (isInserting) {
      context.missing(_operationIdMeta);
    }
    if (data.containsKey('product_code')) {
      context.handle(
          _productCodeMeta,
          productCode.isAcceptableOrUnknown(
              data['product_code']!, _productCodeMeta));
    } else if (isInserting) {
      context.missing(_productCodeMeta);
    }
    if (data.containsKey('product_name')) {
      context.handle(
          _productNameMeta,
          productName.isAcceptableOrUnknown(
              data['product_name']!, _productNameMeta));
    } else if (isInserting) {
      context.missing(_productNameMeta);
    }
    if (data.containsKey('pattern_code')) {
      context.handle(
          _patternCodeMeta,
          patternCode.isAcceptableOrUnknown(
              data['pattern_code']!, _patternCodeMeta));
    }
    if (data.containsKey('machine')) {
      context.handle(_machineMeta,
          machine.isAcceptableOrUnknown(data['machine']!, _machineMeta));
    }
    if (data.containsKey('quantity')) {
      context.handle(_quantityMeta,
          quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta));
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('stage')) {
      context.handle(
          _stageMeta, stage.isAcceptableOrUnknown(data['stage']!, _stageMeta));
    } else if (isInserting) {
      context.missing(_stageMeta);
    }
    if (data.containsKey('shift')) {
      context.handle(
          _shiftMeta, shift.isAcceptableOrUnknown(data['shift']!, _shiftMeta));
    } else if (isInserting) {
      context.missing(_shiftMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('user_name')) {
      context.handle(_userNameMeta,
          userName.isAcceptableOrUnknown(data['user_name']!, _userNameMeta));
    }
    if (data.containsKey('quality')) {
      context.handle(_qualityMeta,
          quality.isAcceptableOrUnknown(data['quality']!, _qualityMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('sync_status')) {
      context.handle(
          _syncStatusMeta,
          syncStatus.isAcceptableOrUnknown(
              data['sync_status']!, _syncStatusMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(_serverIdMeta,
          serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {operationId};
  @override
  ProductionEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProductionEntry(
      operationId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}operation_id'])!,
      productCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}product_code'])!,
      productName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}product_name'])!,
      patternCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}pattern_code']),
      machine: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}machine']),
      quantity: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}quantity'])!,
      stage: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}stage'])!,
      shift: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}shift'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      userName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_name']),
      quality: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}quality']),
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      syncStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sync_status'])!,
      serverId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}server_id']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at']),
    );
  }

  @override
  $ProductionEntriesTable createAlias(String alias) {
    return $ProductionEntriesTable(attachedDatabase, alias);
  }
}

class ProductionEntry extends DataClass implements Insertable<ProductionEntry> {
  final String operationId;
  final String productCode;
  final String productName;
  final String? patternCode;
  final String? machine;
  final int quantity;
  final String stage;
  final String shift;
  final String userId;
  final String? userName;
  final int? quality;
  final String? notes;
  final String syncStatus;
  final String? serverId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  const ProductionEntry(
      {required this.operationId,
      required this.productCode,
      required this.productName,
      this.patternCode,
      this.machine,
      required this.quantity,
      required this.stage,
      required this.shift,
      required this.userId,
      this.userName,
      this.quality,
      this.notes,
      required this.syncStatus,
      this.serverId,
      required this.createdAt,
      this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['operation_id'] = Variable<String>(operationId);
    map['product_code'] = Variable<String>(productCode);
    map['product_name'] = Variable<String>(productName);
    if (!nullToAbsent || patternCode != null) {
      map['pattern_code'] = Variable<String>(patternCode);
    }
    if (!nullToAbsent || machine != null) {
      map['machine'] = Variable<String>(machine);
    }
    map['quantity'] = Variable<int>(quantity);
    map['stage'] = Variable<String>(stage);
    map['shift'] = Variable<String>(shift);
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || userName != null) {
      map['user_name'] = Variable<String>(userName);
    }
    if (!nullToAbsent || quality != null) {
      map['quality'] = Variable<int>(quality);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['sync_status'] = Variable<String>(syncStatus);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<String>(serverId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  ProductionEntriesCompanion toCompanion(bool nullToAbsent) {
    return ProductionEntriesCompanion(
      operationId: Value(operationId),
      productCode: Value(productCode),
      productName: Value(productName),
      patternCode: patternCode == null && nullToAbsent
          ? const Value.absent()
          : Value(patternCode),
      machine: machine == null && nullToAbsent
          ? const Value.absent()
          : Value(machine),
      quantity: Value(quantity),
      stage: Value(stage),
      shift: Value(shift),
      userId: Value(userId),
      userName: userName == null && nullToAbsent
          ? const Value.absent()
          : Value(userName),
      quality: quality == null && nullToAbsent
          ? const Value.absent()
          : Value(quality),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      syncStatus: Value(syncStatus),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      createdAt: Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory ProductionEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProductionEntry(
      operationId: serializer.fromJson<String>(json['operationId']),
      productCode: serializer.fromJson<String>(json['productCode']),
      productName: serializer.fromJson<String>(json['productName']),
      patternCode: serializer.fromJson<String?>(json['patternCode']),
      machine: serializer.fromJson<String?>(json['machine']),
      quantity: serializer.fromJson<int>(json['quantity']),
      stage: serializer.fromJson<String>(json['stage']),
      shift: serializer.fromJson<String>(json['shift']),
      userId: serializer.fromJson<String>(json['userId']),
      userName: serializer.fromJson<String?>(json['userName']),
      quality: serializer.fromJson<int?>(json['quality']),
      notes: serializer.fromJson<String?>(json['notes']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      serverId: serializer.fromJson<String?>(json['serverId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'operationId': serializer.toJson<String>(operationId),
      'productCode': serializer.toJson<String>(productCode),
      'productName': serializer.toJson<String>(productName),
      'patternCode': serializer.toJson<String?>(patternCode),
      'machine': serializer.toJson<String?>(machine),
      'quantity': serializer.toJson<int>(quantity),
      'stage': serializer.toJson<String>(stage),
      'shift': serializer.toJson<String>(shift),
      'userId': serializer.toJson<String>(userId),
      'userName': serializer.toJson<String?>(userName),
      'quality': serializer.toJson<int?>(quality),
      'notes': serializer.toJson<String?>(notes),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'serverId': serializer.toJson<String?>(serverId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  ProductionEntry copyWith(
          {String? operationId,
          String? productCode,
          String? productName,
          Value<String?> patternCode = const Value.absent(),
          Value<String?> machine = const Value.absent(),
          int? quantity,
          String? stage,
          String? shift,
          String? userId,
          Value<String?> userName = const Value.absent(),
          Value<int?> quality = const Value.absent(),
          Value<String?> notes = const Value.absent(),
          String? syncStatus,
          Value<String?> serverId = const Value.absent(),
          DateTime? createdAt,
          Value<DateTime?> updatedAt = const Value.absent()}) =>
      ProductionEntry(
        operationId: operationId ?? this.operationId,
        productCode: productCode ?? this.productCode,
        productName: productName ?? this.productName,
        patternCode: patternCode.present ? patternCode.value : this.patternCode,
        machine: machine.present ? machine.value : this.machine,
        quantity: quantity ?? this.quantity,
        stage: stage ?? this.stage,
        shift: shift ?? this.shift,
        userId: userId ?? this.userId,
        userName: userName.present ? userName.value : this.userName,
        quality: quality.present ? quality.value : this.quality,
        notes: notes.present ? notes.value : this.notes,
        syncStatus: syncStatus ?? this.syncStatus,
        serverId: serverId.present ? serverId.value : this.serverId,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
      );
  ProductionEntry copyWithCompanion(ProductionEntriesCompanion data) {
    return ProductionEntry(
      operationId:
          data.operationId.present ? data.operationId.value : this.operationId,
      productCode:
          data.productCode.present ? data.productCode.value : this.productCode,
      productName:
          data.productName.present ? data.productName.value : this.productName,
      patternCode:
          data.patternCode.present ? data.patternCode.value : this.patternCode,
      machine: data.machine.present ? data.machine.value : this.machine,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      stage: data.stage.present ? data.stage.value : this.stage,
      shift: data.shift.present ? data.shift.value : this.shift,
      userId: data.userId.present ? data.userId.value : this.userId,
      userName: data.userName.present ? data.userName.value : this.userName,
      quality: data.quality.present ? data.quality.value : this.quality,
      notes: data.notes.present ? data.notes.value : this.notes,
      syncStatus:
          data.syncStatus.present ? data.syncStatus.value : this.syncStatus,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProductionEntry(')
          ..write('operationId: $operationId, ')
          ..write('productCode: $productCode, ')
          ..write('productName: $productName, ')
          ..write('patternCode: $patternCode, ')
          ..write('machine: $machine, ')
          ..write('quantity: $quantity, ')
          ..write('stage: $stage, ')
          ..write('shift: $shift, ')
          ..write('userId: $userId, ')
          ..write('userName: $userName, ')
          ..write('quality: $quality, ')
          ..write('notes: $notes, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('serverId: $serverId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      operationId,
      productCode,
      productName,
      patternCode,
      machine,
      quantity,
      stage,
      shift,
      userId,
      userName,
      quality,
      notes,
      syncStatus,
      serverId,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductionEntry &&
          other.operationId == this.operationId &&
          other.productCode == this.productCode &&
          other.productName == this.productName &&
          other.patternCode == this.patternCode &&
          other.machine == this.machine &&
          other.quantity == this.quantity &&
          other.stage == this.stage &&
          other.shift == this.shift &&
          other.userId == this.userId &&
          other.userName == this.userName &&
          other.quality == this.quality &&
          other.notes == this.notes &&
          other.syncStatus == this.syncStatus &&
          other.serverId == this.serverId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ProductionEntriesCompanion extends UpdateCompanion<ProductionEntry> {
  final Value<String> operationId;
  final Value<String> productCode;
  final Value<String> productName;
  final Value<String?> patternCode;
  final Value<String?> machine;
  final Value<int> quantity;
  final Value<String> stage;
  final Value<String> shift;
  final Value<String> userId;
  final Value<String?> userName;
  final Value<int?> quality;
  final Value<String?> notes;
  final Value<String> syncStatus;
  final Value<String?> serverId;
  final Value<DateTime> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<int> rowid;
  const ProductionEntriesCompanion({
    this.operationId = const Value.absent(),
    this.productCode = const Value.absent(),
    this.productName = const Value.absent(),
    this.patternCode = const Value.absent(),
    this.machine = const Value.absent(),
    this.quantity = const Value.absent(),
    this.stage = const Value.absent(),
    this.shift = const Value.absent(),
    this.userId = const Value.absent(),
    this.userName = const Value.absent(),
    this.quality = const Value.absent(),
    this.notes = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.serverId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductionEntriesCompanion.insert({
    required String operationId,
    required String productCode,
    required String productName,
    this.patternCode = const Value.absent(),
    this.machine = const Value.absent(),
    required int quantity,
    required String stage,
    required String shift,
    required String userId,
    this.userName = const Value.absent(),
    this.quality = const Value.absent(),
    this.notes = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.serverId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : operationId = Value(operationId),
        productCode = Value(productCode),
        productName = Value(productName),
        quantity = Value(quantity),
        stage = Value(stage),
        shift = Value(shift),
        userId = Value(userId);
  static Insertable<ProductionEntry> custom({
    Expression<String>? operationId,
    Expression<String>? productCode,
    Expression<String>? productName,
    Expression<String>? patternCode,
    Expression<String>? machine,
    Expression<int>? quantity,
    Expression<String>? stage,
    Expression<String>? shift,
    Expression<String>? userId,
    Expression<String>? userName,
    Expression<int>? quality,
    Expression<String>? notes,
    Expression<String>? syncStatus,
    Expression<String>? serverId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (operationId != null) 'operation_id': operationId,
      if (productCode != null) 'product_code': productCode,
      if (productName != null) 'product_name': productName,
      if (patternCode != null) 'pattern_code': patternCode,
      if (machine != null) 'machine': machine,
      if (quantity != null) 'quantity': quantity,
      if (stage != null) 'stage': stage,
      if (shift != null) 'shift': shift,
      if (userId != null) 'user_id': userId,
      if (userName != null) 'user_name': userName,
      if (quality != null) 'quality': quality,
      if (notes != null) 'notes': notes,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (serverId != null) 'server_id': serverId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductionEntriesCompanion copyWith(
      {Value<String>? operationId,
      Value<String>? productCode,
      Value<String>? productName,
      Value<String?>? patternCode,
      Value<String?>? machine,
      Value<int>? quantity,
      Value<String>? stage,
      Value<String>? shift,
      Value<String>? userId,
      Value<String?>? userName,
      Value<int?>? quality,
      Value<String?>? notes,
      Value<String>? syncStatus,
      Value<String?>? serverId,
      Value<DateTime>? createdAt,
      Value<DateTime?>? updatedAt,
      Value<int>? rowid}) {
    return ProductionEntriesCompanion(
      operationId: operationId ?? this.operationId,
      productCode: productCode ?? this.productCode,
      productName: productName ?? this.productName,
      patternCode: patternCode ?? this.patternCode,
      machine: machine ?? this.machine,
      quantity: quantity ?? this.quantity,
      stage: stage ?? this.stage,
      shift: shift ?? this.shift,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      quality: quality ?? this.quality,
      notes: notes ?? this.notes,
      syncStatus: syncStatus ?? this.syncStatus,
      serverId: serverId ?? this.serverId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (operationId.present) {
      map['operation_id'] = Variable<String>(operationId.value);
    }
    if (productCode.present) {
      map['product_code'] = Variable<String>(productCode.value);
    }
    if (productName.present) {
      map['product_name'] = Variable<String>(productName.value);
    }
    if (patternCode.present) {
      map['pattern_code'] = Variable<String>(patternCode.value);
    }
    if (machine.present) {
      map['machine'] = Variable<String>(machine.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (stage.present) {
      map['stage'] = Variable<String>(stage.value);
    }
    if (shift.present) {
      map['shift'] = Variable<String>(shift.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (userName.present) {
      map['user_name'] = Variable<String>(userName.value);
    }
    if (quality.present) {
      map['quality'] = Variable<int>(quality.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductionEntriesCompanion(')
          ..write('operationId: $operationId, ')
          ..write('productCode: $productCode, ')
          ..write('productName: $productName, ')
          ..write('patternCode: $patternCode, ')
          ..write('machine: $machine, ')
          ..write('quantity: $quantity, ')
          ..write('stage: $stage, ')
          ..write('shift: $shift, ')
          ..write('userId: $userId, ')
          ..write('userName: $userName, ')
          ..write('quality: $quality, ')
          ..write('notes: $notes, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('serverId: $serverId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $QualityEntriesTable extends QualityEntries
    with TableInfo<$QualityEntriesTable, QualityEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QualityEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _operationIdMeta =
      const VerificationMeta('operationId');
  @override
  late final GeneratedColumn<String> operationId = GeneratedColumn<String>(
      'operation_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _productCodeMeta =
      const VerificationMeta('productCode');
  @override
  late final GeneratedColumn<String> productCode = GeneratedColumn<String>(
      'product_code', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _productNameMeta =
      const VerificationMeta('productName');
  @override
  late final GeneratedColumn<String> productName = GeneratedColumn<String>(
      'product_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _patternCodeMeta =
      const VerificationMeta('patternCode');
  @override
  late final GeneratedColumn<String> patternCode = GeneratedColumn<String>(
      'pattern_code', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _machineMeta =
      const VerificationMeta('machine');
  @override
  late final GeneratedColumn<String> machine = GeneratedColumn<String>(
      'machine', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _quantityMeta =
      const VerificationMeta('quantity');
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
      'quantity', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _qualityGradeMeta =
      const VerificationMeta('qualityGrade');
  @override
  late final GeneratedColumn<String> qualityGrade = GeneratedColumn<String>(
      'quality_grade', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('A'));
  static const VerificationMeta _defectNotesMeta =
      const VerificationMeta('defectNotes');
  @override
  late final GeneratedColumn<String> defectNotes = GeneratedColumn<String>(
      'defect_notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _shiftMeta = const VerificationMeta('shift');
  @override
  late final GeneratedColumn<String> shift = GeneratedColumn<String>(
      'shift', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userNameMeta =
      const VerificationMeta('userName');
  @override
  late final GeneratedColumn<String> userName = GeneratedColumn<String>(
      'user_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _syncStatusMeta =
      const VerificationMeta('syncStatus');
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
      'sync_status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('pending'));
  static const VerificationMeta _serverIdMeta =
      const VerificationMeta('serverId');
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
      'server_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        operationId,
        productCode,
        productName,
        patternCode,
        machine,
        quantity,
        qualityGrade,
        defectNotes,
        shift,
        userId,
        userName,
        syncStatus,
        serverId,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'quality_entries';
  @override
  VerificationContext validateIntegrity(Insertable<QualityEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('operation_id')) {
      context.handle(
          _operationIdMeta,
          operationId.isAcceptableOrUnknown(
              data['operation_id']!, _operationIdMeta));
    } else if (isInserting) {
      context.missing(_operationIdMeta);
    }
    if (data.containsKey('product_code')) {
      context.handle(
          _productCodeMeta,
          productCode.isAcceptableOrUnknown(
              data['product_code']!, _productCodeMeta));
    } else if (isInserting) {
      context.missing(_productCodeMeta);
    }
    if (data.containsKey('product_name')) {
      context.handle(
          _productNameMeta,
          productName.isAcceptableOrUnknown(
              data['product_name']!, _productNameMeta));
    } else if (isInserting) {
      context.missing(_productNameMeta);
    }
    if (data.containsKey('pattern_code')) {
      context.handle(
          _patternCodeMeta,
          patternCode.isAcceptableOrUnknown(
              data['pattern_code']!, _patternCodeMeta));
    }
    if (data.containsKey('machine')) {
      context.handle(_machineMeta,
          machine.isAcceptableOrUnknown(data['machine']!, _machineMeta));
    }
    if (data.containsKey('quantity')) {
      context.handle(_quantityMeta,
          quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta));
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('quality_grade')) {
      context.handle(
          _qualityGradeMeta,
          qualityGrade.isAcceptableOrUnknown(
              data['quality_grade']!, _qualityGradeMeta));
    }
    if (data.containsKey('defect_notes')) {
      context.handle(
          _defectNotesMeta,
          defectNotes.isAcceptableOrUnknown(
              data['defect_notes']!, _defectNotesMeta));
    }
    if (data.containsKey('shift')) {
      context.handle(
          _shiftMeta, shift.isAcceptableOrUnknown(data['shift']!, _shiftMeta));
    } else if (isInserting) {
      context.missing(_shiftMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('user_name')) {
      context.handle(_userNameMeta,
          userName.isAcceptableOrUnknown(data['user_name']!, _userNameMeta));
    }
    if (data.containsKey('sync_status')) {
      context.handle(
          _syncStatusMeta,
          syncStatus.isAcceptableOrUnknown(
              data['sync_status']!, _syncStatusMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(_serverIdMeta,
          serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {operationId};
  @override
  QualityEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QualityEntry(
      operationId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}operation_id'])!,
      productCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}product_code'])!,
      productName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}product_name'])!,
      patternCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}pattern_code']),
      machine: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}machine']),
      quantity: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}quantity'])!,
      qualityGrade: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}quality_grade'])!,
      defectNotes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}defect_notes']),
      shift: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}shift'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      userName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_name']),
      syncStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sync_status'])!,
      serverId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}server_id']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at']),
    );
  }

  @override
  $QualityEntriesTable createAlias(String alias) {
    return $QualityEntriesTable(attachedDatabase, alias);
  }
}

class QualityEntry extends DataClass implements Insertable<QualityEntry> {
  final String operationId;
  final String productCode;
  final String productName;
  final String? patternCode;
  final String? machine;
  final int quantity;
  final String qualityGrade;
  final String? defectNotes;
  final String shift;
  final String userId;
  final String? userName;
  final String syncStatus;
  final String? serverId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  const QualityEntry(
      {required this.operationId,
      required this.productCode,
      required this.productName,
      this.patternCode,
      this.machine,
      required this.quantity,
      required this.qualityGrade,
      this.defectNotes,
      required this.shift,
      required this.userId,
      this.userName,
      required this.syncStatus,
      this.serverId,
      required this.createdAt,
      this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['operation_id'] = Variable<String>(operationId);
    map['product_code'] = Variable<String>(productCode);
    map['product_name'] = Variable<String>(productName);
    if (!nullToAbsent || patternCode != null) {
      map['pattern_code'] = Variable<String>(patternCode);
    }
    if (!nullToAbsent || machine != null) {
      map['machine'] = Variable<String>(machine);
    }
    map['quantity'] = Variable<int>(quantity);
    map['quality_grade'] = Variable<String>(qualityGrade);
    if (!nullToAbsent || defectNotes != null) {
      map['defect_notes'] = Variable<String>(defectNotes);
    }
    map['shift'] = Variable<String>(shift);
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || userName != null) {
      map['user_name'] = Variable<String>(userName);
    }
    map['sync_status'] = Variable<String>(syncStatus);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<String>(serverId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  QualityEntriesCompanion toCompanion(bool nullToAbsent) {
    return QualityEntriesCompanion(
      operationId: Value(operationId),
      productCode: Value(productCode),
      productName: Value(productName),
      patternCode: patternCode == null && nullToAbsent
          ? const Value.absent()
          : Value(patternCode),
      machine: machine == null && nullToAbsent
          ? const Value.absent()
          : Value(machine),
      quantity: Value(quantity),
      qualityGrade: Value(qualityGrade),
      defectNotes: defectNotes == null && nullToAbsent
          ? const Value.absent()
          : Value(defectNotes),
      shift: Value(shift),
      userId: Value(userId),
      userName: userName == null && nullToAbsent
          ? const Value.absent()
          : Value(userName),
      syncStatus: Value(syncStatus),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      createdAt: Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory QualityEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QualityEntry(
      operationId: serializer.fromJson<String>(json['operationId']),
      productCode: serializer.fromJson<String>(json['productCode']),
      productName: serializer.fromJson<String>(json['productName']),
      patternCode: serializer.fromJson<String?>(json['patternCode']),
      machine: serializer.fromJson<String?>(json['machine']),
      quantity: serializer.fromJson<int>(json['quantity']),
      qualityGrade: serializer.fromJson<String>(json['qualityGrade']),
      defectNotes: serializer.fromJson<String?>(json['defectNotes']),
      shift: serializer.fromJson<String>(json['shift']),
      userId: serializer.fromJson<String>(json['userId']),
      userName: serializer.fromJson<String?>(json['userName']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      serverId: serializer.fromJson<String?>(json['serverId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'operationId': serializer.toJson<String>(operationId),
      'productCode': serializer.toJson<String>(productCode),
      'productName': serializer.toJson<String>(productName),
      'patternCode': serializer.toJson<String?>(patternCode),
      'machine': serializer.toJson<String?>(machine),
      'quantity': serializer.toJson<int>(quantity),
      'qualityGrade': serializer.toJson<String>(qualityGrade),
      'defectNotes': serializer.toJson<String?>(defectNotes),
      'shift': serializer.toJson<String>(shift),
      'userId': serializer.toJson<String>(userId),
      'userName': serializer.toJson<String?>(userName),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'serverId': serializer.toJson<String?>(serverId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  QualityEntry copyWith(
          {String? operationId,
          String? productCode,
          String? productName,
          Value<String?> patternCode = const Value.absent(),
          Value<String?> machine = const Value.absent(),
          int? quantity,
          String? qualityGrade,
          Value<String?> defectNotes = const Value.absent(),
          String? shift,
          String? userId,
          Value<String?> userName = const Value.absent(),
          String? syncStatus,
          Value<String?> serverId = const Value.absent(),
          DateTime? createdAt,
          Value<DateTime?> updatedAt = const Value.absent()}) =>
      QualityEntry(
        operationId: operationId ?? this.operationId,
        productCode: productCode ?? this.productCode,
        productName: productName ?? this.productName,
        patternCode: patternCode.present ? patternCode.value : this.patternCode,
        machine: machine.present ? machine.value : this.machine,
        quantity: quantity ?? this.quantity,
        qualityGrade: qualityGrade ?? this.qualityGrade,
        defectNotes: defectNotes.present ? defectNotes.value : this.defectNotes,
        shift: shift ?? this.shift,
        userId: userId ?? this.userId,
        userName: userName.present ? userName.value : this.userName,
        syncStatus: syncStatus ?? this.syncStatus,
        serverId: serverId.present ? serverId.value : this.serverId,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
      );
  QualityEntry copyWithCompanion(QualityEntriesCompanion data) {
    return QualityEntry(
      operationId:
          data.operationId.present ? data.operationId.value : this.operationId,
      productCode:
          data.productCode.present ? data.productCode.value : this.productCode,
      productName:
          data.productName.present ? data.productName.value : this.productName,
      patternCode:
          data.patternCode.present ? data.patternCode.value : this.patternCode,
      machine: data.machine.present ? data.machine.value : this.machine,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      qualityGrade: data.qualityGrade.present
          ? data.qualityGrade.value
          : this.qualityGrade,
      defectNotes:
          data.defectNotes.present ? data.defectNotes.value : this.defectNotes,
      shift: data.shift.present ? data.shift.value : this.shift,
      userId: data.userId.present ? data.userId.value : this.userId,
      userName: data.userName.present ? data.userName.value : this.userName,
      syncStatus:
          data.syncStatus.present ? data.syncStatus.value : this.syncStatus,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QualityEntry(')
          ..write('operationId: $operationId, ')
          ..write('productCode: $productCode, ')
          ..write('productName: $productName, ')
          ..write('patternCode: $patternCode, ')
          ..write('machine: $machine, ')
          ..write('quantity: $quantity, ')
          ..write('qualityGrade: $qualityGrade, ')
          ..write('defectNotes: $defectNotes, ')
          ..write('shift: $shift, ')
          ..write('userId: $userId, ')
          ..write('userName: $userName, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('serverId: $serverId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      operationId,
      productCode,
      productName,
      patternCode,
      machine,
      quantity,
      qualityGrade,
      defectNotes,
      shift,
      userId,
      userName,
      syncStatus,
      serverId,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QualityEntry &&
          other.operationId == this.operationId &&
          other.productCode == this.productCode &&
          other.productName == this.productName &&
          other.patternCode == this.patternCode &&
          other.machine == this.machine &&
          other.quantity == this.quantity &&
          other.qualityGrade == this.qualityGrade &&
          other.defectNotes == this.defectNotes &&
          other.shift == this.shift &&
          other.userId == this.userId &&
          other.userName == this.userName &&
          other.syncStatus == this.syncStatus &&
          other.serverId == this.serverId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class QualityEntriesCompanion extends UpdateCompanion<QualityEntry> {
  final Value<String> operationId;
  final Value<String> productCode;
  final Value<String> productName;
  final Value<String?> patternCode;
  final Value<String?> machine;
  final Value<int> quantity;
  final Value<String> qualityGrade;
  final Value<String?> defectNotes;
  final Value<String> shift;
  final Value<String> userId;
  final Value<String?> userName;
  final Value<String> syncStatus;
  final Value<String?> serverId;
  final Value<DateTime> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<int> rowid;
  const QualityEntriesCompanion({
    this.operationId = const Value.absent(),
    this.productCode = const Value.absent(),
    this.productName = const Value.absent(),
    this.patternCode = const Value.absent(),
    this.machine = const Value.absent(),
    this.quantity = const Value.absent(),
    this.qualityGrade = const Value.absent(),
    this.defectNotes = const Value.absent(),
    this.shift = const Value.absent(),
    this.userId = const Value.absent(),
    this.userName = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.serverId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  QualityEntriesCompanion.insert({
    required String operationId,
    required String productCode,
    required String productName,
    this.patternCode = const Value.absent(),
    this.machine = const Value.absent(),
    required int quantity,
    this.qualityGrade = const Value.absent(),
    this.defectNotes = const Value.absent(),
    required String shift,
    required String userId,
    this.userName = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.serverId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : operationId = Value(operationId),
        productCode = Value(productCode),
        productName = Value(productName),
        quantity = Value(quantity),
        shift = Value(shift),
        userId = Value(userId);
  static Insertable<QualityEntry> custom({
    Expression<String>? operationId,
    Expression<String>? productCode,
    Expression<String>? productName,
    Expression<String>? patternCode,
    Expression<String>? machine,
    Expression<int>? quantity,
    Expression<String>? qualityGrade,
    Expression<String>? defectNotes,
    Expression<String>? shift,
    Expression<String>? userId,
    Expression<String>? userName,
    Expression<String>? syncStatus,
    Expression<String>? serverId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (operationId != null) 'operation_id': operationId,
      if (productCode != null) 'product_code': productCode,
      if (productName != null) 'product_name': productName,
      if (patternCode != null) 'pattern_code': patternCode,
      if (machine != null) 'machine': machine,
      if (quantity != null) 'quantity': quantity,
      if (qualityGrade != null) 'quality_grade': qualityGrade,
      if (defectNotes != null) 'defect_notes': defectNotes,
      if (shift != null) 'shift': shift,
      if (userId != null) 'user_id': userId,
      if (userName != null) 'user_name': userName,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (serverId != null) 'server_id': serverId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  QualityEntriesCompanion copyWith(
      {Value<String>? operationId,
      Value<String>? productCode,
      Value<String>? productName,
      Value<String?>? patternCode,
      Value<String?>? machine,
      Value<int>? quantity,
      Value<String>? qualityGrade,
      Value<String?>? defectNotes,
      Value<String>? shift,
      Value<String>? userId,
      Value<String?>? userName,
      Value<String>? syncStatus,
      Value<String?>? serverId,
      Value<DateTime>? createdAt,
      Value<DateTime?>? updatedAt,
      Value<int>? rowid}) {
    return QualityEntriesCompanion(
      operationId: operationId ?? this.operationId,
      productCode: productCode ?? this.productCode,
      productName: productName ?? this.productName,
      patternCode: patternCode ?? this.patternCode,
      machine: machine ?? this.machine,
      quantity: quantity ?? this.quantity,
      qualityGrade: qualityGrade ?? this.qualityGrade,
      defectNotes: defectNotes ?? this.defectNotes,
      shift: shift ?? this.shift,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      syncStatus: syncStatus ?? this.syncStatus,
      serverId: serverId ?? this.serverId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (operationId.present) {
      map['operation_id'] = Variable<String>(operationId.value);
    }
    if (productCode.present) {
      map['product_code'] = Variable<String>(productCode.value);
    }
    if (productName.present) {
      map['product_name'] = Variable<String>(productName.value);
    }
    if (patternCode.present) {
      map['pattern_code'] = Variable<String>(patternCode.value);
    }
    if (machine.present) {
      map['machine'] = Variable<String>(machine.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (qualityGrade.present) {
      map['quality_grade'] = Variable<String>(qualityGrade.value);
    }
    if (defectNotes.present) {
      map['defect_notes'] = Variable<String>(defectNotes.value);
    }
    if (shift.present) {
      map['shift'] = Variable<String>(shift.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (userName.present) {
      map['user_name'] = Variable<String>(userName.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QualityEntriesCompanion(')
          ..write('operationId: $operationId, ')
          ..write('productCode: $productCode, ')
          ..write('productName: $productName, ')
          ..write('patternCode: $patternCode, ')
          ..write('machine: $machine, ')
          ..write('quantity: $quantity, ')
          ..write('qualityGrade: $qualityGrade, ')
          ..write('defectNotes: $defectNotes, ')
          ..write('shift: $shift, ')
          ..write('userId: $userId, ')
          ..write('userName: $userName, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('serverId: $serverId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PackagingEntriesTable extends PackagingEntries
    with TableInfo<$PackagingEntriesTable, PackagingEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PackagingEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _operationIdMeta =
      const VerificationMeta('operationId');
  @override
  late final GeneratedColumn<String> operationId = GeneratedColumn<String>(
      'operation_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _productCodeMeta =
      const VerificationMeta('productCode');
  @override
  late final GeneratedColumn<String> productCode = GeneratedColumn<String>(
      'product_code', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _productNameMeta =
      const VerificationMeta('productName');
  @override
  late final GeneratedColumn<String> productName = GeneratedColumn<String>(
      'product_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _patternCodeMeta =
      const VerificationMeta('patternCode');
  @override
  late final GeneratedColumn<String> patternCode = GeneratedColumn<String>(
      'pattern_code', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _machineMeta =
      const VerificationMeta('machine');
  @override
  late final GeneratedColumn<String> machine = GeneratedColumn<String>(
      'machine', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _quantityMeta =
      const VerificationMeta('quantity');
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
      'quantity', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _packagingTypeMeta =
      const VerificationMeta('packagingType');
  @override
  late final GeneratedColumn<String> packagingType = GeneratedColumn<String>(
      'packaging_type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _shiftMeta = const VerificationMeta('shift');
  @override
  late final GeneratedColumn<String> shift = GeneratedColumn<String>(
      'shift', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userNameMeta =
      const VerificationMeta('userName');
  @override
  late final GeneratedColumn<String> userName = GeneratedColumn<String>(
      'user_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _syncStatusMeta =
      const VerificationMeta('syncStatus');
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
      'sync_status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('pending'));
  static const VerificationMeta _serverIdMeta =
      const VerificationMeta('serverId');
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
      'server_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        operationId,
        productCode,
        productName,
        patternCode,
        machine,
        quantity,
        packagingType,
        shift,
        userId,
        userName,
        syncStatus,
        serverId,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'packaging_entries';
  @override
  VerificationContext validateIntegrity(Insertable<PackagingEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('operation_id')) {
      context.handle(
          _operationIdMeta,
          operationId.isAcceptableOrUnknown(
              data['operation_id']!, _operationIdMeta));
    } else if (isInserting) {
      context.missing(_operationIdMeta);
    }
    if (data.containsKey('product_code')) {
      context.handle(
          _productCodeMeta,
          productCode.isAcceptableOrUnknown(
              data['product_code']!, _productCodeMeta));
    } else if (isInserting) {
      context.missing(_productCodeMeta);
    }
    if (data.containsKey('product_name')) {
      context.handle(
          _productNameMeta,
          productName.isAcceptableOrUnknown(
              data['product_name']!, _productNameMeta));
    } else if (isInserting) {
      context.missing(_productNameMeta);
    }
    if (data.containsKey('pattern_code')) {
      context.handle(
          _patternCodeMeta,
          patternCode.isAcceptableOrUnknown(
              data['pattern_code']!, _patternCodeMeta));
    }
    if (data.containsKey('machine')) {
      context.handle(_machineMeta,
          machine.isAcceptableOrUnknown(data['machine']!, _machineMeta));
    }
    if (data.containsKey('quantity')) {
      context.handle(_quantityMeta,
          quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta));
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('packaging_type')) {
      context.handle(
          _packagingTypeMeta,
          packagingType.isAcceptableOrUnknown(
              data['packaging_type']!, _packagingTypeMeta));
    }
    if (data.containsKey('shift')) {
      context.handle(
          _shiftMeta, shift.isAcceptableOrUnknown(data['shift']!, _shiftMeta));
    } else if (isInserting) {
      context.missing(_shiftMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('user_name')) {
      context.handle(_userNameMeta,
          userName.isAcceptableOrUnknown(data['user_name']!, _userNameMeta));
    }
    if (data.containsKey('sync_status')) {
      context.handle(
          _syncStatusMeta,
          syncStatus.isAcceptableOrUnknown(
              data['sync_status']!, _syncStatusMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(_serverIdMeta,
          serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {operationId};
  @override
  PackagingEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PackagingEntry(
      operationId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}operation_id'])!,
      productCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}product_code'])!,
      productName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}product_name'])!,
      patternCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}pattern_code']),
      machine: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}machine']),
      quantity: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}quantity'])!,
      packagingType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}packaging_type'])!,
      shift: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}shift'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      userName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_name']),
      syncStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sync_status'])!,
      serverId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}server_id']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at']),
    );
  }

  @override
  $PackagingEntriesTable createAlias(String alias) {
    return $PackagingEntriesTable(attachedDatabase, alias);
  }
}

class PackagingEntry extends DataClass implements Insertable<PackagingEntry> {
  final String operationId;
  final String productCode;
  final String productName;
  final String? patternCode;
  final String? machine;
  final int quantity;
  final String packagingType;
  final String shift;
  final String userId;
  final String? userName;
  final String syncStatus;
  final String? serverId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  const PackagingEntry(
      {required this.operationId,
      required this.productCode,
      required this.productName,
      this.patternCode,
      this.machine,
      required this.quantity,
      required this.packagingType,
      required this.shift,
      required this.userId,
      this.userName,
      required this.syncStatus,
      this.serverId,
      required this.createdAt,
      this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['operation_id'] = Variable<String>(operationId);
    map['product_code'] = Variable<String>(productCode);
    map['product_name'] = Variable<String>(productName);
    if (!nullToAbsent || patternCode != null) {
      map['pattern_code'] = Variable<String>(patternCode);
    }
    if (!nullToAbsent || machine != null) {
      map['machine'] = Variable<String>(machine);
    }
    map['quantity'] = Variable<int>(quantity);
    map['packaging_type'] = Variable<String>(packagingType);
    map['shift'] = Variable<String>(shift);
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || userName != null) {
      map['user_name'] = Variable<String>(userName);
    }
    map['sync_status'] = Variable<String>(syncStatus);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<String>(serverId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  PackagingEntriesCompanion toCompanion(bool nullToAbsent) {
    return PackagingEntriesCompanion(
      operationId: Value(operationId),
      productCode: Value(productCode),
      productName: Value(productName),
      patternCode: patternCode == null && nullToAbsent
          ? const Value.absent()
          : Value(patternCode),
      machine: machine == null && nullToAbsent
          ? const Value.absent()
          : Value(machine),
      quantity: Value(quantity),
      packagingType: Value(packagingType),
      shift: Value(shift),
      userId: Value(userId),
      userName: userName == null && nullToAbsent
          ? const Value.absent()
          : Value(userName),
      syncStatus: Value(syncStatus),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      createdAt: Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory PackagingEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PackagingEntry(
      operationId: serializer.fromJson<String>(json['operationId']),
      productCode: serializer.fromJson<String>(json['productCode']),
      productName: serializer.fromJson<String>(json['productName']),
      patternCode: serializer.fromJson<String?>(json['patternCode']),
      machine: serializer.fromJson<String?>(json['machine']),
      quantity: serializer.fromJson<int>(json['quantity']),
      packagingType: serializer.fromJson<String>(json['packagingType']),
      shift: serializer.fromJson<String>(json['shift']),
      userId: serializer.fromJson<String>(json['userId']),
      userName: serializer.fromJson<String?>(json['userName']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      serverId: serializer.fromJson<String?>(json['serverId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'operationId': serializer.toJson<String>(operationId),
      'productCode': serializer.toJson<String>(productCode),
      'productName': serializer.toJson<String>(productName),
      'patternCode': serializer.toJson<String?>(patternCode),
      'machine': serializer.toJson<String?>(machine),
      'quantity': serializer.toJson<int>(quantity),
      'packagingType': serializer.toJson<String>(packagingType),
      'shift': serializer.toJson<String>(shift),
      'userId': serializer.toJson<String>(userId),
      'userName': serializer.toJson<String?>(userName),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'serverId': serializer.toJson<String?>(serverId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  PackagingEntry copyWith(
          {String? operationId,
          String? productCode,
          String? productName,
          Value<String?> patternCode = const Value.absent(),
          Value<String?> machine = const Value.absent(),
          int? quantity,
          String? packagingType,
          String? shift,
          String? userId,
          Value<String?> userName = const Value.absent(),
          String? syncStatus,
          Value<String?> serverId = const Value.absent(),
          DateTime? createdAt,
          Value<DateTime?> updatedAt = const Value.absent()}) =>
      PackagingEntry(
        operationId: operationId ?? this.operationId,
        productCode: productCode ?? this.productCode,
        productName: productName ?? this.productName,
        patternCode: patternCode.present ? patternCode.value : this.patternCode,
        machine: machine.present ? machine.value : this.machine,
        quantity: quantity ?? this.quantity,
        packagingType: packagingType ?? this.packagingType,
        shift: shift ?? this.shift,
        userId: userId ?? this.userId,
        userName: userName.present ? userName.value : this.userName,
        syncStatus: syncStatus ?? this.syncStatus,
        serverId: serverId.present ? serverId.value : this.serverId,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
      );
  PackagingEntry copyWithCompanion(PackagingEntriesCompanion data) {
    return PackagingEntry(
      operationId:
          data.operationId.present ? data.operationId.value : this.operationId,
      productCode:
          data.productCode.present ? data.productCode.value : this.productCode,
      productName:
          data.productName.present ? data.productName.value : this.productName,
      patternCode:
          data.patternCode.present ? data.patternCode.value : this.patternCode,
      machine: data.machine.present ? data.machine.value : this.machine,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      packagingType: data.packagingType.present
          ? data.packagingType.value
          : this.packagingType,
      shift: data.shift.present ? data.shift.value : this.shift,
      userId: data.userId.present ? data.userId.value : this.userId,
      userName: data.userName.present ? data.userName.value : this.userName,
      syncStatus:
          data.syncStatus.present ? data.syncStatus.value : this.syncStatus,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PackagingEntry(')
          ..write('operationId: $operationId, ')
          ..write('productCode: $productCode, ')
          ..write('productName: $productName, ')
          ..write('patternCode: $patternCode, ')
          ..write('machine: $machine, ')
          ..write('quantity: $quantity, ')
          ..write('packagingType: $packagingType, ')
          ..write('shift: $shift, ')
          ..write('userId: $userId, ')
          ..write('userName: $userName, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('serverId: $serverId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      operationId,
      productCode,
      productName,
      patternCode,
      machine,
      quantity,
      packagingType,
      shift,
      userId,
      userName,
      syncStatus,
      serverId,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PackagingEntry &&
          other.operationId == this.operationId &&
          other.productCode == this.productCode &&
          other.productName == this.productName &&
          other.patternCode == this.patternCode &&
          other.machine == this.machine &&
          other.quantity == this.quantity &&
          other.packagingType == this.packagingType &&
          other.shift == this.shift &&
          other.userId == this.userId &&
          other.userName == this.userName &&
          other.syncStatus == this.syncStatus &&
          other.serverId == this.serverId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PackagingEntriesCompanion extends UpdateCompanion<PackagingEntry> {
  final Value<String> operationId;
  final Value<String> productCode;
  final Value<String> productName;
  final Value<String?> patternCode;
  final Value<String?> machine;
  final Value<int> quantity;
  final Value<String> packagingType;
  final Value<String> shift;
  final Value<String> userId;
  final Value<String?> userName;
  final Value<String> syncStatus;
  final Value<String?> serverId;
  final Value<DateTime> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<int> rowid;
  const PackagingEntriesCompanion({
    this.operationId = const Value.absent(),
    this.productCode = const Value.absent(),
    this.productName = const Value.absent(),
    this.patternCode = const Value.absent(),
    this.machine = const Value.absent(),
    this.quantity = const Value.absent(),
    this.packagingType = const Value.absent(),
    this.shift = const Value.absent(),
    this.userId = const Value.absent(),
    this.userName = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.serverId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PackagingEntriesCompanion.insert({
    required String operationId,
    required String productCode,
    required String productName,
    this.patternCode = const Value.absent(),
    this.machine = const Value.absent(),
    required int quantity,
    this.packagingType = const Value.absent(),
    required String shift,
    required String userId,
    this.userName = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.serverId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : operationId = Value(operationId),
        productCode = Value(productCode),
        productName = Value(productName),
        quantity = Value(quantity),
        shift = Value(shift),
        userId = Value(userId);
  static Insertable<PackagingEntry> custom({
    Expression<String>? operationId,
    Expression<String>? productCode,
    Expression<String>? productName,
    Expression<String>? patternCode,
    Expression<String>? machine,
    Expression<int>? quantity,
    Expression<String>? packagingType,
    Expression<String>? shift,
    Expression<String>? userId,
    Expression<String>? userName,
    Expression<String>? syncStatus,
    Expression<String>? serverId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (operationId != null) 'operation_id': operationId,
      if (productCode != null) 'product_code': productCode,
      if (productName != null) 'product_name': productName,
      if (patternCode != null) 'pattern_code': patternCode,
      if (machine != null) 'machine': machine,
      if (quantity != null) 'quantity': quantity,
      if (packagingType != null) 'packaging_type': packagingType,
      if (shift != null) 'shift': shift,
      if (userId != null) 'user_id': userId,
      if (userName != null) 'user_name': userName,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (serverId != null) 'server_id': serverId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PackagingEntriesCompanion copyWith(
      {Value<String>? operationId,
      Value<String>? productCode,
      Value<String>? productName,
      Value<String?>? patternCode,
      Value<String?>? machine,
      Value<int>? quantity,
      Value<String>? packagingType,
      Value<String>? shift,
      Value<String>? userId,
      Value<String?>? userName,
      Value<String>? syncStatus,
      Value<String?>? serverId,
      Value<DateTime>? createdAt,
      Value<DateTime?>? updatedAt,
      Value<int>? rowid}) {
    return PackagingEntriesCompanion(
      operationId: operationId ?? this.operationId,
      productCode: productCode ?? this.productCode,
      productName: productName ?? this.productName,
      patternCode: patternCode ?? this.patternCode,
      machine: machine ?? this.machine,
      quantity: quantity ?? this.quantity,
      packagingType: packagingType ?? this.packagingType,
      shift: shift ?? this.shift,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      syncStatus: syncStatus ?? this.syncStatus,
      serverId: serverId ?? this.serverId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (operationId.present) {
      map['operation_id'] = Variable<String>(operationId.value);
    }
    if (productCode.present) {
      map['product_code'] = Variable<String>(productCode.value);
    }
    if (productName.present) {
      map['product_name'] = Variable<String>(productName.value);
    }
    if (patternCode.present) {
      map['pattern_code'] = Variable<String>(patternCode.value);
    }
    if (machine.present) {
      map['machine'] = Variable<String>(machine.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (packagingType.present) {
      map['packaging_type'] = Variable<String>(packagingType.value);
    }
    if (shift.present) {
      map['shift'] = Variable<String>(shift.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (userName.present) {
      map['user_name'] = Variable<String>(userName.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PackagingEntriesCompanion(')
          ..write('operationId: $operationId, ')
          ..write('productCode: $productCode, ')
          ..write('productName: $productName, ')
          ..write('patternCode: $patternCode, ')
          ..write('machine: $machine, ')
          ..write('quantity: $quantity, ')
          ..write('packagingType: $packagingType, ')
          ..write('shift: $shift, ')
          ..write('userId: $userId, ')
          ..write('userName: $userName, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('serverId: $serverId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ShipmentEntriesTable extends ShipmentEntries
    with TableInfo<$ShipmentEntriesTable, ShipmentEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShipmentEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _operationIdMeta =
      const VerificationMeta('operationId');
  @override
  late final GeneratedColumn<String> operationId = GeneratedColumn<String>(
      'operation_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _productCodeMeta =
      const VerificationMeta('productCode');
  @override
  late final GeneratedColumn<String> productCode = GeneratedColumn<String>(
      'product_code', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _productNameMeta =
      const VerificationMeta('productName');
  @override
  late final GeneratedColumn<String> productName = GeneratedColumn<String>(
      'product_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _patternCodeMeta =
      const VerificationMeta('patternCode');
  @override
  late final GeneratedColumn<String> patternCode = GeneratedColumn<String>(
      'pattern_code', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _quantityMeta =
      const VerificationMeta('quantity');
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
      'quantity', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _destinationMeta =
      const VerificationMeta('destination');
  @override
  late final GeneratedColumn<String> destination = GeneratedColumn<String>(
      'destination', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _shiftMeta = const VerificationMeta('shift');
  @override
  late final GeneratedColumn<String> shift = GeneratedColumn<String>(
      'shift', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userNameMeta =
      const VerificationMeta('userName');
  @override
  late final GeneratedColumn<String> userName = GeneratedColumn<String>(
      'user_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _syncStatusMeta =
      const VerificationMeta('syncStatus');
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
      'sync_status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('pending'));
  static const VerificationMeta _serverIdMeta =
      const VerificationMeta('serverId');
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
      'server_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        operationId,
        productCode,
        productName,
        patternCode,
        quantity,
        destination,
        shift,
        userId,
        userName,
        syncStatus,
        serverId,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shipment_entries';
  @override
  VerificationContext validateIntegrity(Insertable<ShipmentEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('operation_id')) {
      context.handle(
          _operationIdMeta,
          operationId.isAcceptableOrUnknown(
              data['operation_id']!, _operationIdMeta));
    } else if (isInserting) {
      context.missing(_operationIdMeta);
    }
    if (data.containsKey('product_code')) {
      context.handle(
          _productCodeMeta,
          productCode.isAcceptableOrUnknown(
              data['product_code']!, _productCodeMeta));
    } else if (isInserting) {
      context.missing(_productCodeMeta);
    }
    if (data.containsKey('product_name')) {
      context.handle(
          _productNameMeta,
          productName.isAcceptableOrUnknown(
              data['product_name']!, _productNameMeta));
    } else if (isInserting) {
      context.missing(_productNameMeta);
    }
    if (data.containsKey('pattern_code')) {
      context.handle(
          _patternCodeMeta,
          patternCode.isAcceptableOrUnknown(
              data['pattern_code']!, _patternCodeMeta));
    }
    if (data.containsKey('quantity')) {
      context.handle(_quantityMeta,
          quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta));
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('destination')) {
      context.handle(
          _destinationMeta,
          destination.isAcceptableOrUnknown(
              data['destination']!, _destinationMeta));
    }
    if (data.containsKey('shift')) {
      context.handle(
          _shiftMeta, shift.isAcceptableOrUnknown(data['shift']!, _shiftMeta));
    } else if (isInserting) {
      context.missing(_shiftMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('user_name')) {
      context.handle(_userNameMeta,
          userName.isAcceptableOrUnknown(data['user_name']!, _userNameMeta));
    }
    if (data.containsKey('sync_status')) {
      context.handle(
          _syncStatusMeta,
          syncStatus.isAcceptableOrUnknown(
              data['sync_status']!, _syncStatusMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(_serverIdMeta,
          serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {operationId};
  @override
  ShipmentEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ShipmentEntry(
      operationId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}operation_id'])!,
      productCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}product_code'])!,
      productName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}product_name'])!,
      patternCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}pattern_code']),
      quantity: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}quantity'])!,
      destination: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}destination'])!,
      shift: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}shift'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      userName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_name']),
      syncStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sync_status'])!,
      serverId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}server_id']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at']),
    );
  }

  @override
  $ShipmentEntriesTable createAlias(String alias) {
    return $ShipmentEntriesTable(attachedDatabase, alias);
  }
}

class ShipmentEntry extends DataClass implements Insertable<ShipmentEntry> {
  final String operationId;
  final String productCode;
  final String productName;
  final String? patternCode;
  final int quantity;
  final String destination;
  final String shift;
  final String userId;
  final String? userName;
  final String syncStatus;
  final String? serverId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  const ShipmentEntry(
      {required this.operationId,
      required this.productCode,
      required this.productName,
      this.patternCode,
      required this.quantity,
      required this.destination,
      required this.shift,
      required this.userId,
      this.userName,
      required this.syncStatus,
      this.serverId,
      required this.createdAt,
      this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['operation_id'] = Variable<String>(operationId);
    map['product_code'] = Variable<String>(productCode);
    map['product_name'] = Variable<String>(productName);
    if (!nullToAbsent || patternCode != null) {
      map['pattern_code'] = Variable<String>(patternCode);
    }
    map['quantity'] = Variable<int>(quantity);
    map['destination'] = Variable<String>(destination);
    map['shift'] = Variable<String>(shift);
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || userName != null) {
      map['user_name'] = Variable<String>(userName);
    }
    map['sync_status'] = Variable<String>(syncStatus);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<String>(serverId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  ShipmentEntriesCompanion toCompanion(bool nullToAbsent) {
    return ShipmentEntriesCompanion(
      operationId: Value(operationId),
      productCode: Value(productCode),
      productName: Value(productName),
      patternCode: patternCode == null && nullToAbsent
          ? const Value.absent()
          : Value(patternCode),
      quantity: Value(quantity),
      destination: Value(destination),
      shift: Value(shift),
      userId: Value(userId),
      userName: userName == null && nullToAbsent
          ? const Value.absent()
          : Value(userName),
      syncStatus: Value(syncStatus),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      createdAt: Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory ShipmentEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ShipmentEntry(
      operationId: serializer.fromJson<String>(json['operationId']),
      productCode: serializer.fromJson<String>(json['productCode']),
      productName: serializer.fromJson<String>(json['productName']),
      patternCode: serializer.fromJson<String?>(json['patternCode']),
      quantity: serializer.fromJson<int>(json['quantity']),
      destination: serializer.fromJson<String>(json['destination']),
      shift: serializer.fromJson<String>(json['shift']),
      userId: serializer.fromJson<String>(json['userId']),
      userName: serializer.fromJson<String?>(json['userName']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      serverId: serializer.fromJson<String?>(json['serverId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'operationId': serializer.toJson<String>(operationId),
      'productCode': serializer.toJson<String>(productCode),
      'productName': serializer.toJson<String>(productName),
      'patternCode': serializer.toJson<String?>(patternCode),
      'quantity': serializer.toJson<int>(quantity),
      'destination': serializer.toJson<String>(destination),
      'shift': serializer.toJson<String>(shift),
      'userId': serializer.toJson<String>(userId),
      'userName': serializer.toJson<String?>(userName),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'serverId': serializer.toJson<String?>(serverId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  ShipmentEntry copyWith(
          {String? operationId,
          String? productCode,
          String? productName,
          Value<String?> patternCode = const Value.absent(),
          int? quantity,
          String? destination,
          String? shift,
          String? userId,
          Value<String?> userName = const Value.absent(),
          String? syncStatus,
          Value<String?> serverId = const Value.absent(),
          DateTime? createdAt,
          Value<DateTime?> updatedAt = const Value.absent()}) =>
      ShipmentEntry(
        operationId: operationId ?? this.operationId,
        productCode: productCode ?? this.productCode,
        productName: productName ?? this.productName,
        patternCode: patternCode.present ? patternCode.value : this.patternCode,
        quantity: quantity ?? this.quantity,
        destination: destination ?? this.destination,
        shift: shift ?? this.shift,
        userId: userId ?? this.userId,
        userName: userName.present ? userName.value : this.userName,
        syncStatus: syncStatus ?? this.syncStatus,
        serverId: serverId.present ? serverId.value : this.serverId,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
      );
  ShipmentEntry copyWithCompanion(ShipmentEntriesCompanion data) {
    return ShipmentEntry(
      operationId:
          data.operationId.present ? data.operationId.value : this.operationId,
      productCode:
          data.productCode.present ? data.productCode.value : this.productCode,
      productName:
          data.productName.present ? data.productName.value : this.productName,
      patternCode:
          data.patternCode.present ? data.patternCode.value : this.patternCode,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      destination:
          data.destination.present ? data.destination.value : this.destination,
      shift: data.shift.present ? data.shift.value : this.shift,
      userId: data.userId.present ? data.userId.value : this.userId,
      userName: data.userName.present ? data.userName.value : this.userName,
      syncStatus:
          data.syncStatus.present ? data.syncStatus.value : this.syncStatus,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ShipmentEntry(')
          ..write('operationId: $operationId, ')
          ..write('productCode: $productCode, ')
          ..write('productName: $productName, ')
          ..write('patternCode: $patternCode, ')
          ..write('quantity: $quantity, ')
          ..write('destination: $destination, ')
          ..write('shift: $shift, ')
          ..write('userId: $userId, ')
          ..write('userName: $userName, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('serverId: $serverId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      operationId,
      productCode,
      productName,
      patternCode,
      quantity,
      destination,
      shift,
      userId,
      userName,
      syncStatus,
      serverId,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShipmentEntry &&
          other.operationId == this.operationId &&
          other.productCode == this.productCode &&
          other.productName == this.productName &&
          other.patternCode == this.patternCode &&
          other.quantity == this.quantity &&
          other.destination == this.destination &&
          other.shift == this.shift &&
          other.userId == this.userId &&
          other.userName == this.userName &&
          other.syncStatus == this.syncStatus &&
          other.serverId == this.serverId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ShipmentEntriesCompanion extends UpdateCompanion<ShipmentEntry> {
  final Value<String> operationId;
  final Value<String> productCode;
  final Value<String> productName;
  final Value<String?> patternCode;
  final Value<int> quantity;
  final Value<String> destination;
  final Value<String> shift;
  final Value<String> userId;
  final Value<String?> userName;
  final Value<String> syncStatus;
  final Value<String?> serverId;
  final Value<DateTime> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<int> rowid;
  const ShipmentEntriesCompanion({
    this.operationId = const Value.absent(),
    this.productCode = const Value.absent(),
    this.productName = const Value.absent(),
    this.patternCode = const Value.absent(),
    this.quantity = const Value.absent(),
    this.destination = const Value.absent(),
    this.shift = const Value.absent(),
    this.userId = const Value.absent(),
    this.userName = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.serverId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ShipmentEntriesCompanion.insert({
    required String operationId,
    required String productCode,
    required String productName,
    this.patternCode = const Value.absent(),
    required int quantity,
    this.destination = const Value.absent(),
    required String shift,
    required String userId,
    this.userName = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.serverId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : operationId = Value(operationId),
        productCode = Value(productCode),
        productName = Value(productName),
        quantity = Value(quantity),
        shift = Value(shift),
        userId = Value(userId);
  static Insertable<ShipmentEntry> custom({
    Expression<String>? operationId,
    Expression<String>? productCode,
    Expression<String>? productName,
    Expression<String>? patternCode,
    Expression<int>? quantity,
    Expression<String>? destination,
    Expression<String>? shift,
    Expression<String>? userId,
    Expression<String>? userName,
    Expression<String>? syncStatus,
    Expression<String>? serverId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (operationId != null) 'operation_id': operationId,
      if (productCode != null) 'product_code': productCode,
      if (productName != null) 'product_name': productName,
      if (patternCode != null) 'pattern_code': patternCode,
      if (quantity != null) 'quantity': quantity,
      if (destination != null) 'destination': destination,
      if (shift != null) 'shift': shift,
      if (userId != null) 'user_id': userId,
      if (userName != null) 'user_name': userName,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (serverId != null) 'server_id': serverId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ShipmentEntriesCompanion copyWith(
      {Value<String>? operationId,
      Value<String>? productCode,
      Value<String>? productName,
      Value<String?>? patternCode,
      Value<int>? quantity,
      Value<String>? destination,
      Value<String>? shift,
      Value<String>? userId,
      Value<String?>? userName,
      Value<String>? syncStatus,
      Value<String?>? serverId,
      Value<DateTime>? createdAt,
      Value<DateTime?>? updatedAt,
      Value<int>? rowid}) {
    return ShipmentEntriesCompanion(
      operationId: operationId ?? this.operationId,
      productCode: productCode ?? this.productCode,
      productName: productName ?? this.productName,
      patternCode: patternCode ?? this.patternCode,
      quantity: quantity ?? this.quantity,
      destination: destination ?? this.destination,
      shift: shift ?? this.shift,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      syncStatus: syncStatus ?? this.syncStatus,
      serverId: serverId ?? this.serverId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (operationId.present) {
      map['operation_id'] = Variable<String>(operationId.value);
    }
    if (productCode.present) {
      map['product_code'] = Variable<String>(productCode.value);
    }
    if (productName.present) {
      map['product_name'] = Variable<String>(productName.value);
    }
    if (patternCode.present) {
      map['pattern_code'] = Variable<String>(patternCode.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (destination.present) {
      map['destination'] = Variable<String>(destination.value);
    }
    if (shift.present) {
      map['shift'] = Variable<String>(shift.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (userName.present) {
      map['user_name'] = Variable<String>(userName.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShipmentEntriesCompanion(')
          ..write('operationId: $operationId, ')
          ..write('productCode: $productCode, ')
          ..write('productName: $productName, ')
          ..write('patternCode: $patternCode, ')
          ..write('quantity: $quantity, ')
          ..write('destination: $destination, ')
          ..write('shift: $shift, ')
          ..write('userId: $userId, ')
          ..write('userName: $userName, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('serverId: $serverId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueTable extends SyncQueue
    with TableInfo<$SyncQueueTable, SyncQueueData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _operationIdMeta =
      const VerificationMeta('operationId');
  @override
  late final GeneratedColumn<String> operationId = GeneratedColumn<String>(
      'operation_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _entryTypeMeta =
      const VerificationMeta('entryType');
  @override
  late final GeneratedColumn<String> entryType = GeneratedColumn<String>(
      'entry_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
      'action', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _payloadMeta =
      const VerificationMeta('payload');
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
      'payload', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('pending'));
  static const VerificationMeta _retryCountMeta =
      const VerificationMeta('retryCount');
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
      'retry_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _errorMessageMeta =
      const VerificationMeta('errorMessage');
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
      'error_message', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _lastAttemptMeta =
      const VerificationMeta('lastAttempt');
  @override
  late final GeneratedColumn<DateTime> lastAttempt = GeneratedColumn<DateTime>(
      'last_attempt', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _nextRetryAtMeta =
      const VerificationMeta('nextRetryAt');
  @override
  late final GeneratedColumn<DateTime> nextRetryAt = GeneratedColumn<DateTime>(
      'next_retry_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        operationId,
        entryType,
        action,
        payload,
        status,
        retryCount,
        errorMessage,
        createdAt,
        lastAttempt,
        nextRetryAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue';
  @override
  VerificationContext validateIntegrity(Insertable<SyncQueueData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('operation_id')) {
      context.handle(
          _operationIdMeta,
          operationId.isAcceptableOrUnknown(
              data['operation_id']!, _operationIdMeta));
    } else if (isInserting) {
      context.missing(_operationIdMeta);
    }
    if (data.containsKey('entry_type')) {
      context.handle(_entryTypeMeta,
          entryType.isAcceptableOrUnknown(data['entry_type']!, _entryTypeMeta));
    } else if (isInserting) {
      context.missing(_entryTypeMeta);
    }
    if (data.containsKey('action')) {
      context.handle(_actionMeta,
          action.isAcceptableOrUnknown(data['action']!, _actionMeta));
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(_payloadMeta,
          payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta));
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('retry_count')) {
      context.handle(
          _retryCountMeta,
          retryCount.isAcceptableOrUnknown(
              data['retry_count']!, _retryCountMeta));
    }
    if (data.containsKey('error_message')) {
      context.handle(
          _errorMessageMeta,
          errorMessage.isAcceptableOrUnknown(
              data['error_message']!, _errorMessageMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('last_attempt')) {
      context.handle(
          _lastAttemptMeta,
          lastAttempt.isAcceptableOrUnknown(
              data['last_attempt']!, _lastAttemptMeta));
    }
    if (data.containsKey('next_retry_at')) {
      context.handle(
          _nextRetryAtMeta,
          nextRetryAt.isAcceptableOrUnknown(
              data['next_retry_at']!, _nextRetryAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncQueueData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      operationId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}operation_id'])!,
      entryType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entry_type'])!,
      action: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}action'])!,
      payload: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      retryCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}retry_count'])!,
      errorMessage: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}error_message']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      lastAttempt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_attempt']),
      nextRetryAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}next_retry_at']),
    );
  }

  @override
  $SyncQueueTable createAlias(String alias) {
    return $SyncQueueTable(attachedDatabase, alias);
  }
}

class SyncQueueData extends DataClass implements Insertable<SyncQueueData> {
  final int id;
  final String operationId;
  final String entryType;
  final String action;
  final String payload;
  final String status;
  final int retryCount;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime? lastAttempt;
  final DateTime? nextRetryAt;
  const SyncQueueData(
      {required this.id,
      required this.operationId,
      required this.entryType,
      required this.action,
      required this.payload,
      required this.status,
      required this.retryCount,
      this.errorMessage,
      required this.createdAt,
      this.lastAttempt,
      this.nextRetryAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['operation_id'] = Variable<String>(operationId);
    map['entry_type'] = Variable<String>(entryType);
    map['action'] = Variable<String>(action);
    map['payload'] = Variable<String>(payload);
    map['status'] = Variable<String>(status);
    map['retry_count'] = Variable<int>(retryCount);
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || lastAttempt != null) {
      map['last_attempt'] = Variable<DateTime>(lastAttempt);
    }
    if (!nullToAbsent || nextRetryAt != null) {
      map['next_retry_at'] = Variable<DateTime>(nextRetryAt);
    }
    return map;
  }

  SyncQueueCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueCompanion(
      id: Value(id),
      operationId: Value(operationId),
      entryType: Value(entryType),
      action: Value(action),
      payload: Value(payload),
      status: Value(status),
      retryCount: Value(retryCount),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
      createdAt: Value(createdAt),
      lastAttempt: lastAttempt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAttempt),
      nextRetryAt: nextRetryAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextRetryAt),
    );
  }

  factory SyncQueueData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueData(
      id: serializer.fromJson<int>(json['id']),
      operationId: serializer.fromJson<String>(json['operationId']),
      entryType: serializer.fromJson<String>(json['entryType']),
      action: serializer.fromJson<String>(json['action']),
      payload: serializer.fromJson<String>(json['payload']),
      status: serializer.fromJson<String>(json['status']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastAttempt: serializer.fromJson<DateTime?>(json['lastAttempt']),
      nextRetryAt: serializer.fromJson<DateTime?>(json['nextRetryAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'operationId': serializer.toJson<String>(operationId),
      'entryType': serializer.toJson<String>(entryType),
      'action': serializer.toJson<String>(action),
      'payload': serializer.toJson<String>(payload),
      'status': serializer.toJson<String>(status),
      'retryCount': serializer.toJson<int>(retryCount),
      'errorMessage': serializer.toJson<String?>(errorMessage),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastAttempt': serializer.toJson<DateTime?>(lastAttempt),
      'nextRetryAt': serializer.toJson<DateTime?>(nextRetryAt),
    };
  }

  SyncQueueData copyWith(
          {int? id,
          String? operationId,
          String? entryType,
          String? action,
          String? payload,
          String? status,
          int? retryCount,
          Value<String?> errorMessage = const Value.absent(),
          DateTime? createdAt,
          Value<DateTime?> lastAttempt = const Value.absent(),
          Value<DateTime?> nextRetryAt = const Value.absent()}) =>
      SyncQueueData(
        id: id ?? this.id,
        operationId: operationId ?? this.operationId,
        entryType: entryType ?? this.entryType,
        action: action ?? this.action,
        payload: payload ?? this.payload,
        status: status ?? this.status,
        retryCount: retryCount ?? this.retryCount,
        errorMessage:
            errorMessage.present ? errorMessage.value : this.errorMessage,
        createdAt: createdAt ?? this.createdAt,
        lastAttempt: lastAttempt.present ? lastAttempt.value : this.lastAttempt,
        nextRetryAt: nextRetryAt.present ? nextRetryAt.value : this.nextRetryAt,
      );
  SyncQueueData copyWithCompanion(SyncQueueCompanion data) {
    return SyncQueueData(
      id: data.id.present ? data.id.value : this.id,
      operationId:
          data.operationId.present ? data.operationId.value : this.operationId,
      entryType: data.entryType.present ? data.entryType.value : this.entryType,
      action: data.action.present ? data.action.value : this.action,
      payload: data.payload.present ? data.payload.value : this.payload,
      status: data.status.present ? data.status.value : this.status,
      retryCount:
          data.retryCount.present ? data.retryCount.value : this.retryCount,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastAttempt:
          data.lastAttempt.present ? data.lastAttempt.value : this.lastAttempt,
      nextRetryAt:
          data.nextRetryAt.present ? data.nextRetryAt.value : this.nextRetryAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueData(')
          ..write('id: $id, ')
          ..write('operationId: $operationId, ')
          ..write('entryType: $entryType, ')
          ..write('action: $action, ')
          ..write('payload: $payload, ')
          ..write('status: $status, ')
          ..write('retryCount: $retryCount, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastAttempt: $lastAttempt, ')
          ..write('nextRetryAt: $nextRetryAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, operationId, entryType, action, payload,
      status, retryCount, errorMessage, createdAt, lastAttempt, nextRetryAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueData &&
          other.id == this.id &&
          other.operationId == this.operationId &&
          other.entryType == this.entryType &&
          other.action == this.action &&
          other.payload == this.payload &&
          other.status == this.status &&
          other.retryCount == this.retryCount &&
          other.errorMessage == this.errorMessage &&
          other.createdAt == this.createdAt &&
          other.lastAttempt == this.lastAttempt &&
          other.nextRetryAt == this.nextRetryAt);
}

class SyncQueueCompanion extends UpdateCompanion<SyncQueueData> {
  final Value<int> id;
  final Value<String> operationId;
  final Value<String> entryType;
  final Value<String> action;
  final Value<String> payload;
  final Value<String> status;
  final Value<int> retryCount;
  final Value<String?> errorMessage;
  final Value<DateTime> createdAt;
  final Value<DateTime?> lastAttempt;
  final Value<DateTime?> nextRetryAt;
  const SyncQueueCompanion({
    this.id = const Value.absent(),
    this.operationId = const Value.absent(),
    this.entryType = const Value.absent(),
    this.action = const Value.absent(),
    this.payload = const Value.absent(),
    this.status = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastAttempt = const Value.absent(),
    this.nextRetryAt = const Value.absent(),
  });
  SyncQueueCompanion.insert({
    this.id = const Value.absent(),
    required String operationId,
    required String entryType,
    required String action,
    required String payload,
    this.status = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastAttempt = const Value.absent(),
    this.nextRetryAt = const Value.absent(),
  })  : operationId = Value(operationId),
        entryType = Value(entryType),
        action = Value(action),
        payload = Value(payload);
  static Insertable<SyncQueueData> custom({
    Expression<int>? id,
    Expression<String>? operationId,
    Expression<String>? entryType,
    Expression<String>? action,
    Expression<String>? payload,
    Expression<String>? status,
    Expression<int>? retryCount,
    Expression<String>? errorMessage,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastAttempt,
    Expression<DateTime>? nextRetryAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (operationId != null) 'operation_id': operationId,
      if (entryType != null) 'entry_type': entryType,
      if (action != null) 'action': action,
      if (payload != null) 'payload': payload,
      if (status != null) 'status': status,
      if (retryCount != null) 'retry_count': retryCount,
      if (errorMessage != null) 'error_message': errorMessage,
      if (createdAt != null) 'created_at': createdAt,
      if (lastAttempt != null) 'last_attempt': lastAttempt,
      if (nextRetryAt != null) 'next_retry_at': nextRetryAt,
    });
  }

  SyncQueueCompanion copyWith(
      {Value<int>? id,
      Value<String>? operationId,
      Value<String>? entryType,
      Value<String>? action,
      Value<String>? payload,
      Value<String>? status,
      Value<int>? retryCount,
      Value<String?>? errorMessage,
      Value<DateTime>? createdAt,
      Value<DateTime?>? lastAttempt,
      Value<DateTime?>? nextRetryAt}) {
    return SyncQueueCompanion(
      id: id ?? this.id,
      operationId: operationId ?? this.operationId,
      entryType: entryType ?? this.entryType,
      action: action ?? this.action,
      payload: payload ?? this.payload,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
      lastAttempt: lastAttempt ?? this.lastAttempt,
      nextRetryAt: nextRetryAt ?? this.nextRetryAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (operationId.present) {
      map['operation_id'] = Variable<String>(operationId.value);
    }
    if (entryType.present) {
      map['entry_type'] = Variable<String>(entryType.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastAttempt.present) {
      map['last_attempt'] = Variable<DateTime>(lastAttempt.value);
    }
    if (nextRetryAt.present) {
      map['next_retry_at'] = Variable<DateTime>(nextRetryAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueCompanion(')
          ..write('id: $id, ')
          ..write('operationId: $operationId, ')
          ..write('entryType: $entryType, ')
          ..write('action: $action, ')
          ..write('payload: $payload, ')
          ..write('status: $status, ')
          ..write('retryCount: $retryCount, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastAttempt: $lastAttempt, ')
          ..write('nextRetryAt: $nextRetryAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $UsersTable users = $UsersTable(this);
  late final $ProductsTable products = $ProductsTable(this);
  late final $PatternsTable patterns = $PatternsTable(this);
  late final $MachinesTable machines = $MachinesTable(this);
  late final $ProductionEntriesTable productionEntries =
      $ProductionEntriesTable(this);
  late final $QualityEntriesTable qualityEntries = $QualityEntriesTable(this);
  late final $PackagingEntriesTable packagingEntries =
      $PackagingEntriesTable(this);
  late final $ShipmentEntriesTable shipmentEntries =
      $ShipmentEntriesTable(this);
  late final $SyncQueueTable syncQueue = $SyncQueueTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        users,
        products,
        patterns,
        machines,
        productionEntries,
        qualityEntries,
        packagingEntries,
        shipmentEntries,
        syncQueue
      ];
}

typedef $$UsersTableCreateCompanionBuilder = UsersCompanion Function({
  required String id,
  required String name,
  required String username,
  required String role,
  Value<String> assignedShift,
  Value<String?> assignedStage,
  Value<DateTime> cachedAt,
  Value<int> rowid,
});
typedef $$UsersTableUpdateCompanionBuilder = UsersCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> username,
  Value<String> role,
  Value<String> assignedShift,
  Value<String?> assignedStage,
  Value<DateTime> cachedAt,
  Value<int> rowid,
});

class $$UsersTableFilterComposer extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get username => $composableBuilder(
      column: $table.username, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get assignedShift => $composableBuilder(
      column: $table.assignedShift, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get assignedStage => $composableBuilder(
      column: $table.assignedStage, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnFilters(column));
}

class $$UsersTableOrderingComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get username => $composableBuilder(
      column: $table.username, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get assignedShift => $composableBuilder(
      column: $table.assignedShift,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get assignedStage => $composableBuilder(
      column: $table.assignedStage,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnOrderings(column));
}

class $$UsersTableAnnotationComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get assignedShift => $composableBuilder(
      column: $table.assignedShift, builder: (column) => column);

  GeneratedColumn<String> get assignedStage => $composableBuilder(
      column: $table.assignedStage, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$UsersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $UsersTable,
    User,
    $$UsersTableFilterComposer,
    $$UsersTableOrderingComposer,
    $$UsersTableAnnotationComposer,
    $$UsersTableCreateCompanionBuilder,
    $$UsersTableUpdateCompanionBuilder,
    (User, BaseReferences<_$AppDatabase, $UsersTable, User>),
    User,
    PrefetchHooks Function()> {
  $$UsersTableTableManager(_$AppDatabase db, $UsersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UsersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UsersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UsersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> username = const Value.absent(),
            Value<String> role = const Value.absent(),
            Value<String> assignedShift = const Value.absent(),
            Value<String?> assignedStage = const Value.absent(),
            Value<DateTime> cachedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UsersCompanion(
            id: id,
            name: name,
            username: username,
            role: role,
            assignedShift: assignedShift,
            assignedStage: assignedStage,
            cachedAt: cachedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required String username,
            required String role,
            Value<String> assignedShift = const Value.absent(),
            Value<String?> assignedStage = const Value.absent(),
            Value<DateTime> cachedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UsersCompanion.insert(
            id: id,
            name: name,
            username: username,
            role: role,
            assignedShift: assignedShift,
            assignedStage: assignedStage,
            cachedAt: cachedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$UsersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $UsersTable,
    User,
    $$UsersTableFilterComposer,
    $$UsersTableOrderingComposer,
    $$UsersTableAnnotationComposer,
    $$UsersTableCreateCompanionBuilder,
    $$UsersTableUpdateCompanionBuilder,
    (User, BaseReferences<_$AppDatabase, $UsersTable, User>),
    User,
    PrefetchHooks Function()>;
typedef $$ProductsTableCreateCompanionBuilder = ProductsCompanion Function({
  required String id,
  required String productCode,
  required String productName,
  Value<bool> isActive,
  Value<DateTime> cachedAt,
  Value<int> rowid,
});
typedef $$ProductsTableUpdateCompanionBuilder = ProductsCompanion Function({
  Value<String> id,
  Value<String> productCode,
  Value<String> productName,
  Value<bool> isActive,
  Value<DateTime> cachedAt,
  Value<int> rowid,
});

class $$ProductsTableFilterComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get productCode => $composableBuilder(
      column: $table.productCode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get productName => $composableBuilder(
      column: $table.productName, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnFilters(column));
}

class $$ProductsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get productCode => $composableBuilder(
      column: $table.productCode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get productName => $composableBuilder(
      column: $table.productName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnOrderings(column));
}

class $$ProductsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get productCode => $composableBuilder(
      column: $table.productCode, builder: (column) => column);

  GeneratedColumn<String> get productName => $composableBuilder(
      column: $table.productName, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$ProductsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ProductsTable,
    Product,
    $$ProductsTableFilterComposer,
    $$ProductsTableOrderingComposer,
    $$ProductsTableAnnotationComposer,
    $$ProductsTableCreateCompanionBuilder,
    $$ProductsTableUpdateCompanionBuilder,
    (Product, BaseReferences<_$AppDatabase, $ProductsTable, Product>),
    Product,
    PrefetchHooks Function()> {
  $$ProductsTableTableManager(_$AppDatabase db, $ProductsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> productCode = const Value.absent(),
            Value<String> productName = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<DateTime> cachedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ProductsCompanion(
            id: id,
            productCode: productCode,
            productName: productName,
            isActive: isActive,
            cachedAt: cachedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String productCode,
            required String productName,
            Value<bool> isActive = const Value.absent(),
            Value<DateTime> cachedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ProductsCompanion.insert(
            id: id,
            productCode: productCode,
            productName: productName,
            isActive: isActive,
            cachedAt: cachedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ProductsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ProductsTable,
    Product,
    $$ProductsTableFilterComposer,
    $$ProductsTableOrderingComposer,
    $$ProductsTableAnnotationComposer,
    $$ProductsTableCreateCompanionBuilder,
    $$ProductsTableUpdateCompanionBuilder,
    (Product, BaseReferences<_$AppDatabase, $ProductsTable, Product>),
    Product,
    PrefetchHooks Function()>;
typedef $$PatternsTableCreateCompanionBuilder = PatternsCompanion Function({
  required String id,
  required String patternCode,
  required String patternName,
  Value<String?> thumbnailUrl,
  Value<bool> isActive,
  Value<DateTime> cachedAt,
  Value<int> rowid,
});
typedef $$PatternsTableUpdateCompanionBuilder = PatternsCompanion Function({
  Value<String> id,
  Value<String> patternCode,
  Value<String> patternName,
  Value<String?> thumbnailUrl,
  Value<bool> isActive,
  Value<DateTime> cachedAt,
  Value<int> rowid,
});

class $$PatternsTableFilterComposer
    extends Composer<_$AppDatabase, $PatternsTable> {
  $$PatternsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get patternCode => $composableBuilder(
      column: $table.patternCode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get patternName => $composableBuilder(
      column: $table.patternName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get thumbnailUrl => $composableBuilder(
      column: $table.thumbnailUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnFilters(column));
}

class $$PatternsTableOrderingComposer
    extends Composer<_$AppDatabase, $PatternsTable> {
  $$PatternsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get patternCode => $composableBuilder(
      column: $table.patternCode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get patternName => $composableBuilder(
      column: $table.patternName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get thumbnailUrl => $composableBuilder(
      column: $table.thumbnailUrl,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnOrderings(column));
}

class $$PatternsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PatternsTable> {
  $$PatternsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get patternCode => $composableBuilder(
      column: $table.patternCode, builder: (column) => column);

  GeneratedColumn<String> get patternName => $composableBuilder(
      column: $table.patternName, builder: (column) => column);

  GeneratedColumn<String> get thumbnailUrl => $composableBuilder(
      column: $table.thumbnailUrl, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$PatternsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PatternsTable,
    Pattern,
    $$PatternsTableFilterComposer,
    $$PatternsTableOrderingComposer,
    $$PatternsTableAnnotationComposer,
    $$PatternsTableCreateCompanionBuilder,
    $$PatternsTableUpdateCompanionBuilder,
    (Pattern, BaseReferences<_$AppDatabase, $PatternsTable, Pattern>),
    Pattern,
    PrefetchHooks Function()> {
  $$PatternsTableTableManager(_$AppDatabase db, $PatternsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PatternsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PatternsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PatternsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> patternCode = const Value.absent(),
            Value<String> patternName = const Value.absent(),
            Value<String?> thumbnailUrl = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<DateTime> cachedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PatternsCompanion(
            id: id,
            patternCode: patternCode,
            patternName: patternName,
            thumbnailUrl: thumbnailUrl,
            isActive: isActive,
            cachedAt: cachedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String patternCode,
            required String patternName,
            Value<String?> thumbnailUrl = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<DateTime> cachedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PatternsCompanion.insert(
            id: id,
            patternCode: patternCode,
            patternName: patternName,
            thumbnailUrl: thumbnailUrl,
            isActive: isActive,
            cachedAt: cachedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PatternsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PatternsTable,
    Pattern,
    $$PatternsTableFilterComposer,
    $$PatternsTableOrderingComposer,
    $$PatternsTableAnnotationComposer,
    $$PatternsTableCreateCompanionBuilder,
    $$PatternsTableUpdateCompanionBuilder,
    (Pattern, BaseReferences<_$AppDatabase, $PatternsTable, Pattern>),
    Pattern,
    PrefetchHooks Function()>;
typedef $$MachinesTableCreateCompanionBuilder = MachinesCompanion Function({
  required String id,
  required String name,
  required String stage,
  Value<bool> isActive,
  Value<DateTime> cachedAt,
  Value<int> rowid,
});
typedef $$MachinesTableUpdateCompanionBuilder = MachinesCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> stage,
  Value<bool> isActive,
  Value<DateTime> cachedAt,
  Value<int> rowid,
});

class $$MachinesTableFilterComposer
    extends Composer<_$AppDatabase, $MachinesTable> {
  $$MachinesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get stage => $composableBuilder(
      column: $table.stage, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnFilters(column));
}

class $$MachinesTableOrderingComposer
    extends Composer<_$AppDatabase, $MachinesTable> {
  $$MachinesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get stage => $composableBuilder(
      column: $table.stage, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnOrderings(column));
}

class $$MachinesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MachinesTable> {
  $$MachinesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get stage =>
      $composableBuilder(column: $table.stage, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$MachinesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MachinesTable,
    Machine,
    $$MachinesTableFilterComposer,
    $$MachinesTableOrderingComposer,
    $$MachinesTableAnnotationComposer,
    $$MachinesTableCreateCompanionBuilder,
    $$MachinesTableUpdateCompanionBuilder,
    (Machine, BaseReferences<_$AppDatabase, $MachinesTable, Machine>),
    Machine,
    PrefetchHooks Function()> {
  $$MachinesTableTableManager(_$AppDatabase db, $MachinesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MachinesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MachinesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MachinesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> stage = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<DateTime> cachedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MachinesCompanion(
            id: id,
            name: name,
            stage: stage,
            isActive: isActive,
            cachedAt: cachedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required String stage,
            Value<bool> isActive = const Value.absent(),
            Value<DateTime> cachedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MachinesCompanion.insert(
            id: id,
            name: name,
            stage: stage,
            isActive: isActive,
            cachedAt: cachedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MachinesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MachinesTable,
    Machine,
    $$MachinesTableFilterComposer,
    $$MachinesTableOrderingComposer,
    $$MachinesTableAnnotationComposer,
    $$MachinesTableCreateCompanionBuilder,
    $$MachinesTableUpdateCompanionBuilder,
    (Machine, BaseReferences<_$AppDatabase, $MachinesTable, Machine>),
    Machine,
    PrefetchHooks Function()>;
typedef $$ProductionEntriesTableCreateCompanionBuilder
    = ProductionEntriesCompanion Function({
  required String operationId,
  required String productCode,
  required String productName,
  Value<String?> patternCode,
  Value<String?> machine,
  required int quantity,
  required String stage,
  required String shift,
  required String userId,
  Value<String?> userName,
  Value<int?> quality,
  Value<String?> notes,
  Value<String> syncStatus,
  Value<String?> serverId,
  Value<DateTime> createdAt,
  Value<DateTime?> updatedAt,
  Value<int> rowid,
});
typedef $$ProductionEntriesTableUpdateCompanionBuilder
    = ProductionEntriesCompanion Function({
  Value<String> operationId,
  Value<String> productCode,
  Value<String> productName,
  Value<String?> patternCode,
  Value<String?> machine,
  Value<int> quantity,
  Value<String> stage,
  Value<String> shift,
  Value<String> userId,
  Value<String?> userName,
  Value<int?> quality,
  Value<String?> notes,
  Value<String> syncStatus,
  Value<String?> serverId,
  Value<DateTime> createdAt,
  Value<DateTime?> updatedAt,
  Value<int> rowid,
});

class $$ProductionEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $ProductionEntriesTable> {
  $$ProductionEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get operationId => $composableBuilder(
      column: $table.operationId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get productCode => $composableBuilder(
      column: $table.productCode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get productName => $composableBuilder(
      column: $table.productName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get patternCode => $composableBuilder(
      column: $table.patternCode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get machine => $composableBuilder(
      column: $table.machine, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get stage => $composableBuilder(
      column: $table.stage, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get shift => $composableBuilder(
      column: $table.shift, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userName => $composableBuilder(
      column: $table.userName, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get quality => $composableBuilder(
      column: $table.quality, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get serverId => $composableBuilder(
      column: $table.serverId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$ProductionEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductionEntriesTable> {
  $$ProductionEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get operationId => $composableBuilder(
      column: $table.operationId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get productCode => $composableBuilder(
      column: $table.productCode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get productName => $composableBuilder(
      column: $table.productName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get patternCode => $composableBuilder(
      column: $table.patternCode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get machine => $composableBuilder(
      column: $table.machine, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get stage => $composableBuilder(
      column: $table.stage, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get shift => $composableBuilder(
      column: $table.shift, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userName => $composableBuilder(
      column: $table.userName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get quality => $composableBuilder(
      column: $table.quality, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get serverId => $composableBuilder(
      column: $table.serverId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$ProductionEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductionEntriesTable> {
  $$ProductionEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get operationId => $composableBuilder(
      column: $table.operationId, builder: (column) => column);

  GeneratedColumn<String> get productCode => $composableBuilder(
      column: $table.productCode, builder: (column) => column);

  GeneratedColumn<String> get productName => $composableBuilder(
      column: $table.productName, builder: (column) => column);

  GeneratedColumn<String> get patternCode => $composableBuilder(
      column: $table.patternCode, builder: (column) => column);

  GeneratedColumn<String> get machine =>
      $composableBuilder(column: $table.machine, builder: (column) => column);

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<String> get stage =>
      $composableBuilder(column: $table.stage, builder: (column) => column);

  GeneratedColumn<String> get shift =>
      $composableBuilder(column: $table.shift, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get userName =>
      $composableBuilder(column: $table.userName, builder: (column) => column);

  GeneratedColumn<int> get quality =>
      $composableBuilder(column: $table.quality, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => column);

  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ProductionEntriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ProductionEntriesTable,
    ProductionEntry,
    $$ProductionEntriesTableFilterComposer,
    $$ProductionEntriesTableOrderingComposer,
    $$ProductionEntriesTableAnnotationComposer,
    $$ProductionEntriesTableCreateCompanionBuilder,
    $$ProductionEntriesTableUpdateCompanionBuilder,
    (
      ProductionEntry,
      BaseReferences<_$AppDatabase, $ProductionEntriesTable, ProductionEntry>
    ),
    ProductionEntry,
    PrefetchHooks Function()> {
  $$ProductionEntriesTableTableManager(
      _$AppDatabase db, $ProductionEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductionEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductionEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductionEntriesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> operationId = const Value.absent(),
            Value<String> productCode = const Value.absent(),
            Value<String> productName = const Value.absent(),
            Value<String?> patternCode = const Value.absent(),
            Value<String?> machine = const Value.absent(),
            Value<int> quantity = const Value.absent(),
            Value<String> stage = const Value.absent(),
            Value<String> shift = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String?> userName = const Value.absent(),
            Value<int?> quality = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<String> syncStatus = const Value.absent(),
            Value<String?> serverId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ProductionEntriesCompanion(
            operationId: operationId,
            productCode: productCode,
            productName: productName,
            patternCode: patternCode,
            machine: machine,
            quantity: quantity,
            stage: stage,
            shift: shift,
            userId: userId,
            userName: userName,
            quality: quality,
            notes: notes,
            syncStatus: syncStatus,
            serverId: serverId,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String operationId,
            required String productCode,
            required String productName,
            Value<String?> patternCode = const Value.absent(),
            Value<String?> machine = const Value.absent(),
            required int quantity,
            required String stage,
            required String shift,
            required String userId,
            Value<String?> userName = const Value.absent(),
            Value<int?> quality = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<String> syncStatus = const Value.absent(),
            Value<String?> serverId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ProductionEntriesCompanion.insert(
            operationId: operationId,
            productCode: productCode,
            productName: productName,
            patternCode: patternCode,
            machine: machine,
            quantity: quantity,
            stage: stage,
            shift: shift,
            userId: userId,
            userName: userName,
            quality: quality,
            notes: notes,
            syncStatus: syncStatus,
            serverId: serverId,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ProductionEntriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ProductionEntriesTable,
    ProductionEntry,
    $$ProductionEntriesTableFilterComposer,
    $$ProductionEntriesTableOrderingComposer,
    $$ProductionEntriesTableAnnotationComposer,
    $$ProductionEntriesTableCreateCompanionBuilder,
    $$ProductionEntriesTableUpdateCompanionBuilder,
    (
      ProductionEntry,
      BaseReferences<_$AppDatabase, $ProductionEntriesTable, ProductionEntry>
    ),
    ProductionEntry,
    PrefetchHooks Function()>;
typedef $$QualityEntriesTableCreateCompanionBuilder = QualityEntriesCompanion
    Function({
  required String operationId,
  required String productCode,
  required String productName,
  Value<String?> patternCode,
  Value<String?> machine,
  required int quantity,
  Value<String> qualityGrade,
  Value<String?> defectNotes,
  required String shift,
  required String userId,
  Value<String?> userName,
  Value<String> syncStatus,
  Value<String?> serverId,
  Value<DateTime> createdAt,
  Value<DateTime?> updatedAt,
  Value<int> rowid,
});
typedef $$QualityEntriesTableUpdateCompanionBuilder = QualityEntriesCompanion
    Function({
  Value<String> operationId,
  Value<String> productCode,
  Value<String> productName,
  Value<String?> patternCode,
  Value<String?> machine,
  Value<int> quantity,
  Value<String> qualityGrade,
  Value<String?> defectNotes,
  Value<String> shift,
  Value<String> userId,
  Value<String?> userName,
  Value<String> syncStatus,
  Value<String?> serverId,
  Value<DateTime> createdAt,
  Value<DateTime?> updatedAt,
  Value<int> rowid,
});

class $$QualityEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $QualityEntriesTable> {
  $$QualityEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get operationId => $composableBuilder(
      column: $table.operationId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get productCode => $composableBuilder(
      column: $table.productCode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get productName => $composableBuilder(
      column: $table.productName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get patternCode => $composableBuilder(
      column: $table.patternCode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get machine => $composableBuilder(
      column: $table.machine, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get qualityGrade => $composableBuilder(
      column: $table.qualityGrade, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get defectNotes => $composableBuilder(
      column: $table.defectNotes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get shift => $composableBuilder(
      column: $table.shift, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userName => $composableBuilder(
      column: $table.userName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get serverId => $composableBuilder(
      column: $table.serverId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$QualityEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $QualityEntriesTable> {
  $$QualityEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get operationId => $composableBuilder(
      column: $table.operationId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get productCode => $composableBuilder(
      column: $table.productCode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get productName => $composableBuilder(
      column: $table.productName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get patternCode => $composableBuilder(
      column: $table.patternCode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get machine => $composableBuilder(
      column: $table.machine, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get qualityGrade => $composableBuilder(
      column: $table.qualityGrade,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get defectNotes => $composableBuilder(
      column: $table.defectNotes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get shift => $composableBuilder(
      column: $table.shift, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userName => $composableBuilder(
      column: $table.userName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get serverId => $composableBuilder(
      column: $table.serverId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$QualityEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $QualityEntriesTable> {
  $$QualityEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get operationId => $composableBuilder(
      column: $table.operationId, builder: (column) => column);

  GeneratedColumn<String> get productCode => $composableBuilder(
      column: $table.productCode, builder: (column) => column);

  GeneratedColumn<String> get productName => $composableBuilder(
      column: $table.productName, builder: (column) => column);

  GeneratedColumn<String> get patternCode => $composableBuilder(
      column: $table.patternCode, builder: (column) => column);

  GeneratedColumn<String> get machine =>
      $composableBuilder(column: $table.machine, builder: (column) => column);

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<String> get qualityGrade => $composableBuilder(
      column: $table.qualityGrade, builder: (column) => column);

  GeneratedColumn<String> get defectNotes => $composableBuilder(
      column: $table.defectNotes, builder: (column) => column);

  GeneratedColumn<String> get shift =>
      $composableBuilder(column: $table.shift, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get userName =>
      $composableBuilder(column: $table.userName, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => column);

  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$QualityEntriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $QualityEntriesTable,
    QualityEntry,
    $$QualityEntriesTableFilterComposer,
    $$QualityEntriesTableOrderingComposer,
    $$QualityEntriesTableAnnotationComposer,
    $$QualityEntriesTableCreateCompanionBuilder,
    $$QualityEntriesTableUpdateCompanionBuilder,
    (
      QualityEntry,
      BaseReferences<_$AppDatabase, $QualityEntriesTable, QualityEntry>
    ),
    QualityEntry,
    PrefetchHooks Function()> {
  $$QualityEntriesTableTableManager(
      _$AppDatabase db, $QualityEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QualityEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QualityEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QualityEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> operationId = const Value.absent(),
            Value<String> productCode = const Value.absent(),
            Value<String> productName = const Value.absent(),
            Value<String?> patternCode = const Value.absent(),
            Value<String?> machine = const Value.absent(),
            Value<int> quantity = const Value.absent(),
            Value<String> qualityGrade = const Value.absent(),
            Value<String?> defectNotes = const Value.absent(),
            Value<String> shift = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String?> userName = const Value.absent(),
            Value<String> syncStatus = const Value.absent(),
            Value<String?> serverId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              QualityEntriesCompanion(
            operationId: operationId,
            productCode: productCode,
            productName: productName,
            patternCode: patternCode,
            machine: machine,
            quantity: quantity,
            qualityGrade: qualityGrade,
            defectNotes: defectNotes,
            shift: shift,
            userId: userId,
            userName: userName,
            syncStatus: syncStatus,
            serverId: serverId,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String operationId,
            required String productCode,
            required String productName,
            Value<String?> patternCode = const Value.absent(),
            Value<String?> machine = const Value.absent(),
            required int quantity,
            Value<String> qualityGrade = const Value.absent(),
            Value<String?> defectNotes = const Value.absent(),
            required String shift,
            required String userId,
            Value<String?> userName = const Value.absent(),
            Value<String> syncStatus = const Value.absent(),
            Value<String?> serverId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              QualityEntriesCompanion.insert(
            operationId: operationId,
            productCode: productCode,
            productName: productName,
            patternCode: patternCode,
            machine: machine,
            quantity: quantity,
            qualityGrade: qualityGrade,
            defectNotes: defectNotes,
            shift: shift,
            userId: userId,
            userName: userName,
            syncStatus: syncStatus,
            serverId: serverId,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$QualityEntriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $QualityEntriesTable,
    QualityEntry,
    $$QualityEntriesTableFilterComposer,
    $$QualityEntriesTableOrderingComposer,
    $$QualityEntriesTableAnnotationComposer,
    $$QualityEntriesTableCreateCompanionBuilder,
    $$QualityEntriesTableUpdateCompanionBuilder,
    (
      QualityEntry,
      BaseReferences<_$AppDatabase, $QualityEntriesTable, QualityEntry>
    ),
    QualityEntry,
    PrefetchHooks Function()>;
typedef $$PackagingEntriesTableCreateCompanionBuilder
    = PackagingEntriesCompanion Function({
  required String operationId,
  required String productCode,
  required String productName,
  Value<String?> patternCode,
  Value<String?> machine,
  required int quantity,
  Value<String> packagingType,
  required String shift,
  required String userId,
  Value<String?> userName,
  Value<String> syncStatus,
  Value<String?> serverId,
  Value<DateTime> createdAt,
  Value<DateTime?> updatedAt,
  Value<int> rowid,
});
typedef $$PackagingEntriesTableUpdateCompanionBuilder
    = PackagingEntriesCompanion Function({
  Value<String> operationId,
  Value<String> productCode,
  Value<String> productName,
  Value<String?> patternCode,
  Value<String?> machine,
  Value<int> quantity,
  Value<String> packagingType,
  Value<String> shift,
  Value<String> userId,
  Value<String?> userName,
  Value<String> syncStatus,
  Value<String?> serverId,
  Value<DateTime> createdAt,
  Value<DateTime?> updatedAt,
  Value<int> rowid,
});

class $$PackagingEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $PackagingEntriesTable> {
  $$PackagingEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get operationId => $composableBuilder(
      column: $table.operationId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get productCode => $composableBuilder(
      column: $table.productCode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get productName => $composableBuilder(
      column: $table.productName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get patternCode => $composableBuilder(
      column: $table.patternCode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get machine => $composableBuilder(
      column: $table.machine, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get packagingType => $composableBuilder(
      column: $table.packagingType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get shift => $composableBuilder(
      column: $table.shift, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userName => $composableBuilder(
      column: $table.userName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get serverId => $composableBuilder(
      column: $table.serverId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$PackagingEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $PackagingEntriesTable> {
  $$PackagingEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get operationId => $composableBuilder(
      column: $table.operationId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get productCode => $composableBuilder(
      column: $table.productCode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get productName => $composableBuilder(
      column: $table.productName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get patternCode => $composableBuilder(
      column: $table.patternCode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get machine => $composableBuilder(
      column: $table.machine, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get packagingType => $composableBuilder(
      column: $table.packagingType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get shift => $composableBuilder(
      column: $table.shift, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userName => $composableBuilder(
      column: $table.userName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get serverId => $composableBuilder(
      column: $table.serverId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$PackagingEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PackagingEntriesTable> {
  $$PackagingEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get operationId => $composableBuilder(
      column: $table.operationId, builder: (column) => column);

  GeneratedColumn<String> get productCode => $composableBuilder(
      column: $table.productCode, builder: (column) => column);

  GeneratedColumn<String> get productName => $composableBuilder(
      column: $table.productName, builder: (column) => column);

  GeneratedColumn<String> get patternCode => $composableBuilder(
      column: $table.patternCode, builder: (column) => column);

  GeneratedColumn<String> get machine =>
      $composableBuilder(column: $table.machine, builder: (column) => column);

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<String> get packagingType => $composableBuilder(
      column: $table.packagingType, builder: (column) => column);

  GeneratedColumn<String> get shift =>
      $composableBuilder(column: $table.shift, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get userName =>
      $composableBuilder(column: $table.userName, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => column);

  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$PackagingEntriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PackagingEntriesTable,
    PackagingEntry,
    $$PackagingEntriesTableFilterComposer,
    $$PackagingEntriesTableOrderingComposer,
    $$PackagingEntriesTableAnnotationComposer,
    $$PackagingEntriesTableCreateCompanionBuilder,
    $$PackagingEntriesTableUpdateCompanionBuilder,
    (
      PackagingEntry,
      BaseReferences<_$AppDatabase, $PackagingEntriesTable, PackagingEntry>
    ),
    PackagingEntry,
    PrefetchHooks Function()> {
  $$PackagingEntriesTableTableManager(
      _$AppDatabase db, $PackagingEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PackagingEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PackagingEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PackagingEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> operationId = const Value.absent(),
            Value<String> productCode = const Value.absent(),
            Value<String> productName = const Value.absent(),
            Value<String?> patternCode = const Value.absent(),
            Value<String?> machine = const Value.absent(),
            Value<int> quantity = const Value.absent(),
            Value<String> packagingType = const Value.absent(),
            Value<String> shift = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String?> userName = const Value.absent(),
            Value<String> syncStatus = const Value.absent(),
            Value<String?> serverId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PackagingEntriesCompanion(
            operationId: operationId,
            productCode: productCode,
            productName: productName,
            patternCode: patternCode,
            machine: machine,
            quantity: quantity,
            packagingType: packagingType,
            shift: shift,
            userId: userId,
            userName: userName,
            syncStatus: syncStatus,
            serverId: serverId,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String operationId,
            required String productCode,
            required String productName,
            Value<String?> patternCode = const Value.absent(),
            Value<String?> machine = const Value.absent(),
            required int quantity,
            Value<String> packagingType = const Value.absent(),
            required String shift,
            required String userId,
            Value<String?> userName = const Value.absent(),
            Value<String> syncStatus = const Value.absent(),
            Value<String?> serverId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PackagingEntriesCompanion.insert(
            operationId: operationId,
            productCode: productCode,
            productName: productName,
            patternCode: patternCode,
            machine: machine,
            quantity: quantity,
            packagingType: packagingType,
            shift: shift,
            userId: userId,
            userName: userName,
            syncStatus: syncStatus,
            serverId: serverId,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PackagingEntriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PackagingEntriesTable,
    PackagingEntry,
    $$PackagingEntriesTableFilterComposer,
    $$PackagingEntriesTableOrderingComposer,
    $$PackagingEntriesTableAnnotationComposer,
    $$PackagingEntriesTableCreateCompanionBuilder,
    $$PackagingEntriesTableUpdateCompanionBuilder,
    (
      PackagingEntry,
      BaseReferences<_$AppDatabase, $PackagingEntriesTable, PackagingEntry>
    ),
    PackagingEntry,
    PrefetchHooks Function()>;
typedef $$ShipmentEntriesTableCreateCompanionBuilder = ShipmentEntriesCompanion
    Function({
  required String operationId,
  required String productCode,
  required String productName,
  Value<String?> patternCode,
  required int quantity,
  Value<String> destination,
  required String shift,
  required String userId,
  Value<String?> userName,
  Value<String> syncStatus,
  Value<String?> serverId,
  Value<DateTime> createdAt,
  Value<DateTime?> updatedAt,
  Value<int> rowid,
});
typedef $$ShipmentEntriesTableUpdateCompanionBuilder = ShipmentEntriesCompanion
    Function({
  Value<String> operationId,
  Value<String> productCode,
  Value<String> productName,
  Value<String?> patternCode,
  Value<int> quantity,
  Value<String> destination,
  Value<String> shift,
  Value<String> userId,
  Value<String?> userName,
  Value<String> syncStatus,
  Value<String?> serverId,
  Value<DateTime> createdAt,
  Value<DateTime?> updatedAt,
  Value<int> rowid,
});

class $$ShipmentEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $ShipmentEntriesTable> {
  $$ShipmentEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get operationId => $composableBuilder(
      column: $table.operationId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get productCode => $composableBuilder(
      column: $table.productCode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get productName => $composableBuilder(
      column: $table.productName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get patternCode => $composableBuilder(
      column: $table.patternCode, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get destination => $composableBuilder(
      column: $table.destination, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get shift => $composableBuilder(
      column: $table.shift, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userName => $composableBuilder(
      column: $table.userName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get serverId => $composableBuilder(
      column: $table.serverId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$ShipmentEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $ShipmentEntriesTable> {
  $$ShipmentEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get operationId => $composableBuilder(
      column: $table.operationId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get productCode => $composableBuilder(
      column: $table.productCode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get productName => $composableBuilder(
      column: $table.productName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get patternCode => $composableBuilder(
      column: $table.patternCode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get destination => $composableBuilder(
      column: $table.destination, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get shift => $composableBuilder(
      column: $table.shift, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userName => $composableBuilder(
      column: $table.userName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get serverId => $composableBuilder(
      column: $table.serverId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$ShipmentEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ShipmentEntriesTable> {
  $$ShipmentEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get operationId => $composableBuilder(
      column: $table.operationId, builder: (column) => column);

  GeneratedColumn<String> get productCode => $composableBuilder(
      column: $table.productCode, builder: (column) => column);

  GeneratedColumn<String> get productName => $composableBuilder(
      column: $table.productName, builder: (column) => column);

  GeneratedColumn<String> get patternCode => $composableBuilder(
      column: $table.patternCode, builder: (column) => column);

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<String> get destination => $composableBuilder(
      column: $table.destination, builder: (column) => column);

  GeneratedColumn<String> get shift =>
      $composableBuilder(column: $table.shift, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get userName =>
      $composableBuilder(column: $table.userName, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => column);

  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ShipmentEntriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ShipmentEntriesTable,
    ShipmentEntry,
    $$ShipmentEntriesTableFilterComposer,
    $$ShipmentEntriesTableOrderingComposer,
    $$ShipmentEntriesTableAnnotationComposer,
    $$ShipmentEntriesTableCreateCompanionBuilder,
    $$ShipmentEntriesTableUpdateCompanionBuilder,
    (
      ShipmentEntry,
      BaseReferences<_$AppDatabase, $ShipmentEntriesTable, ShipmentEntry>
    ),
    ShipmentEntry,
    PrefetchHooks Function()> {
  $$ShipmentEntriesTableTableManager(
      _$AppDatabase db, $ShipmentEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShipmentEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShipmentEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShipmentEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> operationId = const Value.absent(),
            Value<String> productCode = const Value.absent(),
            Value<String> productName = const Value.absent(),
            Value<String?> patternCode = const Value.absent(),
            Value<int> quantity = const Value.absent(),
            Value<String> destination = const Value.absent(),
            Value<String> shift = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String?> userName = const Value.absent(),
            Value<String> syncStatus = const Value.absent(),
            Value<String?> serverId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ShipmentEntriesCompanion(
            operationId: operationId,
            productCode: productCode,
            productName: productName,
            patternCode: patternCode,
            quantity: quantity,
            destination: destination,
            shift: shift,
            userId: userId,
            userName: userName,
            syncStatus: syncStatus,
            serverId: serverId,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String operationId,
            required String productCode,
            required String productName,
            Value<String?> patternCode = const Value.absent(),
            required int quantity,
            Value<String> destination = const Value.absent(),
            required String shift,
            required String userId,
            Value<String?> userName = const Value.absent(),
            Value<String> syncStatus = const Value.absent(),
            Value<String?> serverId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ShipmentEntriesCompanion.insert(
            operationId: operationId,
            productCode: productCode,
            productName: productName,
            patternCode: patternCode,
            quantity: quantity,
            destination: destination,
            shift: shift,
            userId: userId,
            userName: userName,
            syncStatus: syncStatus,
            serverId: serverId,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ShipmentEntriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ShipmentEntriesTable,
    ShipmentEntry,
    $$ShipmentEntriesTableFilterComposer,
    $$ShipmentEntriesTableOrderingComposer,
    $$ShipmentEntriesTableAnnotationComposer,
    $$ShipmentEntriesTableCreateCompanionBuilder,
    $$ShipmentEntriesTableUpdateCompanionBuilder,
    (
      ShipmentEntry,
      BaseReferences<_$AppDatabase, $ShipmentEntriesTable, ShipmentEntry>
    ),
    ShipmentEntry,
    PrefetchHooks Function()>;
typedef $$SyncQueueTableCreateCompanionBuilder = SyncQueueCompanion Function({
  Value<int> id,
  required String operationId,
  required String entryType,
  required String action,
  required String payload,
  Value<String> status,
  Value<int> retryCount,
  Value<String?> errorMessage,
  Value<DateTime> createdAt,
  Value<DateTime?> lastAttempt,
  Value<DateTime?> nextRetryAt,
});
typedef $$SyncQueueTableUpdateCompanionBuilder = SyncQueueCompanion Function({
  Value<int> id,
  Value<String> operationId,
  Value<String> entryType,
  Value<String> action,
  Value<String> payload,
  Value<String> status,
  Value<int> retryCount,
  Value<String?> errorMessage,
  Value<DateTime> createdAt,
  Value<DateTime?> lastAttempt,
  Value<DateTime?> nextRetryAt,
});

class $$SyncQueueTableFilterComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get operationId => $composableBuilder(
      column: $table.operationId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entryType => $composableBuilder(
      column: $table.entryType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get action => $composableBuilder(
      column: $table.action, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get errorMessage => $composableBuilder(
      column: $table.errorMessage, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastAttempt => $composableBuilder(
      column: $table.lastAttempt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get nextRetryAt => $composableBuilder(
      column: $table.nextRetryAt, builder: (column) => ColumnFilters(column));
}

class $$SyncQueueTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get operationId => $composableBuilder(
      column: $table.operationId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entryType => $composableBuilder(
      column: $table.entryType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get action => $composableBuilder(
      column: $table.action, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get errorMessage => $composableBuilder(
      column: $table.errorMessage,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastAttempt => $composableBuilder(
      column: $table.lastAttempt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get nextRetryAt => $composableBuilder(
      column: $table.nextRetryAt, builder: (column) => ColumnOrderings(column));
}

class $$SyncQueueTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get operationId => $composableBuilder(
      column: $table.operationId, builder: (column) => column);

  GeneratedColumn<String> get entryType =>
      $composableBuilder(column: $table.entryType, builder: (column) => column);

  GeneratedColumn<String> get action =>
      $composableBuilder(column: $table.action, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => column);

  GeneratedColumn<String> get errorMessage => $composableBuilder(
      column: $table.errorMessage, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastAttempt => $composableBuilder(
      column: $table.lastAttempt, builder: (column) => column);

  GeneratedColumn<DateTime> get nextRetryAt => $composableBuilder(
      column: $table.nextRetryAt, builder: (column) => column);
}

class $$SyncQueueTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SyncQueueTable,
    SyncQueueData,
    $$SyncQueueTableFilterComposer,
    $$SyncQueueTableOrderingComposer,
    $$SyncQueueTableAnnotationComposer,
    $$SyncQueueTableCreateCompanionBuilder,
    $$SyncQueueTableUpdateCompanionBuilder,
    (
      SyncQueueData,
      BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueData>
    ),
    SyncQueueData,
    PrefetchHooks Function()> {
  $$SyncQueueTableTableManager(_$AppDatabase db, $SyncQueueTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> operationId = const Value.absent(),
            Value<String> entryType = const Value.absent(),
            Value<String> action = const Value.absent(),
            Value<String> payload = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int> retryCount = const Value.absent(),
            Value<String?> errorMessage = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> lastAttempt = const Value.absent(),
            Value<DateTime?> nextRetryAt = const Value.absent(),
          }) =>
              SyncQueueCompanion(
            id: id,
            operationId: operationId,
            entryType: entryType,
            action: action,
            payload: payload,
            status: status,
            retryCount: retryCount,
            errorMessage: errorMessage,
            createdAt: createdAt,
            lastAttempt: lastAttempt,
            nextRetryAt: nextRetryAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String operationId,
            required String entryType,
            required String action,
            required String payload,
            Value<String> status = const Value.absent(),
            Value<int> retryCount = const Value.absent(),
            Value<String?> errorMessage = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> lastAttempt = const Value.absent(),
            Value<DateTime?> nextRetryAt = const Value.absent(),
          }) =>
              SyncQueueCompanion.insert(
            id: id,
            operationId: operationId,
            entryType: entryType,
            action: action,
            payload: payload,
            status: status,
            retryCount: retryCount,
            errorMessage: errorMessage,
            createdAt: createdAt,
            lastAttempt: lastAttempt,
            nextRetryAt: nextRetryAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SyncQueueTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SyncQueueTable,
    SyncQueueData,
    $$SyncQueueTableFilterComposer,
    $$SyncQueueTableOrderingComposer,
    $$SyncQueueTableAnnotationComposer,
    $$SyncQueueTableCreateCompanionBuilder,
    $$SyncQueueTableUpdateCompanionBuilder,
    (
      SyncQueueData,
      BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueData>
    ),
    SyncQueueData,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db, _db.users);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db, _db.products);
  $$PatternsTableTableManager get patterns =>
      $$PatternsTableTableManager(_db, _db.patterns);
  $$MachinesTableTableManager get machines =>
      $$MachinesTableTableManager(_db, _db.machines);
  $$ProductionEntriesTableTableManager get productionEntries =>
      $$ProductionEntriesTableTableManager(_db, _db.productionEntries);
  $$QualityEntriesTableTableManager get qualityEntries =>
      $$QualityEntriesTableTableManager(_db, _db.qualityEntries);
  $$PackagingEntriesTableTableManager get packagingEntries =>
      $$PackagingEntriesTableTableManager(_db, _db.packagingEntries);
  $$ShipmentEntriesTableTableManager get shipmentEntries =>
      $$ShipmentEntriesTableTableManager(_db, _db.shipmentEntries);
  $$SyncQueueTableTableManager get syncQueue =>
      $$SyncQueueTableTableManager(_db, _db.syncQueue);
}
