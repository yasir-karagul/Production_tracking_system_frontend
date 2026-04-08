import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/constants/app_spacing.dart';

/// Shift indicator badge widget.
class ShiftBadge extends StatelessWidget {
  final String shiftName;
  final bool isActive;

  const ShiftBadge({super.key, required this.shiftName, this.isActive = false});

  Color get _color {
    switch (shiftName) {
      case 'Shift 1':
        return AppColors.shift1;
      case 'Shift 2':
        return AppColors.shift2;
      case 'Shift 3':
        return AppColors.shift3;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? _color : _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        shiftName,
        style: TextStyle(
          color: isActive ? Colors.white : _color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Stage card for dashboard.
class StageCard extends StatelessWidget {
  final String stageName;
  final int quantity;
  final int recordCount;
  final Color color;
  final VoidCallback? onTap;

  const StageCard({
    super.key,
    required this.stageName,
    required this.quantity,
    required this.recordCount,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                stageName,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                '$quantity',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$recordCount kayıt',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Loading overlay widget.
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;

  const LoadingOverlay(
      {super.key, required this.isLoading, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withValues(alpha: 0.3),
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
      ],
    );
  }
}

/// Empty state widget.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const EmptyState(
      {super.key, required this.icon, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary)),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(subtitle!,
                  textAlign: TextAlign.center,
                  style:
                      const TextStyle(fontSize: 13, color: AppColors.textHint)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Sync status indicator.
class SyncStatusBadge extends StatelessWidget {
  final int pendingCount;

  const SyncStatusBadge({super.key, required this.pendingCount});

  @override
  Widget build(BuildContext context) {
    if (pendingCount == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.sync, size: 14, color: AppColors.warning),
          const SizedBox(width: 4),
          Text(
            '$pendingCount bekliyor',
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.warning),
          ),
        ],
      ),
    );
  }
}

/// Standard sync state chip used across top bars.
class SyncStatusChip extends StatelessWidget {
  final bool isSyncing;
  final bool isOnline;
  final int pendingCount;
  final int failedCount;

  const SyncStatusChip({
    super.key,
    required this.isSyncing,
    required this.isOnline,
    this.pendingCount = 0,
    this.failedCount = 0,
  });

  ({IconData icon, Color color, String label}) _resolveVisual() {
    if (isSyncing) {
      return (
        icon: Icons.sync,
        color: AppColors.warning,
        label: 'Eşitleniyor',
      );
    }
    if (!isOnline) {
      return (
        icon: Icons.cloud_off,
        color: AppColors.textHint,
        label: pendingCount > 0 ? 'Çevrimdışı ($pendingCount)' : 'Çevrimdışı',
      );
    }
    if (failedCount > 0) {
      return (
        icon: Icons.error_outline,
        color: AppColors.error,
        label: '$failedCount hata',
      );
    }
    if (pendingCount > 0) {
      return (
        icon: Icons.schedule,
        color: AppColors.warning,
        label: '$pendingCount bekliyor',
      );
    }
    return (
      icon: Icons.check_circle,
      color: AppColors.success,
      label: 'Senkron',
    );
  }

  @override
  Widget build(BuildContext context) {
    final visual = _resolveVisual();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: visual.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: visual.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(visual.icon, size: 16, color: visual.color),
          const SizedBox(width: 6),
          Text(
            visual.label,
            style: TextStyle(
              color: visual.color,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Unified top bar used across app screens.
/// Order is fixed: Title -> Sync Status -> Profile icon.
class UnifiedTopBar extends StatelessWidget {
  final String title;
  final bool isSyncing;
  final bool isOnline;
  final int pendingCount;
  final int failedCount;
  final VoidCallback onProfileTap;

  const UnifiedTopBar({
    super.key,
    required this.title,
    required this.isSyncing,
    required this.isOnline,
    required this.onProfileTap,
    this.pendingCount = 0,
    this.failedCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppColors.surface,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.headlineSmall.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SyncStatusChip(
            isSyncing: isSyncing,
            isOnline: isOnline,
            pendingCount: pendingCount,
            failedCount: failedCount,
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onProfileTap,
            child: const CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.surfaceVariant,
              child: Icon(
                Icons.person_outline,
                color: AppColors.textSecondary,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
