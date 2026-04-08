import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/entry_providers.dart';
import '../screens/entry_form/entry_form_screen.dart';
import '../screens/worker_history/worker_history_screen.dart';
import '../screens/daily_report/daily_report_screen.dart';
import '../screens/settings/settings_screen.dart';

/// Main shell with role-based bottom navigation:
/// - Worker: Entry Form + History
/// - Admin: History + Reports + Settings
/// - Supervisor: Entry Form + History + Reports
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _currentIndex = 0;
  String? _lastAnnouncedPageId;

  List<Widget> _getScreens(String role) {
    switch (role) {
      case 'admin':
        return const [
          WorkerHistoryScreen(),
          DailyReportScreen(),
          SettingsScreen()
        ];
      case 'worker':
        return const [EntryFormScreen(), WorkerHistoryScreen()];
      default: // supervisor
        return const [
          EntryFormScreen(),
          WorkerHistoryScreen(),
          DailyReportScreen(),
        ];
    }
  }

  List<BottomNavigationBarItem> _getNavItems(String role, SyncState syncState) {
    final historyItem = BottomNavigationBarItem(
      icon: Badge(
        isLabelVisible: syncState.pendingCount > 0,
        label: Text('${syncState.pendingCount}'),
        child: const Icon(Icons.history_outlined),
      ),
      activeIcon: Badge(
        isLabelVisible: syncState.pendingCount > 0,
        label: Text('${syncState.pendingCount}'),
        child: const Icon(Icons.history),
      ),
      label: 'Ge\u00e7mi\u015f',
    );
    const entryItem = BottomNavigationBarItem(
      icon: Icon(Icons.add_circle_outline),
      activeIcon: Icon(Icons.add_circle),
      label: '\u00dcretim Giri\u015fi',
    );
    const reportItem = BottomNavigationBarItem(
      icon: Icon(Icons.bar_chart_outlined),
      activeIcon: Icon(Icons.bar_chart),
      label: 'Raporlar',
    );
    const settingsItem = BottomNavigationBarItem(
      icon: Icon(Icons.settings_outlined),
      activeIcon: Icon(Icons.settings),
      label: 'Ayarlar',
    );

    switch (role) {
      case 'admin':
        return [historyItem, reportItem, settingsItem];
      case 'worker':
        return [entryItem, historyItem];
      default: // supervisor
        return [entryItem, historyItem, reportItem];
    }
  }

  List<String> _getScreenIds(String role) {
    switch (role) {
      case 'admin':
        return const [
          AppPageIds.workerHistory,
          AppPageIds.dailyReport,
          AppPageIds.settings,
        ];
      case 'worker':
        return const [
          AppPageIds.entryForm,
          AppPageIds.workerHistory,
        ];
      default: // supervisor
        return const [
          AppPageIds.entryForm,
          AppPageIds.workerHistory,
          AppPageIds.dailyReport,
        ];
    }
  }

  void _announceCurrentPageEnter(List<String> screenIds) {
    if (screenIds.isEmpty) return;
    final pageId = screenIds[_currentIndex];
    if (pageId == _lastAnnouncedPageId) return;

    _lastAnnouncedPageId = pageId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(pageRefreshProvider.notifier).markPageEntered(pageId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final syncState = ref.watch(syncProvider);
    final role = user?.role ?? 'worker';
    final screens = _getScreens(role);
    final screenIds = _getScreenIds(role);
    final navItems = _getNavItems(role, syncState);

    // Clamp index if role changes
    if (_currentIndex >= screens.length) {
      _currentIndex = 0;
    }
    _announceCurrentPageEnter(screenIds);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            if (_currentIndex == index) return;
            setState(() => _currentIndex = index);
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textHint,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          elevation: 0,
          items: navItems,
        ),
      ),
    );
  }
}
