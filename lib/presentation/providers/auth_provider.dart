import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/errors/failures.dart';
import '../../data/models/user_model.dart';
import 'service_providers.dart';

/// Authentication state.
enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;
  final String? currentShift;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
    this.currentShift,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? errorMessage,
    String? currentShift,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
      currentShift: currentShift ?? this.currentShift,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref _ref;

  AuthNotifier(this._ref) : super(const AuthState());

  Future<void> login(String username, String loginCode) async {
    final deferredLogout =
        await _ref.read(authRepositoryProvider).isDeferredLogoutForSync();
    if (deferredLogout) {
      final pendingSyncCount =
          await _ref.read(databaseProvider).getPendingSyncCount();
      if (pendingSyncCount > 0) {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage:
              'Bekleyen çevrimdışı kayıtlar senkronize edilmeden yeni oturum açılamaz.',
        );
        return;
      }
    }

    state = state.copyWith(status: AuthStatus.loading);

    final result =
        await _ref.read(authRepositoryProvider).login(username, loginCode);

    result.fold(
      (failure) {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: failure.message,
        );
      },
      (user) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
        );
      },
    );
  }

  Future<void> checkAuth() async {
    final repo = _ref.read(authRepositoryProvider);
    final deferredLogout = await repo.isDeferredLogoutForSync();
    if (deferredLogout) {
      state = const AuthState(status: AuthStatus.unauthenticated);
      return;
    }

    final isLoggedIn = await repo.isLoggedIn();

    if (!isLoggedIn) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return;
    }

    final result = await repo.getMe();
    await result.fold<Future<void>>(
      (failure) async {
        if (failure is AuthFailure && failure.statusCode == 401) {
          await repo.logout();
          state = const AuthState(status: AuthStatus.unauthenticated);
          return;
        }

        final cachedUser = await repo.getCachedUser();
        if (cachedUser != null) {
          state = state.copyWith(
            status: AuthStatus.authenticated,
            user: cachedUser,
            errorMessage: null,
          );
          return;
        }

        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          errorMessage: failure.message,
        );
      },
      (user) async {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          errorMessage: null,
        );
      },
    );
  }

  Future<void> logout() async {
    final pendingSyncCount =
        await _ref.read(databaseProvider).getPendingSyncCount();
    final shouldPreserveTokens = pendingSyncCount > 0;
    await _ref.read(authRepositoryProvider).logout(
          preserveTokensForPendingSync: shouldPreserveTokens,
        );
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void clearError() {
    state =
        state.copyWith(status: AuthStatus.unauthenticated, errorMessage: null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
