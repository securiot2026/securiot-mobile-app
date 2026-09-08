import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';

/// Loading state: a spinner paired with a live-announced "Loading…" label
/// (a spinner alone conveys nothing to a screen reader), per the sibling
/// surfaces' Accessibility Contract.
class ListLoadingView extends StatelessWidget {
  const ListLoadingView({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.accent),
          const SizedBox(height: AppSpacing.md),
          Semantics(
            liveRegion: true,
            child: Text(label, style: const TextStyle(color: AppColors.ink)),
          ),
        ],
      ),
    );
  }
}

class ListErrorView extends StatelessWidget {
  const ListErrorView({
    super.key,
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 40, color: AppColors.statusOffline),
            const SizedBox(height: AppSpacing.md),
            Semantics(
              liveRegion: true,
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.ink),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: AppSpacing.minTouchTarget,
              child: OutlinedButton(onPressed: onRetry, child: Text(retryLabel)),
            ),
          ],
        ),
      ),
    );
  }
}

class ListEmptyView extends StatelessWidget {
  const ListEmptyView({
    super.key,
    required this.icon,
    required this.heading,
    required this.body,
  });

  final IconData icon;
  final String heading;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: AppColors.ink.withValues(alpha: 0.35)),
            const SizedBox(height: AppSpacing.md),
            Text(
              heading,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.ink),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              body,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.ink.withValues(alpha: 0.7)),
            ),
          ],
        ),
      ),
    );
  }
}
