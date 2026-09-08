import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/i18n/app_localizations.dart';
import '../../core/theme/app_spacing.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/language_switcher.dart';
import '../alerts/alerts_screen.dart';
import '../devices/devices_screen.dart';
import '../zones/zones_screen.dart';

/// Bottom-navigation shell: the native translation of the Web App's
/// sidenav, sized for a phone. Three destinations, thumb-reachable.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _screens = [ZonesScreen(), DevicesScreen(), AlertsScreen()];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          const LanguageSwitcher(),
          Semantics(
            button: true,
            label: l10n.logout,
            child: IconButton(
              constraints: const BoxConstraints(
                minWidth: AppSpacing.minTouchTarget,
                minHeight: AppSpacing.minTouchTarget,
              ),
              icon: const Icon(Icons.logout),
              tooltip: l10n.logout,
              onPressed: () => context.read<AuthProvider>().logout(),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.map_outlined), selectedIcon: const Icon(Icons.map), label: l10n.navZones),
          NavigationDestination(icon: const Icon(Icons.sensors_outlined), selectedIcon: const Icon(Icons.sensors), label: l10n.navDevices),
          NavigationDestination(icon: const Icon(Icons.notifications_outlined), selectedIcon: const Icon(Icons.notifications), label: l10n.navAlerts),
        ],
      ),
    );
  }
}
