import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/shift_utils.dart';
import 'data/database/app_database.dart';
import 'application/sync_service.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/screens/login/login_screen.dart';
import 'presentation/screens/splash/splash_screen.dart';
import 'presentation/widgets/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Turkish locale for date formatting
  await initializeDateFormatting('tr_TR', null);

  // Initialize Drift database (singleton)
  // ignore: unused_local_variable
  final db = AppDatabase.instance;

  // Initialize Workmanager for background sync
  await initWorkmanager();

  runApp(
    const ProviderScope(
      child: MaiaPorselenApp(),
    ),
  );
}

class MaiaPorselenApp extends ConsumerStatefulWidget {
  const MaiaPorselenApp({super.key});

  @override
  ConsumerState<MaiaPorselenApp> createState() => _MaiaPorselenAppState();
}

class _MaiaPorselenAppState extends ConsumerState<MaiaPorselenApp> {
  static const Duration _shiftMonitorInterval = Duration(seconds: 30);
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  Timer? _shiftMonitorTimer;
  bool _shiftExpiryHandled = false;

  @override
  void initState() {
    super.initState();
    // Check if user is already logged in
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).checkAuth();
    });
  }

  @override
  void dispose() {
    _shiftMonitorTimer?.cancel();
    super.dispose();
  }

  void _syncShiftMonitor(AuthState authState) {
    final user = authState.user;
    final shouldMonitor = authState.status == AuthStatus.authenticated &&
        user != null &&
        user.role == 'worker';

    if (!shouldMonitor) {
      _shiftMonitorTimer?.cancel();
      _shiftMonitorTimer = null;
      _shiftExpiryHandled = false;
      return;
    }

    _shiftMonitorTimer ??=
        Timer.periodic(_shiftMonitorInterval, (_) => _evaluateShiftLockout());
    _evaluateShiftLockout();
  }

  Future<void> _evaluateShiftLockout() async {
    if (!mounted) return;

    final authState = ref.read(authProvider);
    final user = authState.user;
    if (authState.status != AuthStatus.authenticated ||
        user == null ||
        user.role != 'worker') {
      return;
    }

    final assignedShift = user.assignedShift.trim();
    final outOfShift = assignedShift.isEmpty || !isUserInShift(assignedShift);
    if (!outOfShift) {
      _shiftExpiryHandled = false;
      return;
    }

    if (_shiftExpiryHandled) return;
    _shiftExpiryHandled = true;

    final reason = assignedShift.isEmpty
        ? 'Size atanmış vardiya yapılandırılmamış. Oturum sona erdi.'
        : 'Vardiyanız sona erdi. Otomatik olarak oturumunuz kapatıldı.';

    final messenger = _scaffoldMessengerKey.currentState;
    messenger
      ?..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(reason),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 4),
        ),
      );

    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    await ref.read(authProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    _syncShiftMonitor(authState);

    return MaterialApp(
      title: 'Maia Porselen',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: _scaffoldMessengerKey,
      theme: AppTheme.light,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('tr', 'TR'),
      ],
      locale: const Locale('tr', 'TR'),
      home: _buildHome(authState),
    );
  }

  Widget _buildHome(AuthState authState) {
    switch (authState.status) {
      case AuthStatus.initial:
      case AuthStatus.loading:
        return const SplashScreen();
      case AuthStatus.authenticated:
        return const MainShell();
      case AuthStatus.unauthenticated:
      case AuthStatus.error:
        return const LoginScreen();
    }
  }
}
