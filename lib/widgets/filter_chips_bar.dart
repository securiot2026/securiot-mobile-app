import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';

class FilterOption<T> {
  const FilterOption({required this.value, required this.label, this.icon});

  final T value;
  final String label;
  final IconData? icon;
}

/// Single-select filter chips in a horizontal strip (pattern from Astryx
/// "Filterable Table"). Each chip is at least 44 high, shows a check mark
/// when selected (color is never the only cue) and is grouped under
/// [groupLabel] for screen readers.
class FilterChipsBar<T> extends StatelessWidget {
  const FilterChipsBar({
    super.key,
    required this.groupLabel,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final String groupLabel;
  final List<FilterOption<T>> options;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: groupLabel,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Row(
          children: [
            for (final option in options) ...[
              ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: AppSpacing.minTouchTarget,
                ),
                child: FilterChip(
                  label: Text(option.label),
                  avatar: option.icon == null
                      ? null
                      : Icon(option.icon, size: 18),
                  selected: option.value == selected,
                  showCheckmark: true,
                  checkmarkColor: AppColors.marca,
                  selectedColor: AppColors.marca.withValues(alpha: 0.24),
                  backgroundColor: AppColors.surfaceCard,
                  side: BorderSide(
                    color: option.value == selected
                        ? AppColors.marca
                        : AppColors.texto.withValues(alpha: 0.2),
                  ),
                  shape: const StadiumBorder(),
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  onSelected: (_) => onSelected(option.value),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
          ],
        ),
      ),
    );
  }
}
