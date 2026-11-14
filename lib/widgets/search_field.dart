import 'package:flutter/material.dart';

import '../core/i18n/app_localizations.dart';
import '../core/theme/app_spacing.dart';

/// Search box with a visible label, a 44x44 clear button and a live
/// result count slot (pattern from Astryx "Searchable Table").
class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    required this.controller,
    required this.label,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        return TextField(
          controller: controller,
          onChanged: onChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: value.text.isEmpty
                ? null
                : IconButton(
                    constraints: const BoxConstraints(
                      minWidth: AppSpacing.minTouchTarget,
                      minHeight: AppSpacing.minTouchTarget,
                    ),
                    tooltip: l10n.t('searchClear'),
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      controller.clear();
                      onChanged('');
                    },
                  ),
          ),
        );
      },
    );
  }
}

/// "N results" line announced politely when the number changes.
class ResultCount extends StatelessWidget {
  const ResultCount({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context).resultCount(count);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Semantics(
        liveRegion: true,
        child: Text(text, style: Theme.of(context).textTheme.bodySmall),
      ),
    );
  }
}
