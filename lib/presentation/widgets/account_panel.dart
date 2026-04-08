import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/network/network_info.dart';
import '../providers/auth_provider.dart';

/// Shows account info bottom sheet with user details, system info, and logout.
void showAccountPanel(BuildContext context, WidgetRef ref) {
  final user = ref.read(authProvider).user;
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _AccountPanelContent(user: user, ref: ref, ctx: ctx),
  );
}

class _AccountPanelContent extends StatefulWidget {
  final dynamic user;
  final WidgetRef ref;
  final BuildContext ctx;

  const _AccountPanelContent(
      {required this.user, required this.ref, required this.ctx});

  @override
  State<_AccountPanelContent> createState() => _AccountPanelContentState();
}

class _AccountPanelContentState extends State<_AccountPanelContent> {
  bool _isOnline = true;
  StreamSubscription<bool>? _connectivitySub;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _listenConnectivity();
  }

  Future<void> _checkConnectivity() async {
    final networkInfo = NetworkInfo();
    final online = await networkInfo.isConnected;
    if (mounted) setState(() => _isOnline = online);
  }

  void _listenConnectivity() {
    final networkInfo = NetworkInfo();
    _connectivitySub =
        networkInfo.onConnectionStatusChanged.listen((connected) {
      if (mounted && connected != _isOnline) {
        setState(() => _isOnline = connected);
      }
    });
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'Yönetici';
      case 'supervisor':
        return 'Süpervizör';
      default:
        return 'çalışan';
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final personnelNo = (user?.personnelNo ?? '').toString().trim();
    final showShiftInfo = user?.role == 'worker';
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(user?.name ?? '',
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.headlineSmall
                        .copyWith(fontWeight: FontWeight.w700)),
              ),
              
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.factory_outlined,
                  color: AppColors.primary,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  _getRoleLabel(user?.role ?? ''),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (personnelNo.isNotEmpty) ...[
                  const SizedBox(width: 10),
                  Container(
                    width: 1,
                    height: 14,
                    color: AppColors.primary.withValues(alpha: 0.25),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'No: $personnelNo',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          // SİSTEM BİLGİLERİ section
          Align(
            alignment: Alignment.centerLeft,
            child: Text('SİSTEM BİLGİLERİ',
                style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textHint,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8)),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                if (showShiftInfo)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        const Icon(Icons.badge_outlined,
                            color: AppColors.textSecondary, size: 20),
                        const SizedBox(width: 12),
                        Text('Vardiya',
                            style: AppTypography.bodyMedium
                                .copyWith(color: AppColors.textSecondary)),
                        const Spacer(),
                        Text(user?.assignedShift ?? 'Atanmamış',
                            style: AppTypography.bodyMedium
                                .copyWith(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                if (showShiftInfo)
                  Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: AppColors.border.withValues(alpha: 0.5)),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      const Icon(Icons.wifi,
                          color: AppColors.textSecondary, size: 20),
                      const SizedBox(width: 12),
                      Text('Durum',
                          style: AppTypography.bodyMedium
                              .copyWith(color: AppColors.textSecondary)),
                      const Spacer(),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color:
                              _isOnline ? AppColors.success : AppColors.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(_isOnline ? 'Çevrimiçi' : 'Çevrimdışı',
                          style: AppTypography.bodyMedium.copyWith(
                              color: _isOnline
                                  ? AppColors.success
                                  : AppColors.error,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Logout button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                widget.ref.read(authProvider.notifier).logout();
              },
              icon: Icon(Icons.logout, color: Colors.pink.shade400, size: 20),
              label: Text('Oturumu Kapat',
                  style: AppTypography.button.copyWith(
                      color: Colors.pink.shade400,
                      fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.pink.shade300),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
