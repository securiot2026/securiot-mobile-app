import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import 'empty_state.dart';

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
          const CircularProgressIndicator(color: AppColors.marca),
          const SizedBox(height: AppSpacing.md),
          Semantics(
            liveRegion: true,
            child: Text(label, style: const TextStyle(color: AppColors.texto)),
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
            const Icon(
              Icons.wifi_off_rounded,
              size: 40,
              color: AppColors.statusOffline,
            ),
            const SizedBox(height: AppSpacing.md),
            Semantics(
              liveRegion: true,
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.texto),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: AppSpacing.minTouchTarget,
              child: OutlinedButton(
                onPressed: onRetry,
                child: Text(retryLabel),
              ),
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
    return EmptyState(
      icon: icon,
      heading: heading,
      body: body,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}
