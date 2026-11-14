import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';

/// Section title with an optional trailing count or action. Marked as a
/// header for screen readers (pattern from Astryx "Settings Panels").
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(title, style: Theme.of(context).textTheme.titleLarge),
            ),
          ),
          if (trailing != null)
            Text(
              trailing!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textoMute),
            ),
        ],
      ),
    );
  }
}
