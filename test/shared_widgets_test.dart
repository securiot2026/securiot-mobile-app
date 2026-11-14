import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:securiot_mobile/core/i18n/app_localizations.dart';
import 'package:securiot_mobile/core/theme/app_spacing.dart';
import 'package:securiot_mobile/widgets/empty_state.dart';
import 'package:securiot_mobile/widgets/filter_chips_bar.dart';
import 'package:securiot_mobile/widgets/search_field.dart';
import 'package:securiot_mobile/widgets/section_header.dart';
import 'package:securiot_mobile/widgets/status_tile.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: ThemeData.dark(),
    locale: const Locale('en', 'US'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

Future<void> _pump(WidgetTester tester, Widget w) async {
  await tester.pumpWidget(w);
  await tester.pump();
}

void main() {
  testWidgets('StatusTile exposes one "label: value" semantics node and a sparkline', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, _wrap(const StatusTile(
      label: 'Online',
      value: '3',
      icon: Icons.check_circle,
      trend: [1, 3, 2, 4],
    )));
    expect(find.bySemanticsLabel('Online: 3'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
    expect(tester.getSize(find.byType(StatusTile)).height, greaterThanOrEqualTo(AppSpacing.minTouchTarget));
    handle.dispose();
  });

  testWidgets('FilterChipsBar chips are 44 high, grouped, and report selection', (tester) async {
    final handle = tester.ensureSemantics();
    String selected = 'all';
    await _pump(tester, _wrap(StatefulBuilder(
      builder: (context, setState) => FilterChipsBar<String>(
        groupLabel: 'Filter by status',
        selected: selected,
        onSelected: (v) => setState(() => selected = v),
        options: const [
          FilterOption(value: 'all', label: 'All'),
          FilterOption(value: 'online', label: 'Online', icon: Icons.check_circle),
        ],
      ),
    )));
    expect(find.bySemanticsLabel('Filter by status'), findsOneWidget);
    for (final chip in tester.widgetList(find.byType(FilterChip))) {
      final size = tester.getSize(find.byWidget(chip));
      expect(size.height, greaterThanOrEqualTo(AppSpacing.minTouchTarget));
    }
    await tester.tap(find.text('Online'));
    await tester.pump();
    expect(selected, 'online');
    final chip = tester.widget<FilterChip>(find.widgetWithText(FilterChip, 'Online'));
    expect(chip.selected, isTrue);
    expect(chip.showCheckmark, isTrue); // check mark, not color alone
    handle.dispose();
  });

  testWidgets('SearchField is labelled, clear button is 44x44 and clears', (tester) async {
    final controller = TextEditingController();
    String last = '';
    await _pump(tester, _wrap(SearchField(
      controller: controller,
      label: 'Search devices',
      onChanged: (v) => last = v,
    )));
    expect(find.text('Search devices'), findsOneWidget);
    expect(find.byIcon(Icons.close), findsNothing);
    await tester.enterText(find.byType(TextField), 'cam');
    await tester.pump();
    expect(last, 'cam');
    final size = tester.getSize(find.widgetWithIcon(IconButton, Icons.close));
    expect(size.width, greaterThanOrEqualTo(AppSpacing.minTouchTarget));
    expect(size.height, greaterThanOrEqualTo(AppSpacing.minTouchTarget));
    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    expect(controller.text, isEmpty);
    expect(last, '');
  });

  testWidgets('ResultCount is a live region with pluralization', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, _wrap(const ResultCount(count: 1)));
    expect(find.text('1 result'), findsOneWidget);
    await _pump(tester, _wrap(const ResultCount(count: 4)));
    expect(find.text('4 results'), findsOneWidget);
    expect(
      tester.getSemantics(find.text('4 results')),
      matchesSemantics(label: '4 results', isLiveRegion: true, hasEnabledState: false),
    );
    handle.dispose();
  });

  testWidgets('EmptyState shows a 44 high action and fires it', (tester) async {
    var fired = false;
    await _pump(tester, _wrap(EmptyState(
      icon: Icons.search_off,
      heading: 'Nothing here',
      body: 'Try again',
      actionLabel: 'Clear filters',
      onAction: () => fired = true,
    )));
    expect(find.text('Nothing here'), findsOneWidget);
    final size = tester.getSize(find.widgetWithText(OutlinedButton, 'Clear filters'));
    expect(size.height, greaterThanOrEqualTo(AppSpacing.minTouchTarget));
    await tester.tap(find.text('Clear filters'));
    expect(fired, isTrue);
  });

  testWidgets('SectionHeader is marked as a header', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, _wrap(const SectionHeader(title: 'Devices', trailing: '3')));
    expect(tester.getSemantics(find.text('Devices')), matchesSemantics(label: 'Devices', isHeader: true));
    handle.dispose();
  });
}
