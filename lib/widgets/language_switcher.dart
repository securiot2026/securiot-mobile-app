import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/i18n/app_localizations.dart';
import '../core/theme/app_spacing.dart';
import '../providers/locale_provider.dart';

/// EN / ES toggle. Visible text labels, never a flag or unlabeled globe
/// icon, with an explicit group accessible name per the shared
/// Accessibility Contract.
class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final localeProvider = context.watch<LocaleProvider>();
    final isEnglish = localeProvider.locale.languageCode == 'en';

    return Semantics(
      container: true,
      label: l10n.languageSelector,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        child: SegmentedButton<String>(
          segments: [
            ButtonSegment(value: 'en', label: Text(l10n.t('languageEnglish'))),
            ButtonSegment(value: 'es', label: Text(l10n.t('languageSpanish'))),
          ],
          selected: {isEnglish ? 'en' : 'es'},
          showSelectedIcon: false,
          style: const ButtonStyle(
            visualDensity: VisualDensity.standard,
            minimumSize: WidgetStatePropertyAll(Size(0, AppSpacing.minTouchTarget)),
          ),
          onSelectionChanged: (selection) {
            final code = selection.first;
            localeProvider.setLanguage(code == 'en' ? const Locale('en', 'US') : const Locale('es', 'PE'));
          },
        ),
      ),
    );
  }
}
