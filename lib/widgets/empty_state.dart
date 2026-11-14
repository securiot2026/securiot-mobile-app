import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';

/// Empty state with icon, heading, body and an optional action button
/// (for example "Clear filters"). Same layout the list views used before,
/// now with an action slot.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.heading,
    required this.body,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String heading;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: Icon(icon, size: 40, color: AppColors.textoMute),
            ),
            const SizedBox(height: AppSpacing.md),
            Semantics(
              header: true,
              child: Text(
                heading,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textoMute),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                height: AppSpacing.minTouchTarget,
                child: OutlinedButton(
                  onPressed: onAction,
                  child: Text(actionLabel!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
