import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/network/api_client.dart';
import '../../core/network/network_info.dart';
import '../../data/database/app_database.dart';
import '../../data/datasources/local/production_local_datasource.dart';
import '../../data/datasources/remote/auth_remote_datasource.dart';
import '../../data/datasources/remote/production_remote_datasource.dart';
import '../../data/datasources/remote/report_remote_datasource.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/production_repository.dart';
import '../../data/repositories/report_repository.dart';
import '../../application/catalog_service.dart';
import '../../application/entry_service.dart';
import '../../application/sync_service.dart';

// ---- Core ----
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(),
);

final networkInfoProvider = Provider<NetworkInfo>((ref) => NetworkInfo());

// ---- Database ----
final databaseProvider = Provider<AppDatabase>((ref) => AppDatabase.instance);

// ---- Application Services ----
final entryServiceProvider = Provider<EntryService>(
  (ref) => EntryService(ref.read(databaseProvider)),
);

final catalogServiceProvider = Provider<CatalogService>(
  (ref) => CatalogService(
    ref.read(databaseProvider),
    apiClient: ref.read(apiClientProvider),
    networkInfo: ref.read(networkInfoProvider),
  ),
);

final syncServiceProvider = Provider<SyncService>(
  (ref) => SyncService(ref.read(databaseProvider)),
);

// ---- Data Sources ----
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>(
  (ref) => AuthRemoteDataSource(ref.read(apiClientProvider)),
);

final productionRemoteDataSourceProvider = Provider<ProductionRemoteDataSource>(
  (ref) => ProductionRemoteDataSource(ref.read(apiClientProvider)),
);

final productionLocalDataSourceProvider = Provider<ProductionLocalDataSource>(
  (ref) => ProductionLocalDataSource(),
);

final reportRemoteDataSourceProvider = Provider<ReportRemoteDataSource>(
  (ref) => ReportRemoteDataSource(ref.read(apiClientProvider)),
);

// ---- Repositories ----
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    ref.read(authRemoteDataSourceProvider),
    ref.read(secureStorageProvider),
  ),
);

final productionRepositoryProvider = Provider<ProductionRepository>(
  (ref) => ProductionRepository(
    ref.read(productionRemoteDataSourceProvider),
    ref.read(productionLocalDataSourceProvider),
    ref.read(networkInfoProvider),
  ),
);

final reportRepositoryProvider = Provider<ReportRepository>(
  (ref) => ReportRepository(ref.read(reportRemoteDataSourceProvider)),
);
