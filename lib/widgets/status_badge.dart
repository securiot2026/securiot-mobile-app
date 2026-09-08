import 'package:flutter/material.dart';

import '../core/i18n/app_localizations.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../models/alert.dart';

/// Online/offline indicator. Never color alone: pairs an icon, the color,
/// and a text label, per the A11Y "no color alone" rule inherited from the
/// sibling Web App surface.
class OnlineStatusBadge extends StatelessWidget {
  const OnlineStatusBadge({super.key, required this.isOnline});

  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = isOnline ? AppColors.statusOnline : AppColors.statusOffline;
    final label = isOnline ? l10n.t('statusOnline') : l10n.t('statusOffline');
    final icon = isOnline ? Icons.check_circle : Icons.remove_circle_outline;

    return Semantics(
      label: label,
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Alert severity chip. Same icon+text+color contract as [OnlineStatusBadge].
class SeverityBadge extends StatelessWidget {
  const SeverityBadge({super.key, required this.severity});

  final AlertSeverity severity;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (color, label, icon) = switch (severity) {
      AlertSeverity.high => (AppColors.severityHigh, l10n.t('severityHigh'), Icons.warning_amber_rounded),
      AlertSeverity.medium => (AppColors.severityMedium, l10n.t('severityMedium'), Icons.error_outline),
      AlertSeverity.low => (AppColors.severityLow, l10n.t('severityLow'), Icons.info_outline),
    };

    return Semantics(
      label: label,
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: AppSpacing.xs),
              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
