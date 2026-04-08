import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/production_model.dart';
import 'service_providers.dart';

/// Production list state.
class ProductionListState {
  final bool isLoading;
  final List<ProductionModel> productions;
  final String? errorMessage;
  final int totalRecords;
  final int currentPage;

  const ProductionListState({
    this.isLoading = false,
    this.productions = const [],
    this.errorMessage,
    this.totalRecords = 0,
    this.currentPage = 1,
  });

  ProductionListState copyWith({
    bool? isLoading,
    List<ProductionModel>? productions,
    String? errorMessage,
    int? totalRecords,
    int? currentPage,
  }) {
    return ProductionListState(
      isLoading: isLoading ?? this.isLoading,
      productions: productions ?? this.productions,
      errorMessage: errorMessage,
      totalRecords: totalRecords ?? this.totalRecords,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

class ProductionNotifier extends StateNotifier<ProductionListState> {
  final Ref _ref;

  ProductionNotifier(this._ref) : super(const ProductionListState());

  Future<void> loadProductions({
    String? shift,
    String? stage,
    String? date,
    String? startAt,
    String? endAt,
    int page = 1,
    int limit = 50,
  }) async {
    state = state.copyWith(isLoading: true);

    final result = await _ref.read(productionRepositoryProvider).getProductions(
          shift: shift,
          stage: stage,
          date: date,
          startAt: startAt,
          endAt: endAt,
          page: page,
          limit: limit,
        );

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        );
      },
      (response) {
        state = state.copyWith(
          isLoading: false,
          productions: response.data,
          totalRecords: response.total,
          currentPage: response.page,
        );
      },
    );
  }

  Future<bool> createProduction(Map<String, dynamic> data) async {
    final result =
        await _ref.read(productionRepositoryProvider).createProduction(data);
    return result.fold(
      (failure) {
        state = state.copyWith(errorMessage: failure.message);
        return false;
      },
      (production) {
        state = state.copyWith(
          productions: [production, ...state.productions],
          totalRecords: state.totalRecords + 1,
        );
        return true;
      },
    );
  }

  Future<bool> updateProduction(String id, Map<String, dynamic> data) async {
    final result = await _ref
        .read(productionRepositoryProvider)
        .updateProduction(id, data);
    return result.fold(
      (failure) {
        state = state.copyWith(errorMessage: failure.message);
        return false;
      },
      (updated) {
        final updatedList = state.productions.map((p) {
          return p.id == id ? updated : p;
        }).toList();
        state = state.copyWith(productions: updatedList);
        return true;
      },
    );
  }

  Future<bool> cancelProduction(String id) async {
    final result =
        await _ref.read(productionRepositoryProvider).cancelProduction(id);
    return result.fold(
      (failure) {
        state = state.copyWith(errorMessage: failure.message);
        return false;
      },
      (_) {
        state = state.copyWith(
          productions: state.productions.where((p) => p.id != id).toList(),
          totalRecords: state.totalRecords - 1,
        );
        return true;
      },
    );
  }

  Future<int> syncOfflineRecords() async {
    return await _ref.read(productionRepositoryProvider).syncPendingRecords();
  }

  Future<int> get pendingSyncCount =>
      _ref.read(productionRepositoryProvider).pendingSyncCount;
}

final productionProvider =
    StateNotifierProvider<ProductionNotifier, ProductionListState>(
  ProductionNotifier.new,
);
