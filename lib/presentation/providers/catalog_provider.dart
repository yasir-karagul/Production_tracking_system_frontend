import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/utils/pattern_image_utils.dart';
import '../../data/datasources/remote/product_remote_datasource.dart';
import 'service_providers.dart';

final productRemoteDataSourceProvider = Provider<ProductRemoteDataSource>(
  (ref) => ProductRemoteDataSource(ref.read(apiClientProvider)),
);

class CatalogState {
  final List<Map<String, dynamic>> products;
  final List<Map<String, dynamic>> patterns;
  final List<Map<String, dynamic>> machines;
  final List<Map<String, dynamic>> stages;
  final bool isLoading;
  final String? error;

  const CatalogState({
    this.products = const [],
    this.patterns = const [],
    this.machines = const [],
    this.stages = const [],
    this.isLoading = false,
    this.error,
  });

  List<String> get productNames => products
      .where((p) => p['is_active'] != false)
      .map((p) => p['name'] as String)
      .toSet()
      .toList();

  List<String> get patternNames => patterns
      .where((p) => p['is_active'] != false)
      .map((p) => p['name'] as String)
      .toSet()
      .toList();

  List<String> get stageNames {
    final names = <String>[];
    final seen = <String>{};

    void addName(String rawName) {
      final name = rawName.trim();
      if (name.isEmpty) return;
      final key = name.toLowerCase();
      if (seen.add(key)) {
        names.add(name);
      }
    }

    for (final stage in stages) {
      if (stage['is_deleted'] == true || stage['is_active'] == false) {
        continue;
      }
      addName((stage['name'] ?? '').toString());
    }

    if (names.isNotEmpty) {
      return names;
    }

    for (final machine in machines) {
      if (machine['is_active'] == false) continue;
      addName((machine['stage'] ?? '').toString());
    }
    return names;
  }

  List<String> machinesForStage(String stage) {
    final stageKey = _catalogKey(stage);
    if (stageKey.isEmpty) return const [];

    final names = <String>[];
    final seen = <String>{};

    for (final machine in machines) {
      if (machine['is_active'] == false) continue;
      final machineStageKey = _catalogKey((machine['stage'] ?? '').toString());
      if (machineStageKey != stageKey) continue;

      final machineName = (machine['name'] ?? '').toString().trim();
      if (machineName.isEmpty) continue;

      final machineKey = machineName.toLowerCase();
      if (seen.add(machineKey)) {
        names.add(machineName);
      }
    }

    return names;
  }

  static String _catalogKey(String value) => value.trim().toLowerCase();

  CatalogState copyWith({
    List<Map<String, dynamic>>? products,
    List<Map<String, dynamic>>? patterns,
    List<Map<String, dynamic>>? machines,
    List<Map<String, dynamic>>? stages,
    bool? isLoading,
    String? error,
  }) {
    return CatalogState(
      products: products ?? this.products,
      patterns: patterns ?? this.patterns,
      machines: machines ?? this.machines,
      stages: stages ?? this.stages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class CatalogNotifier extends StateNotifier<CatalogState> {
  final Ref _ref;

  CatalogNotifier(this._ref) : super(const CatalogState());

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[CATALOG] $message');
    }
  }

  bool _setStateSafely(CatalogState nextState, {required String source}) {
    try {
      state = nextState;
      return true;
    } on StateNotifierListenerError catch (e, st) {
      _log(
          'State update failed at $source with ${e.errors.length} listener error(s)');
      for (var i = 0; i < e.errors.length; i++) {
        _log('listener[$i] error: ${e.errors[i]}');
        _log('listener[$i] stack: ${e.stackTraces[i]}');
      }
      _log('setter stack: $st');
      return false;
    }
  }

  Future<void> loadAll() async {
    if (state.isLoading) {
      _log('loadAll skipped: already loading');
      return;
    }
    _log(
      'loadAll start (products=${state.products.length}, patterns=${state.patterns.length}, machines=${state.machines.length}, stages=${state.stages.length})',
    );
    _setStateSafely(
      state.copyWith(isLoading: true, error: null),
      source: 'loadAll:start',
    );

    final db = _ref.read(databaseProvider);
    var hasPrimedCache = false;
    try {
      final cachedProducts = await db.getAllProducts();
      final cachedPatterns = await db.getAllPatterns();
      final cachedMachines = await db.getAllMachines();

      if (cachedProducts.isNotEmpty ||
          cachedPatterns.isNotEmpty ||
          cachedMachines.isNotEmpty) {
        hasPrimedCache = true;
        _setStateSafely(
          state.copyWith(
            products: _mapCachedProducts(cachedProducts),
            patterns: _mapCachedPatterns(cachedPatterns),
            machines: _mapCachedMachines(cachedMachines),
            isLoading: true,
            error: null,
          ),
          source: 'loadAll:cache-prime',
        );
        _log(
          'loadAll cache prime success (products=${cachedProducts.length}, patterns=${cachedPatterns.length}, machines=${cachedMachines.length})',
        );
      }
    } catch (cachePrimeError, cachePrimeStack) {
      _log('loadAll cache prime failed: $cachePrimeError');
      _log('loadAll cache prime stack: $cachePrimeStack');
    }

    try {
      final ds = _ref.read(productRemoteDataSourceProvider);
      _log('loadAll -> requesting products/patterns/machines/stages');
      final results = await Future.wait([
        ds.getProducts(),
        ds.getPatterns(),
        ds.getMachines(),
      ]);
      List<Map<String, dynamic>> stageResults = const [];
      try {
        stageResults = await ds.getStages();
      } catch (stageError, stageStack) {
        _log('loadAll -> stages fetch failed: $stageError');
        _log('loadAll -> stages fetch stack: $stageStack');
      }
      _log(
        'loadAll -> remote success (products=${results[0].length}, patterns=${results[1].length}, machines=${results[2].length}, stages=${stageResults.length})',
      );
      final patternsWithOfflineImages =
          await _attachOfflinePatternImages(results[1]);

      final db = _ref.read(databaseProvider);
      await db.cacheProducts(results[0]);
      await db.cachePatterns(patternsWithOfflineImages);
      await db.cacheMachines(results[2]);

      _setStateSafely(
        state.copyWith(
          products: results[0],
          patterns: patternsWithOfflineImages,
          machines: results[2],
          stages: stageResults,
          isLoading: false,
          error: null,
        ),
        source: 'loadAll:success',
      );
      _log('loadAll success -> state updated');
    } catch (e, st) {
      _log('loadAll remote failed: $e');
      _log('loadAll remote stack: $st');
      if (hasPrimedCache) {
        _setStateSafely(
          state.copyWith(
            isLoading: false,
            error: e.toString(),
          ),
          source: 'loadAll:remote-failed-cache-primed',
        );
        _log('loadAll remote failed -> kept cache-primed state');
        return;
      }
      try {
        final cachedProducts = await db.getAllProducts();
        final cachedPatterns = await db.getAllPatterns();
        final cachedMachines = await db.getAllMachines();

        _log(
          'loadAll cache fallback success (products=${cachedProducts.length}, patterns=${cachedPatterns.length}, machines=${cachedMachines.length})',
        );
        _setStateSafely(
          state.copyWith(
            products: _mapCachedProducts(cachedProducts),
            patterns: _mapCachedPatterns(cachedPatterns),
            machines: _mapCachedMachines(cachedMachines),
            isLoading: false,
            error: e.toString(),
          ),
          source: 'loadAll:cache-fallback',
        );
      } catch (cacheError, cacheStack) {
        _log('loadAll cache fallback failed: $cacheError');
        _log('loadAll cache fallback stack: $cacheStack');
        _setStateSafely(
          state.copyWith(
            products: const [],
            patterns: const [],
            machines: const [],
            isLoading: false,
            error: '$e | cache: $cacheError',
          ),
          source: 'loadAll:cache-fallback-error',
        );
      }
    } finally {
      if (state.isLoading) {
        _setStateSafely(
          state.copyWith(isLoading: false),
          source: 'loadAll:finally',
        );
        _log('loadAll finally forced isLoading=false');
      }
    }
  }

  List<Map<String, dynamic>> _mapCachedProducts(List cachedProducts) {
    return cachedProducts.map((item) {
      final p = item as dynamic;
      return {
        'id': p.id,
        'code': p.productCode,
        'name': p.productName,
        'is_active': p.isActive,
      };
    }).toList();
  }

  List<Map<String, dynamic>> _mapCachedPatterns(List cachedPatterns) {
    return cachedPatterns.map((item) {
      final p = item as dynamic;
      return {
        'id': p.id,
        'code': p.patternCode,
        'name': p.patternName,
        'thumbnail_url': p.thumbnailUrl,
        'image_url': p.thumbnailUrl,
        'local_image_path': p.thumbnailUrl,
        'is_active': p.isActive,
      };
    }).toList();
  }

  List<Map<String, dynamic>> _mapCachedMachines(List cachedMachines) {
    return cachedMachines.map((item) {
      final m = item as dynamic;
      return {
        'id': m.id,
        'name': m.name,
        'stage': m.stage,
        'is_active': m.isActive,
      };
    }).toList();
  }

  Future<void> loadMachinesForStage(String stage) async {
    try {
      final ds = _ref.read(productRemoteDataSourceProvider);
      final machines = await ds.getMachines(stage: stage);
      await _ref.read(databaseProvider).cacheMachines(machines);
      _setStateSafely(
        state.copyWith(machines: machines),
        source: 'loadMachinesForStage:success',
      );
    } catch (_) {
      final cached =
          await _ref.read(databaseProvider).getMachinesByStage(stage);
      _setStateSafely(
        state.copyWith(
          machines: cached
              .map((m) => {
                    'id': m.id,
                    'name': m.name,
                    'stage': m.stage,
                    'is_active': m.isActive,
                  })
              .toList(),
        ),
        source: 'loadMachinesForStage:cache-fallback',
      );
    }
  }

  Future<List<Map<String, dynamic>>> _attachOfflinePatternImages(
    List<Map<String, dynamic>> patterns,
  ) async {
    try {
      final cacheDir = await _patternImageCacheDirectory();
      final cached = <Map<String, dynamic>>[];

      for (var index = 0; index < patterns.length; index++) {
        final pattern = Map<String, dynamic>.from(patterns[index]);
        final resolved = PatternImageUtils.resolvePatternImageRef(pattern);

        if (resolved == null ||
            PatternImageUtils.isLocalFileRef(resolved) ||
            !(resolved.startsWith('http://') ||
                resolved.startsWith('https://'))) {
          cached.add(pattern);
          continue;
        }

        final localImageUri = await _downloadPatternImage(
          imageUrl: resolved,
          cacheDir: cacheDir,
          cacheKey: _patternCacheKey(pattern, index, resolved),
        );

        if (localImageUri != null) {
          pattern['local_image_path'] = localImageUri;
        }
        cached.add(pattern);
      }

      return cached;
    } catch (_) {
      return patterns.map(Map<String, dynamic>.from).toList();
    }
  }

  Future<Directory> _patternImageCacheDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory(p.join(appDir.path, 'pattern_images'));
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }

  Future<String?> _downloadPatternImage({
    required String imageUrl,
    required Directory cacheDir,
    required String cacheKey,
  }) async {
    final filePath =
        p.join(cacheDir.path, '$cacheKey${_imageExtension(imageUrl)}');
    final file = File(filePath);
    if (await file.exists() && await file.length() > 0) {
      return Uri.file(file.path).toString();
    }

    try {
      final response = await _ref.read(apiClientProvider).dio.get<List<int>>(
            imageUrl,
            options: Options(responseType: ResponseType.bytes),
          );
      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) return null;
      await file.writeAsBytes(bytes, flush: true);
      return Uri.file(file.path).toString();
    } catch (_) {
      return null;
    }
  }

  String _patternCacheKey(
    Map<String, dynamic> pattern,
    int index,
    String imageUrl,
  ) {
    final rawId = (pattern['_id'] ??
            pattern['id'] ??
            pattern['code'] ??
            pattern['pattern_code'] ??
            'pattern_$index')
        .toString();
    final safeId = rawId.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    return '${safeId}_${_fnv1aHash(imageUrl)}';
  }

  String _fnv1aHash(String input) {
    var hash = 0x811C9DC5;
    for (final codeUnit in input.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16);
  }

  String _imageExtension(String imageUrl) {
    final path = Uri.tryParse(imageUrl)?.path ?? '';
    final extension = p.extension(path).toLowerCase();
    if (extension == '.jpg' ||
        extension == '.jpeg' ||
        extension == '.png' ||
        extension == '.webp') {
      return extension;
    }
    return '.img';
  }
}

final catalogProvider = StateNotifierProvider<CatalogNotifier, CatalogState>(
  CatalogNotifier.new,
);
